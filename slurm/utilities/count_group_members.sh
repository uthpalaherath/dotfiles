#!/bin/bash
# Get a count of users in each group

for group in $(groups); do
    members=$(getent group "$group" | cut -d: -f4 | tr ',' '\n' | grep -v '^$')
    count=$(echo "$members" | wc -l)
    printf "%-30s %5d\n" "$group" "$count"
done
