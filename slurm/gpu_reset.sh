#!/usr/bin/env bash

LOGFILE="/hpc/home/ukh/log/h200_usage_reset.log"
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")

# Run resets (auto-confirm with 'y')
echo "y" | sacctmgr modify account slurm-subaccount-testing_h200 set RawUsage=0
echo "y" | sacctmgr modify account slurm-subaccount-testing_h200_u set RawUsage=0
echo "y" | sacctmgr modify account slurm-subaccount-testing_h200_r set RawUsage=0
echo "y" | sacctmgr modify qos where name=h200alloc-r set RawUsage=0
echo "y" | sacctmgr modify qos where name=h200alloc-u set RawUsage=0
echo "y" | sacctmgr modify qos h200alloc-u set GrpTRESMins=billing=10000
echo "y" | sacctmgr modify qos h200alloc-r set GrpTRESMins=billing=10000

# Append timestamp
echo "$TIMESTAMP reset executed" >> "$LOGFILE"
