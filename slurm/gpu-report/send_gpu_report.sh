#!/usr/bin/env bash
# send_gpu_report.sh
#
# Run gpu_report.sh for a partition and window, then build and send the weekly
# GPU usage report email from its output.
#
# Usage:
#   send_gpu_report.sh -r PARTITION [-S START] [-E END] [--review | --send]
#
#   -r PARTITION   Partition. Needs templates/<PARTITION>.html. cc/<PARTITION>.txt and
#                  bcc/<PARTITION>.txt are optional extra recipients.
#   -S START       Window start (default: END - 7 days).
#   -E END         Window end (default: today).
#   (no mode)      Build the message only. Nothing is sent.
#   --review       Send it to $REVIEW_ADDR only.
#   --send         Send it to all users, the CC and BCC lists, $FROM_ADDR and $REVIEW_ADDR.
#
# Every run regenerates the report and the message. The message is saved as
# <report dir>/email/<partition>_<start>-<end>.eml. After a successful --send a
# .sent marker next to it blocks a second send for that window. Delete the
# marker to resend.
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

REVIEW_ADDR="herathuk@gmail.com"
MIN_RECIPIENTS=10
SENDMAIL=/usr/sbin/sendmail

SCRIPT_DIR="$HOME/dotfiles/slurm/gpu-report"

die() { echo "Error: $*" >&2; exit 1; }

PART="" START="" END="" MODE="build"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) PART="$2"; shift 2;;
    -S) START="$2"; shift 2;;
    -E) END="$2"; shift 2;;
    --review) MODE="review"; shift;;
    --send) MODE="send"; shift;;
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
BCC_FILE="$SCRIPT_DIR/bcc/${PART}.txt"
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
EML="$REPORT_DIR/email/${TAG}.eml"
SENT="$REPORT_DIR/email/${TAG}.sent"

[[ "$MODE" == "send" && -f "$SENT" ]] && die "$TAG was already sent on $(cat "$SENT"). Delete $SENT to resend."

# ---------------------------------------------------------------------------
# Run the report and check its output
# ---------------------------------------------------------------------------

echo "Running gpu_report.sh for $PART $START to $END ..."
# gpu_report.sh logs through a tee process substitution. Piping through cat
# waits until that tee has closed, so the log is complete before it is read.
"$SCRIPT_DIR/gpu_report.sh" -r "$PART" -S "$START" -E "$END" | cat > /dev/null

[[ -s "$LOG" ]] || die "gpu_report.sh produced no log at $LOG"
[[ -s "$TARBALL" ]] || die "missing user-report tarball $TARBALL"
nreports="$(tar tzf "$TARBALL" | grep -c '\.txt$' || true)"
(( nreports > 0 )) || die "user-report tarball $TARBALL is empty"

# User-facing part of the report: everything before the recipient list.
# For gpu-hp this includes the quota usage and pre-reset snapshot tables.
report="$(awk '/^Email list:/ {exit} {print}' "$LOG" | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')"

nusers="$(awk '!t && /^-+ +-+/ {t=1; next} t && NF==0 {exit} t && NF>=6 {n++} END {print n+0}' <<< "$report")"
(( nusers > 0 )) || die "no user rows in the efficiency table of $LOG"

# Recipients: the line after "Email list:".
users="$(awk 'f {print; exit} /^Email list:/ {f=1}' "$LOG" | tr ',; \t' '\n\n\n\n' \
         | grep -E '^[^@[:space:]]+@[^@[:space:]]+$' | sort -u || true)"
nrcpt="$(grep -c . <<< "$users" || true)"
(( nrcpt >= MIN_RECIPIENTS )) || die "only $nrcpt recipients parsed from $LOG (minimum $MIN_RECIPIENTS)"

# CC and BCC lists: one address per line or separated by , ; or spaces. # starts
# a comment. A missing file means no extra recipients.
read_addresses() {
  [[ -f "$1" ]] || return 0
  sed 's/#.*//' "$1" | tr ',; \t' '\n\n\n\n' | grep -E '^[^@[:space:]]+@[^@[:space:]]+$' | sort -u || true
}
cc="$(read_addresses "$CC_FILE")"
bcc="$(read_addresses "$BCC_FILE")"

# ---------------------------------------------------------------------------
# Build the message
# ---------------------------------------------------------------------------

body="$(<"$TEMPLATE")"
body="${body//\{\{PARTITION\}\}/$PART}"
body="${body//\{\{START\}\}/$START}"
body="${body//\{\{END\}\}/$END}"
body="${body//\{\{REPORT\}\}/$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "$report")}"

boundary="=_gpureport_$(date +%s)_$$"
mkdir -p "$REPORT_DIR/email"
{
  echo "From: ${FROM_NAME} <${FROM_ADDR}>"
  echo "To: ${FROM_NAME} <${FROM_ADDR}>"
  [[ -n "$cc" ]] && echo "Cc: $(paste -sd, - <<< "$cc" | sed 's/,/, /g')"
  echo "Subject: ${PART} GPU Usage Report: ${START} to ${END}"
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

echo "Built $EML"
echo "  users: $nusers in table, $nreports user reports attached, $nrcpt users (Bcc), $(grep -c . <<< "$cc" || true) CC, $(grep -c . <<< "$bcc" || true) extra Bcc"

# ---------------------------------------------------------------------------
# Deliver
# ---------------------------------------------------------------------------

case "$MODE" in
  build)
    echo "Nothing sent. Use --review to send it to $REVIEW_ADDR or --send to send it to everyone."
    ;;
  review)
    "$SENDMAIL" -oi -f "$FROM_ADDR" -- "$REVIEW_ADDR" < "$EML"
    echo "Review copy sent to $REVIEW_ADDR"
    ;;
  send)
    # Envelope recipients. Users and the BCC list are delivered to but not listed in the headers.
    mapfile -t rcpts < <(printf '%s\n' "$FROM_ADDR" "$REVIEW_ADDR" "$cc" "$bcc" "$users" | grep . | sort -u)
    "$SENDMAIL" -oi -f "$FROM_ADDR" -- "${rcpts[@]}" < "$EML"
    date '+%F %T' > "$SENT"
    echo "Sent to ${#rcpts[@]} recipients"
    ;;
esac
