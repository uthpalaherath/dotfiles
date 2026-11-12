#!/bin/bash
HERE="$HOME/dotfiles/slurm/utilities"
# Per-account GPU-hours + efficiency for h200-hp, one file per month.
# Run on a LOGIN node: the efficiency pass needs
# slurm-gpu, which is not installed on compute nodes.
# h200-hp only - scavenger-h200 charges ~everything to one catch-all
# account, so a per-account breakdown there says nothing.
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-05 -E 2026-05 --with-efficiency
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-06 -E 2026-06 --with-efficiency
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-07 -E 2026-07 --with-efficiency
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-08 -E 2026-08 --with-efficiency
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-09 -E 2026-09 --with-efficiency
"$HERE/monthly_account_gpu_hours.sh" -r h200-hp -S 2026-10 -E 2026-10 --with-efficiency
