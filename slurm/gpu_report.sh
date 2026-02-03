#!/usr/bin/env bash

# Usage:
# gpu_report.sh -p partition -s start_date -e end_date

# Parse command line arguments
while getopts "p:s:e:" opt; do
    case $opt in
        p) PARTITION="$OPTARG";;
        s) START_DATE="$OPTARG";;
        e) END_DATE="$OPTARG";;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    esac
done

# Check if all required arguments are provided
if [ -z "$PARTITION" ] || [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    echo "Usage: $0 -p partition -s start_date -e end_date"
    echo "Example: $0 -p h200alloc -s 2025-12-30 -e 2026-01-08"
    exit 1
fi

# Create slurm-reports directory if it doesn't exist
SLURM_REPORT_DIR="slurm-reports_${PARTITION}_${START_DATE}-${END_DATE}"
mkdir -p "$SLURM_REPORT_DIR"

# dump slurm-report for each of those users in directory
echo "Generating individual user reports..."
for user in $(slurm-report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" --summary --plain | tail -n +5 | awk -F " " '{print $1}'); do
    slurm-report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" -u "$user" > "$SLURM_REPORT_DIR/${PARTITION}_${user}_${START_DATE//-/}-${END_DATE//-/}.txt"
done

# Run partition_gpu_eff_weighted_simple_ordered.sh
./partition_gpu_eff_weighted_simple_ordered_mem_csv.sh -p "$PARTITION" -s "$START_DATE" -e "$END_DATE" -c

# Sub-account utilization
if [ $PARTITION == "h200alloc" ]; then
    echo ""
    echo "=== Sub-account utilization ==="
    echo ""
    #sreport cluster AccountUtilizationByQoS Start=$START_DATE End=$END_DATE -T gres/gpu Accounts=slurm-subaccount-testing_h200_r,slurm-subaccount-testing_h200_u format=Account%32,QOS,Used -t Hours | tail -n +4
    u_sum=$(slurm-report -r h200alloc -A slurm-subaccount-testing_h200_u -S "${START_DATE}" -E "${END_DATE}" --summary --plain \
            | tail -n +5 \
            | awk '{s+=$3} END {print s}')
    r_sum=$(slurm-report -r h200alloc -A slurm-subaccount-testing_h200_r -S "${START_DATE}" -E "${END_DATE}" --summary --plain \
            | tail -n +5 \
            | awk '{s+=$3} END {print s}')
    echo "slurm-subaccount-testing_h200_u: ${u_sum} GPU-hours"
    echo "slurm-subaccount-testing_h200_r: ${r_sum} GPU-hours"
fi

# Run gpu_stats_minimal.sh to get GPU usage stats
./gpu_stats_minimal.sh -p "$PARTITION" -s "$START_DATE" -e "$END_DATE"

# list of emails for the users
echo ""
echo "Email list for users:"
#for i in $(slurm-report -r "$PARTITION" -S "$START_DATE" -E "$END_DATE" --summary --plain | tail -n +5 | awk -F " " '{print $1}'); do echo -n "$i@duke.edu,"; done
if [ $PARTITION == "h200alloc" ]; then
    for i in `sacctmgr show assoc where account=slurm-subaccount-testing_h200_u format=user --noheader`; do echo -n $i@duke.edu\;;done
elif [ $PARTITION == "h200ea" ]; then
    for i in `sacctmgr show assoc where account=h200ea format=user --noheader`; do echo -n $i@duke.edu\;;done
fi
echo
