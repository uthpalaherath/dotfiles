#!/usr/bin/env bash

# Usage:
# gpu_report.sh -r partition -S start_date -E end_date

UTIL_DIR="$HOME/dotfiles/slurm/utilities"
NCSHARE_DIR="$HOME/dotfiles/slurm/ncshare"

# Parse command line arguments
while getopts "r:S:E:" opt; do
    case $opt in
        r) PARTITION="$OPTARG";;
        S) START_DATE="$OPTARG";;
        E) END_DATE="$OPTARG";;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    esac
done

# Check if all required arguments are provided
if [ -z "$PARTITION" ] || [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    echo "Usage: $0 -r partition -S start_date -E end_date"
    echo "Example: $0 -r scavenger-h200 -S 2025-12-30 -E 2026-01-08"
    exit 1
fi

# Select log directory based on partition
# Keep in sync with the REPORT_DIR case block in send_gpu_report.sh (same directory)
if [ "$PARTITION" == "scavenger-h200" ] || [ "$PARTITION" == "h200-hp" ] || [ "$PARTITION" == "h200-shared" ]; then
    OUTPUT_DIR="/admin/reports/${PARTITION}"
elif [ "$PARTITION" == "gpu-hp" ] || [ "$PARTITION" == "gpu" ]; then
    OUTPUT_DIR="/data/admin/reports/${PARTITION}"
fi
# Create log file path for capturing output
mkdir -p "$OUTPUT_DIR"
LOG_FILE="${OUTPUT_DIR}/${PARTITION}_${START_DATE}-${END_DATE}.txt"

# Set up output to be saved to log file while also displaying to stdout
exec > >(tee "$LOG_FILE") 2>&1

# Create user-reports directory
USER_REPORTS_DIR="${OUTPUT_DIR}/user-reports"
mkdir -p "$USER_REPORTS_DIR"

# dump slurm-report for each of those users in directory
for user in $(slurm-gpu report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" --summary --plain --duplicates | tail -n +3 | awk -F " " '{print $1}'); do
    slurm-gpu report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" -u "$user" --duplicates > "$USER_REPORTS_DIR/${PARTITION}_${user}_${START_DATE//-/}-${END_DATE//-/}.txt"
done

# Run partition_cpu_gpu_eff_gpuutil.sh
"$UTIL_DIR/partition_cpu_gpu_eff.sh" -r "$PARTITION" -S "$START_DATE" -E "$END_DATE"

# Run gpu_stats_minimal.sh to get GPU usage stats
# "$UTIL_DIR/gpu_stats_minimal.sh" -r "$PARTITION" -S "$START_DATE" -E "$END_DATE"
"$UTIL_DIR/gpu_efficiency_by_count.sh" -r "$PARTITION" -S "$START_DATE" -E "$END_DATE"

# Current GPU quota
if [ "$PARTITION" == "gpu-hp" ]; then
    echo ""
    echo "Current High-Priority Quota Usage"
    "$NCSHARE_DIR/get_gpu_quota.sh" -H
fi

# GPU quota/reset log for high-priority partitions
if [ "$PARTITION" == "gpu-hp" ]; then
    echo ""
    echo "High-Priority Quota Pre-reset Snapshot"
    LOG_DIR="$HOME/logs/${PARTITION}_reset"
    LATEST_LOG=$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | sed -n '1p')

    if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
        cat "$LATEST_LOG"
    else
        echo "No reset log found in $LOG_DIR"
    fi
fi

# list of emails for the users
echo ""
echo "Email list:"
# DCC H200 users of every account matching an awk regex, as user@duke.edu;...
# Accounts: <lab>_h200_hp -> h200-hp, <lab>_h200_s -> h200-shared, and both -> scavenger-h200.
dcc_h200_users() {
    sacctmgr show assoc format=account,user --noheader -P 2>/dev/null \
        | awk -F'|' -v re="$1" '$1 ~ re && $2 != "" { print $2 "@duke.edu" }' | sort -u | paste -sd ';' -
}
if [ $PARTITION == "h200-hp" ]; then
    dcc_h200_users '_h200_hp$'
elif [ $PARTITION == "h200-shared" ]; then
    dcc_h200_users '_h200_s$'
elif [ $PARTITION == "scavenger-h200" ]; then
    dcc_h200_users '_h200_hp$|_h200_s$'
elif [ $PARTITION == "gpu" ]; then
  "$NCSHARE_DIR/get_email_address.sh" -e appstate_h200,campbell_h200,catawba_h200,chowan_h200,davidson_h200,duke_h200,elon_h200,guilford_h200,meredith_h200,ncat_h200,nccu_h200,ncssm_h200,ncsu_h200,unc_h200,charlotte_h200,fsu_h200,uncp_h200,uncw_h200,wcu_h200,wfu_h200,wssu_h200
elif [ $PARTITION == "gpu-hp" ]; then
  "$NCSHARE_DIR/get_email_address.sh" -e davidson_h200_hp,duke_h200_hp,ncat_h200_hp,nccu_h200_hp,ncsu_h200_hp,unc_h200_hp,charlotte_h200_hp,fsu_h200_hp,wssu_h200_hp
fi
echo

# Create tar.gz archive of the user-reports directory
ARCHIVE_NAME="${OUTPUT_DIR}/${PARTITION}_${START_DATE}-${END_DATE}.tar.gz"
tar -czf "$ARCHIVE_NAME" -C "$OUTPUT_DIR" user-reports
rm -rf "${USER_REPORTS_DIR}"
