#!/bin/bash
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions common --tres cpu
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions osg --tres cpu
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions common,osg --tres cpu
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions gpu --tres gres/gpu
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions gpu,osg-gpu --tres gres/gpu
./monthly_account_usage.py --start 2025-07 --end 2026-07 --partitions osg-gpu --tres gres/gpu
./monthly_account_usage.py --start 2026-02 --end 2026-07 --partitions gpu-hp --tres gres/gpu
