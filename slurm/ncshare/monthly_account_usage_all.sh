#!/bin/bash
HERE="$HOME/dotfiles/slurm/ncshare"
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions common --tres cpu
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions osg --tres cpu
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions common,osg --tres cpu
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions gpu --tres gres/gpu
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions gpu,osg-gpu --tres gres/gpu
"$HERE/monthly_account_usage.py" --start 2025-07 --end 2026-10 --partitions osg-gpu --tres gres/gpu
"$HERE/monthly_account_usage.py" --start 2026-02 --end 2026-10 --partitions gpu-hp --tres gres/gpu
