#!/bin/bash
# This script extracts NetIDs of users associated with H200 HP Labs accounts from a CSV file.

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
   #} | awk 'NF { print $1 "@duke.edu" }' | sort -u | paste -sd ';' -
   } | awk 'NF { print $1 }' | sort -u | paste -sd '\n' -
else
   echo "Error: CSV file not found at $H200_HP_CSV" >&2
fi
