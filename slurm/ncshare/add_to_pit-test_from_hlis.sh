#!/bin/bash
# Add all hlis group members to the pit-test Slurm account.

for user in $(getent group hlis | cut -d: -f4 | tr ',' ' '); do
    sacctmgr --immediate add user "$user" account=pit-test || true
done
