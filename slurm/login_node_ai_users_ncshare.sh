#!/usr/bin/env bash
#
# login_node_ai_users_ncshare.sh - List users running AI coding agents / remote IDEs
# (Claude Code, Codex, Cursor, VS Code server, Copilot, Gemini CLI, etc.)
# on NCShare login nodes, and optionally email and/or block them. Emails are
# looked up in LDAP with get_email_address.sh.
#
# Usage:
#   ./login_node_ai_users_ncshare.sh                              # this host
#   ./login_node_ai_users_ncshare.sh -H login-01,login-02 # query hosts over ssh
#   ./login_node_ai_users_ncshare.sh -r                           # raw TSV, no header (for scripts)
#   ./login_node_ai_users_ncshare.sh -H ... --email               # email every user found
#   ./login_node_ai_users_ncshare.sh -H ... --block               # set MaxJobs=0 for every user found
#   ./login_node_ai_users_ncshare.sh -H ... --email --block       # both; the email says they are blocked
#   ./login_node_ai_users_ncshare.sh --unblock user1,user2        # restore their saved MaxJobs values
#   add --dry-run to --email/--block/--unblock to print what would happen
#
# Each user found gets one email per run listing their processes on every
# host, with no cooldown, so an hourly cron job keeps emailing until they stop.
#
# --block saves each association's MaxJobs to BLOCK_FILE before setting it to
# 0, and --unblock restores exactly those values. Blocks are not lifted
# automatically.
#
# Every --email/--block/--unblock run (except dry runs) appends one row per
# user and host to HISTORY_FILE.
#
# Works as a normal user unless /proc is mounted with hidepid. -H needs
# passwordless ssh to each host.
#
set -euo pipefail

# label|ERE matched against the lowercased command line.
PATTERNS=(
  'claude|(^|/)claude( |$)|@anthropic-ai/claude-code|anthropic\.claude-code'
  'codex|(^|/)codex( |$)|@openai/codex|openai\.chatgpt|/\.codex/packages/'
  'cursor|\.cursor-server|cursor-agent|(^|/)cursor( |$)'
  'windsurf|\.windsurf-server|(^|/)windsurf( |$)'
  'vscode|\.vscode-server|vscode-server|code-server|code-tunnel|\.vscode/cli|(^|/)code (tunnel|serve-web)'
  'copilot|@github/copilot|copilot-language-server|github\.copilot|(^|/)copilot( |$)'
  'gemini|@google/gemini-cli|(^|/)gemini( |$)'
  'qwen|@qwen-code|(^|/)qwen( |$)'
  'aider|(^|/)aider( |$)|-m aider'
  'opencode|(^|/)opencode( |$)'
  'goose|(^|/)goose( |$)'
  'amazon-q|(^|/)q chat|(^|/)qchat( |$)'
  'ollama|(^|/)ollama( |$)'
)

# Email settings (--email only).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FROM_EMAIL="info@ncshare.org"
CC_EMAIL="uthpala.herath@duke.edu,info@ncshare.org,rescomputing@duke.edu"
LOG_DIR="${HOME}/logs/login_ai"
# Tab-separated: time, user, host, tools, nproc, pids, action.
HISTORY_FILE="${LOG_DIR}/history.tsv"
# Pipe-separated (empty fields are common, and read would merge tabs):
# user|account|partition|previous MaxJobs|blocked at.
BLOCK_FILE="${LOG_DIR}/blocked.psv"
# Appended to short host names in the kill commands users copy into their
# own terminal, so they resolve from outside the cluster.
LOGIN_DOMAIN="ncshare.org"
# Users never emailed or blocked (staff, service accounts), space-separated.
EXCLUDE_USERS=""

# Normalize long options to short ones before getopts.
args=()
for a in "$@"; do
  case "$a" in
    --email)   args+=("-e") ;;
    --block)   args+=("-b") ;;
    --unblock) args+=("-u") ;;
    --dry-run) args+=("-n") ;;
    --help)    args+=("-h") ;;
    *)         args+=("$a") ;;
  esac
done
set -- "${args[@]+"${args[@]}"}"

hosts=""
raw=0
email=0
block=0
unblock=""
dry_run=0
while getopts ":H:rebu:nh" opt; do
  case "$opt" in
    H) hosts="$OPTARG" ;;
    r) raw=1 ;;
    e) email=1 ;;
    b) block=1 ;;
    u) unblock="$OPTARG" ;;
    n) dry_run=1 ;;
    h) awk 'NR > 1 && !/^#/ { exit } NR > 1' "$0"; exit 0 ;;
    :) case "$OPTARG" in
         u) echo "Error: --unblock needs a user, e.g. --unblock zy128" >&2 ;;
         H) echo "Error: -H needs a host list, e.g. -H login-01,login-02" >&2 ;;
       esac
       exit 1 ;;
    *) echo "Error: unknown option -$OPTARG (see --help)" >&2; exit 1 ;;
  esac
done

if [[ "$dry_run" -eq 1 && "$email" -eq 0 && "$block" -eq 0 && -z "$unblock" ]]; then
  echo "Error: --dry-run only applies with --email, --block or --unblock" >&2
  exit 1
fi

PS_CMD='ps -eo uid=,user:32=,pid=,args= --no-headers'

# Emit "host uid user pid args..." for each process.
collect() {
  if [[ -z "$hosts" ]]; then
    $PS_CMD | sed "s/^/$(hostname -s) /"
  else
    local h
    for h in ${hosts//,/ }; do
      timeout 60 ssh -x -o BatchMode=yes -o ConnectTimeout=5 "$h" "$PS_CMD" 2>/dev/null \
        | sed "s/^/$h /" \
        || echo "warning: could not query $h" >&2
    done
  fi
}

# Passed via ENVIRON so awk does not mangle backslash escapes.
export AI_PATS="$(printf '%s\n' "${PATTERNS[@]}")"

# Print "user<TAB>host<TAB>tools<TAB>pid<TAB>command" for each matching process.
find_matches() {
  collect | awk '
  BEGIN {
    n = split(ENVIRON["AI_PATS"], lines, "\n")
    for (i = 1; i <= n; i++) {
      if (lines[i] == "") continue
      p = index(lines[i], "|")
      np++
      label[np] = substr(lines[i], 1, p - 1)
      re[np]    = substr(lines[i], p + 1)
    }
  }
  $2 >= 1000 {
    cmd = $0
    for (i = 1; i <= 4; i++) sub(/^[ \t]*[^ \t]+/, "", cmd)
    sub(/^[ \t]+/, "", cmd)
    gsub(/\t/, " ", cmd)
    lc = tolower(cmd)
    tools = ""
    for (i = 1; i <= np; i++)
      if (lc ~ re[i]) tools = tools (tools == "" ? "" : ",") label[i]
    if (tools != "") print $3 "\t" $1 "\t" tools "\t" $4 "\t" cmd
  }' | sort -t$'\t' -k1,1 -k2,2 -k4,4n
}

# First LDAP address for a user, or nothing.
get_email_for_user() {
  "$SCRIPT_DIR/get_email_address.sh" -e "$1" 2>/dev/null | head -1 || true
}

send_email() {
  local to="$1"
  local subject="$2"
  local body="$3"

  local args=(
    -r "$FROM_EMAIL"
    -a "From: $FROM_EMAIL"
  )

  if [ -n "$CC_EMAIL" ]; then
    args+=(-a "Cc: $CC_EMAIL")
  fi

  echo "$body" | mailx "${args[@]}" -s "$subject" "$to" || true
}

# Run a command, or just print it with --dry-run.
run() {
  if [[ "$dry_run" -eq 1 ]]; then
    echo "  would run: $*" >&2
  else
    "$@"
  fi
}

# Append one row per host for this user to HISTORY_FILE.
record_history() {
  local user="$1" matches="$2" action="$3" now
  [[ "$dry_run" -eq 1 ]] && return
  now="$(date '+%F %T')"
  if [[ ! -s "$HISTORY_FILE" ]]; then
    printf 'time\tuser\thost\ttools\tnproc\tpids\taction\n' > "$HISTORY_FILE"
  fi
  awk -F'\t' -v OFS='\t' -v u="$user" -v now="$now" -v act="$action" '
    $1 == u {
      if (!($2 in n)) order[++k] = $2
      n[$2]++
      pids[$2] = pids[$2] (pids[$2] == "" ? "" : " ") $4
      m = split($3, t, ",")
      for (i = 1; i <= m; i++)
        if (!(($2, t[i]) in seen)) {
          seen[$2, t[i]] = 1
          tools[$2] = tools[$2] (tools[$2] == "" ? "" : ",") t[i]
        }
    }
    END { for (i = 1; i <= k; i++) { h = order[i]; print now, u, h, tools[h], n[h], pids[h], act } }
  ' <<< "$matches" >> "$HISTORY_FILE"
}

# Set MaxJobs=0 on all of a user's associations. The original values are saved
# only the first time, so repeated hourly runs don't overwrite them with 0.
block_user() {
  local user="$1" now assocs
  now="$(date '+%F %T')"
  if ! grep -q "^${user}|" "$BLOCK_FILE" 2>/dev/null; then
    assocs="$(sacctmgr -nP show assoc where user="$user" format=user,account,partition,maxjobs)"
    if [[ -z "$assocs" ]]; then
      echo "  $user has no Slurm associations, nothing to block"
      return 1
    fi
    if [[ "$dry_run" -eq 0 ]]; then
      awk -F'|' -v OFS='|' -v now="$now" '{ print $1, $2, $3, $4, now }' <<< "$assocs" >> "$BLOCK_FILE"
    fi
  fi
  run sacctmgr -i modify user where name="$user" set MaxJobs=0 > /dev/null
}

# Restore the MaxJobs values saved by block_user. An empty saved value means
# no limit was set, which sacctmgr spells -1. Account-level rows (empty
# partition) sort first so partition-specific values are applied last.
unblock_users() {
  local user acct part prev _ restored now
  now="$(date '+%F %T')"
  [[ "$dry_run" -eq 0 ]] && mkdir -p "$LOG_DIR"
  for user in ${unblock//,/ }; do
    if ! grep -q "^${user}|" "$BLOCK_FILE" 2>/dev/null; then
      echo "Skipping $user: not in $BLOCK_FILE"
      continue
    fi
    if [[ "$dry_run" -eq 1 ]]; then
      echo "[dry run] Would unblock $user"
    else
      echo "Unblocking $user"
    fi
    restored=1
    while IFS='|' read -r _ acct part prev _; do
      local where=(name="$user" account="$acct")
      [[ -n "$part" ]] && where+=(partition="$part")
      run sacctmgr -i modify user where "${where[@]}" set MaxJobs="${prev:--1}" > /dev/null \
        || { echo "  failed to restore $user account=$acct partition=$part" >&2; restored=0; }
    done < <(awk -F'|' -v u="$user" '$1 == u' "$BLOCK_FILE" | sort -t'|' -k3,3)
    if [[ "$dry_run" -eq 0 && "$restored" -eq 1 ]]; then
      awk -F'|' -v u="$user" '$1 != u' "$BLOCK_FILE" > "${BLOCK_FILE}.tmp"
      mv "${BLOCK_FILE}.tmp" "$BLOCK_FILE"
      printf '%s\t%s\t-\t-\t-\t-\tunblock\n' "$now" "$user" >> "$HISTORY_FILE"
    fi
  done
}

# Email and/or block each user found; one email covers all their hosts.
process_users() {
  local matches="$1"
  local user details kill_cmds addr body subject block_note ban_warning action
  local sent=0 blocked=0 skipped=0

  if [[ "$dry_run" -eq 0 ]]; then
    mkdir -p "$LOG_DIR"
  fi

  for user in $(cut -f1 <<< "$matches" | sort -u); do
    if [[ " $EXCLUDE_USERS " == *" $user "* ]]; then
      echo "Skipping $user: excluded"
      ((skipped++)) || true
      continue
    fi

    action=""
    block_note=""
    if [[ "$block" -eq 1 ]]; then
      if [[ "$dry_run" -eq 1 ]]; then
        echo "[dry run] Would block $user (MaxJobs=0)"
      else
        echo "Blocking $user (MaxJobs=0)"
      fi
      if block_user "$user"; then
        action="block"
        ((blocked++)) || true
        block_note="
YOUR SLURM JOBS HAVE BEEN BLOCKED because of the processes listed below.
New jobs will stay pending and will not start. Once these processes are
stopped, contact info@ncshare.org to have your access restored.
"
      fi
    fi

    if [[ "$email" -eq 1 ]]; then
      # Tools found on each host, and a kill command per host.
      details="$(awk -F'\t' -v u="$user" '
        $1 == u {
          if (!($2 in tools)) order[++n] = $2
          k = split($3, t, ",")
          for (i = 1; i <= k; i++)
            if (!(($2, t[i]) in seen)) {
              seen[$2, t[i]] = 1
              tools[$2] = tools[$2] (tools[$2] == "" ? "" : ", ") t[i]
            }
        }
        END { for (i = 1; i <= n; i++) printf "  %s: %s\n", order[i], tools[order[i]] }
      ' <<< "$matches")"
      kill_cmds="$(awk -F'\t' -v u="$user" -v dom="$LOGIN_DOMAIN" '
        $1 == u { if (!($2 in pids)) order[++n] = $2; pids[$2] = pids[$2] " " $4 }
        END {
          for (i = 1; i <= n; i++) {
            h = order[i]
            fqdn = (index(h, ".") || dom == "") ? h : h "." dom
            printf "    ssh %s@%s kill%s\n", u, fqdn, pids[h]
          }
        }' <<< "$matches")"

      addr="$(get_email_for_user "$user")"
      if [[ -z "$addr" ]]; then
        echo "Skipping email to $user: no address in LDAP"
        ((skipped++)) || true
        [[ -n "$action" ]] && record_history "$user" "$matches" "$action"
        continue
      fi
      if [[ -n "$block_note" ]]; then
        subject="Slurm jobs BLOCKED: Stop AI tools and IDEs on NCShare login nodes"
        ban_warning=""
      else
        subject="ACTION REQUIRED: Stop AI tools and IDEs on NCShare login nodes"
        ban_warning=$'\nFailure to comply will ban you from using NCShare.'
      fi

      body="Dear ${user},

THIS IS AN AUTOMATED MESSAGE!
${block_note}
You are running the following AI coding tools and/or remote IDE servers on
the NCShare login nodes:

${details}

The login nodes are shared by every NCShare user and are meant for light work such
as editing files, managing data, and submitting jobs. VS Code, Cursor and AI
coding agents (Claude Code, Codex, Gemini, etc.) start long-running processes
that use a significant amount of CPU and memory, which slows down the login
nodes for everyone.

Please stop these processes immediately! Close your remote IDE
or AI agent session first, otherwise it may restart them. Then
run the following commands from a terminal to kill any remaining processes:

${kill_cmds}

To run these tools properly, inside a Slurm job on a compute node, follow
these guides:

- VS Code (and VS Code-based editors such as Cursor):
    https://userguide.ncshare.org/guides/vscode

- AI coding tools (Claude Code, Codex, etc.):
    https://userguide.ncshare.org/guides/ai

Please reach out to us at info@ncshare.org if you need any assistance.${ban_warning}

Thank you,
NCShare Team
"
      if [[ "$dry_run" -eq 1 ]]; then
        echo "----- [dry run] To: $addr  Subject: $subject"
        echo "$body"
      else
        echo "Sending email to: $addr"
        send_email "$addr" "$subject" "$body"
        ((sent++)) || true
      fi
      action="email${action:+,$action}"
    fi

    [[ -n "$action" ]] && record_history "$user" "$matches" "$action"
  done

  echo ""
  if [[ "$dry_run" -eq 1 ]]; then
    echo "Done (dry run, nothing sent or changed). Would block: $blocked, Skipped: $skipped"
  else
    echo "Done. Emails sent: $sent, Blocked: $blocked, Skipped: $skipped"
  fi
}

if [[ "$raw" -eq 1 ]]; then
  find_matches
  exit 0
fi

if [[ -n "$unblock" ]]; then
  unblock_users
  exit 0
fi

if [[ "$email" -eq 1 || "$block" -eq 1 ]]; then
  matches="$(find_matches)"
  if [[ -z "$matches" ]]; then
    echo "No AI tools or remote IDEs found"
    exit 0
  fi
  process_users "$matches"
  exit 0
fi

# Tab-separated so the command line can contain spaces. A blank line
# separates users.
{
  printf 'USER\tHOST\tPID\tRUNNING\tCOMMAND\n'
  find_matches | awk -F'\t' -v OFS='\t' '{ print $1, $2, $4, $3, $5 }'
} | column -t -s $'\t' \
  | awk 'NR > 2 && $1 != prev { print "" } { print; prev = $1 }'
