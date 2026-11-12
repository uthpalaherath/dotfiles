#!/usr/bin/env bash
# send_gpu_report.sh
#
# Build and send the weekly GPU usage report email for a partition from the
# output of gpu_report.sh in the same directory.
#
# Usage:
#   send_gpu_report.sh -r PARTITION [-S START] [-E END] [--review | --send] [--regen] [--force]
#
#   -r PARTITION   Partition. Needs templates/<PARTITION>.html. cc/<PARTITION>.txt is optional.
#   -S START       Window start (default: END - 7 days).
#   -E END         Window end (default: today).
#   (no mode)      Build and stage the message only. Nothing is sent.
#   --review       Send the staged message to $REVIEW_ADDR only.
#   --send         Send the staged message to all users, the CC list, $FROM_ADDR and $REVIEW_ADDR.
#   --regen        Discard the existing gpu_report.sh log, tarball and staged message, then rebuild.
#   --force        Allow --send for a window that was already sent.
#
# The message is built once and staged under <report dir>/email/. --review and
# --send deliver that same file, so what you review is exactly what users get.
# An existing gpu_report.sh log for the window is reused because gpu_report.sh
# appends to its log rather than overwriting it.
#
# Mail goes out through sendmail with a prebuilt MIME message rather than mailx,
# because mailx flags differ between clusters (s-nail on DCC treats -a as an
# attachment, bsd-mailx/mailutils on NCShare treats it as a header).
#
# Examples:
#   send_gpu_report.sh -r h200-hp --review
#   send_gpu_report.sh -r h200-hp -S 2026-11-03 -E 2026-11-10 --send
#   send_gpu_report.sh -r gpu-hp --review        # on NCShare

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/opt/slurm/bin:$PATH"
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true

REVIEW_ADDR="uthpala.herath@duke.edu"
MIN_RECIPIENTS=10
SENDMAIL=/usr/sbin/sendmail

SCRIPT_DIR="$HOME/dotfiles/slurm/gpu-report"

die() { echo "Error: $*" >&2; exit 1; }

PART="" START="" END="" MODE="stage" REGEN=0 FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) PART="$2"; shift 2;;
    -S) START="$2"; shift 2;;
    -E) END="$2"; shift 2;;
    --review) MODE="review"; shift;;
    --send) MODE="send"; shift;;
    --regen) REGEN=1; shift;;
    --force) FORCE=1; shift;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) die "unknown argument: $1";;
  esac
done

[[ -n "$PART" ]] || die "-r PARTITION is required"
END="${END:-$(date +%Y-%m-%d)}"
START="${START:-$(date -d "$END - 7 days" +%Y-%m-%d)}"
date -d "$START" >/dev/null 2>&1 || die "bad start date: $START"
date -d "$END" >/dev/null 2>&1 || die "bad end date: $END"

TEMPLATE="$SCRIPT_DIR/templates/${PART}.html"
CC_FILE="$SCRIPT_DIR/cc/${PART}.txt"
[[ -f "$TEMPLATE" ]] || die "no template for $PART at $TEMPLATE"

# Per-cluster settings. REPORT_DIR must match OUTPUT_DIR in gpu_report.sh.
case "$PART" in
  scavenger-h200|h200-hp)  # DCC
    REPORT_DIR="/admin/reports/${PART}"
    FROM_NAME="Uthpala Herath"
    FROM_ADDR="uthpala.herath@duke.edu";;
  gpu-hp|gpu)              # NCShare
    REPORT_DIR="/data/admin/reports/${PART}"
    FROM_NAME="NCShare"
    FROM_ADDR="info@ncshare.org";;
  *) die "no settings for partition $PART";;
esac
[[ -x "$SENDMAIL" ]] || die "$SENDMAIL not found on $(hostname)"

TAG="${PART}_${START}-${END}"
LOG="$REPORT_DIR/${TAG}.txt"
TARBALL="$REPORT_DIR/${TAG}.tar.gz"
STAGE_DIR="$REPORT_DIR/email"
EML="$STAGE_DIR/${TAG}.eml"
RCPT="$STAGE_DIR/${TAG}.rcpt"
SENT="$STAGE_DIR/${TAG}.sent"

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

# Read addresses from a file, one per line or separated by , ; or spaces. # starts a comment.
read_addresses() {
  sed 's/#.*//' "$1" | tr ',; \t' '\n\n\n\n' | grep -E '^[^@[:space:]]+@[^@[:space:]]+$' || true
}

build_message() {
  if (( REGEN )); then
    [[ -f "$SENT" && $FORCE -eq 0 ]] && die "$TAG was already sent. Use --force to rebuild anyway."
    rm -f "$LOG" "$TARBALL" "$EML" "$RCPT"
  fi

  if [[ ! -s "$LOG" ]]; then
    echo "Running gpu_report.sh for $PART $START to $END ..."
    "$SCRIPT_DIR/gpu_report.sh" -r "$PART" -S "$START" -E "$END" > /dev/null
  else
    echo "Reusing existing report $LOG"
  fi
  [[ -s "$LOG" ]] || die "gpu_report.sh produced no log at $LOG"
  [[ -s "$TARBALL" ]] || die "missing user-report tarball $TARBALL"

  # User-facing part of the report: everything before the recipient list.
  # For gpu-hp this includes the quota usage and pre-reset snapshot tables.
  local report
  report="$(awk '/^Email list:/ {exit} {print}' "$LOG" | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')"

  local nusers
  nusers="$(awk '!t && /^-+ +-+/ {t=1; next} t && NF==0 {exit} t && NF>=6 {n++} END {print n+0}' <<< "$report")"
  (( nusers > 0 )) || die "no user rows in the efficiency table of $LOG"

  # Recipients: line after "Email list:".
  local users cc
  users="$(awk 'f {print; exit} /^Email list:/ {f=1}' "$LOG" | tr ',; \t' '\n\n\n\n' \
           | grep -E '^[^@[:space:]]+@[^@[:space:]]+$' | sort -u || true)"
  local nrcpt
  nrcpt="$(grep -c . <<< "$users" || true)"
  (( nrcpt >= MIN_RECIPIENTS )) || die "only $nrcpt recipients parsed from $LOG (minimum $MIN_RECIPIENTS)"

  cc=""
  [[ -f "$CC_FILE" ]] && cc="$(read_addresses "$CC_FILE" | sort -u)"

  local body
  body="$(<"$TEMPLATE")"
  body="${body//\{\{PARTITION\}\}/$PART}"
  body="${body//\{\{START\}\}/$START}"
  body="${body//\{\{END\}\}/$END}"
  body="${body//\{\{REPORT\}\}/$(html_escape <<< "$report")}"

  local subject="${PART} GPU Usage Report: ${START} to ${END}"
  local boundary="=_gpureport_$(date +%s)_$$"
  local cc_header=""
  [[ -n "$cc" ]] && cc_header="Cc: $(paste -sd, - <<< "$cc" | sed 's/,/, /g')"

  mkdir -p "$STAGE_DIR"
  {
    echo "From: ${FROM_NAME} <${FROM_ADDR}>"
    echo "To: ${FROM_NAME} <${FROM_ADDR}>"
    [[ -n "$cc_header" ]] && echo "$cc_header"
    echo "Subject: ${subject}"
    echo "Date: $(date -R)"
    echo "Message-ID: <${TAG}.$(date +%s).$$@$(hostname -f)>"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"${boundary}\""
    echo
    echo "--${boundary}"
    echo "Content-Type: text/html; charset=UTF-8"
    echo "Content-Transfer-Encoding: base64"
    echo
    base64 -w 76 <<< "$body"
    echo
    echo "--${boundary}"
    echo "Content-Type: application/gzip; name=\"$(basename "$TARBALL")\""
    echo "Content-Disposition: attachment; filename=\"$(basename "$TARBALL")\""
    echo "Content-Transfer-Encoding: base64"
    echo
    base64 -w 76 "$TARBALL"
    echo
    echo "--${boundary}--"
  } > "$EML"

  # Envelope recipients. Users are Bcc: they are delivered to but not listed in the headers.
  { echo "$FROM_ADDR"; echo "$REVIEW_ADDR"; [[ -n "$cc" ]] && echo "$cc"; echo "$users"; } | grep . | sort -u > "$RCPT"

  echo "Staged $EML"
  echo "  users: $nusers in table, $nrcpt recipients (Bcc), $(grep -c . <<< "$cc" || true) CC"
}

if (( REGEN )) || [[ ! -s "$EML" || ! -s "$RCPT" ]]; then
  build_message
else
  echo "Using staged $EML (pass --regen to rebuild)"
fi

# ---------------------------------------------------------------------------
# Deliver
# ---------------------------------------------------------------------------

case "$MODE" in
  stage)
    echo "Nothing sent. Use --review to send it to $REVIEW_ADDR or --send to send it to everyone."
    ;;
  review)
    "$SENDMAIL" -oi -f "$FROM_ADDR" -- "$REVIEW_ADDR" < "$EML"
    echo "Review copy sent to $REVIEW_ADDR"
    ;;
  send)
    [[ -f "$SENT" && $FORCE -eq 0 ]] && die "$TAG was already sent on $(cat "$SENT"). Use --force to resend."
    mapfile -t rcpts < "$RCPT"
    (( ${#rcpts[@]} >= MIN_RECIPIENTS )) || die "only ${#rcpts[@]} recipients in $RCPT"
    "$SENDMAIL" -oi -f "$FROM_ADDR" -- "${rcpts[@]}" < "$EML"
    date '+%F %T' > "$SENT"
    echo "Sent to ${#rcpts[@]} recipients"
    ;;
esac
