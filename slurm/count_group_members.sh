#!/bin/bash

# Get the current user's groups
for group in $(groups); do
    # Get supplementary members
    members=$(getent group "$group" | cut -d: -f4 | tr ',' '\n' | grep -v '^$')
    count=$(echo "$members" | wc -l)

    # Print nicely formatted output
    printf "%-30s %5d\n" "$group" "$count"
done
