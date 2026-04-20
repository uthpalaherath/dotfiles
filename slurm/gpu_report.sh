#!/usr/bin/env bash

# Usage:
# gpu_report.sh -r partition -S start_date -E end_date

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
    echo "Example: $0 -r h200alloc -S 2025-12-30 -E 2026-01-08"
    exit 1
fi

# Create log file path for capturing output
OUTPUT_DIR="$HOME/logs/${PARTITION}"
mkdir -p "$OUTPUT_DIR"
LOG_FILE="${OUTPUT_DIR}/${PARTITION}_${START_DATE}-${END_DATE}.txt"

# Set up output to be saved to log file while also displaying to stdout
exec > >(tee -a "$LOG_FILE") 2>&1

# Create user-reports directory
USER_REPORTS_DIR="${OUTPUT_DIR}/user-reports"
mkdir -p "$USER_REPORTS_DIR"

# dump slurm-report for each of those users in directory
for user in $(slurm-gpu report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" --summary --plain | tail -n +3 | awk -F " " '{print $1}'); do
    slurm-gpu report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" -u "$user" > "$USER_REPORTS_DIR/${PARTITION}_${user}_${START_DATE//-/}-${END_DATE//-/}.txt"
done

# Run partition_gpu_eff.sh
./partition_gpu_eff.sh -r "$PARTITION" -S "$START_DATE" -E "$END_DATE"

# Sub-account utilization
if [ $PARTITION == "h200alloc" ]; then
    echo ""
    echo "=== Sub-account utilization ==="
    echo ""
    #sreport cluster AccountUtilizationByQoS Start=$START_DATE End=$END_DATE -T gres/gpu Accounts=slurm-subaccount-testing_h200_r,slurm-subaccount-testing_h200_u format=Account%32,QOS,Used -t Hours | tail -n +4
    u_sum=$(slurm-gpu report -r h200alloc -A slurm-subaccount-testing_h200_u -S "${START_DATE}" -E "${END_DATE}" --summary --plain \
            | tail -n +3 \
            | awk '{s+=$3} END {print s}')
    r_sum=$(slurm-gpu report -r h200alloc -A slurm-subaccount-testing_h200_r -S "${START_DATE}" -E "${END_DATE}" --summary --plain \
            | tail -n +3 \
            | awk '{s+=$3} END {print s}')
    echo "slurm-subaccount-testing_h200_u: ${u_sum} GPU-hours"
    echo "slurm-subaccount-testing_h200_r: ${r_sum} GPU-hours"
fi

# Run gpu_stats_minimal.sh to get GPU usage stats
./gpu_stats_minimal.sh -r "$PARTITION" -S "$START_DATE" -E "$END_DATE"

# GPU quota for high-priority account
if [ $PARTITION == "gpu-hp" ]; then
    echo ""
    echo "High-Priority Monthly GPU Quota:"
    get_gpu_quota.sh -H
fi

# list of emails for the users
echo ""
echo "Email list:"
if [ $PARTITION == "h200-hp" ]; then
    H200_HP_CSV="/hpc/home/ukh/accounting/h200-hp-labs.csv"
    if [ -f "$H200_HP_CSV" ]; then
        {
            while IFS=, read -r parent_account unrestricted_account restricted_account _; do
                parent_account=${parent_account//$'\r'/}
                unrestricted_account=${unrestricted_account//$'\r'/}
                restricted_account=${restricted_account//$'\r'/}

                [ "$parent_account" = "Parent Account" ] && continue
                [ -z "$parent_account" ] && continue

                sacctmgr show assoc where account="$unrestricted_account" format=user --noheader 2>/dev/null
                sacctmgr show assoc where account="$restricted_account" format=user --noheader 2>/dev/null
            done < "$H200_HP_CSV"
        } | awk 'NF { print $1 "@duke.edu" }' | sort -u | paste -sd ';' -
    else
        echo "Error: CSV file not found at $H200_HP_CSV" >&2
    fi
elif [ $PARTITION == "scavenger-h200" ]; then
    for i in `sacctmgr show assoc where account=scavenger-h200 format=user --noheader`; do echo -n $i@duke.edu\;;done
elif [ $PARTITION == "gpu" ]; then
  ./get_email_address.sh appstate_h200,campbell_h200,catawba_h200,chowan_h200,davidson_h200,duke_h200,elon_h200,guilford_h200,meredith_h200,ncat_h200,nccu_h200,ncssm_h200,ncsu_h200,unc_h200,charlotte_h200,fsu_h200,uncp_h200,uncw_h200,wfu_h200,wssu_h200
elif [ $PARTITION == "gpu-hp" ]; then
  ./get_email_address.sh davidson_h200_hp,duke_h200_hp,ncat_h200_hp,nccu_h200_hp,ncsu_h200_hp,unc_h200_hp,charlotte_h200_hp,fsu_h200_hp,wssu_h200_hp
fi
echo

# Create tar.gz archive of the user-reports directory
ARCHIVE_NAME="${OUTPUT_DIR}/${PARTITION}_${START_DATE}-${END_DATE}.tar.gz"
tar -czf "$ARCHIVE_NAME" -C "$OUTPUT_DIR" user-reports
rm -rf "${USER_REPORTS_DIR}"
