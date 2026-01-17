#!/usr/bin/env bash
# gpu_usage.sh
# Compute GPU usage for user during a specified time period.
# Usage: ./gpu_usage.sh -A ACCOUNT -S START -E END

# Set defaults
ACCOUNT="h200ea"
START="now-1weeks"
END="now"

# Parse command line arguments
while getopts "A:S:E:" opt; do
    case $opt in
        A) ACCOUNT="$OPTARG" ;;
        S) START="$OPTARG" ;;
        E) END="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

sreport cluster AccountUtilizationByUser Start=$START End=$END -T gres/gpu Accounts=$ACCOUNT User=${USER}
