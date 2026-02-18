#!/usr/bin/env python3

import subprocess
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import pandas as pd
from datetime import datetime, timedelta
import numpy as np
import argparse
import os
import sys

# Try to import the custom plotting utilities and apply style
try:
    sys.path.append(os.path.expanduser("~/dotfiles"))
    plt.style.use("~/dotfiles/matplotlib/prb.mplstyle")
    from my_plot import set_size

    USE_CUSTOM_STYLING = True
except ImportError:
    print(
        "Warning: Could not import custom plotting utilities. Using default matplotlib style."
    )
    USE_CUSTOM_STYLING = False

    def set_size(width, fraction=1.0):
        """Fallback figure size function."""
        return (10 * fraction, 6)


ACCOUNT_COLORS = {
    "appstate": "#1F77B4",
    "davidson": "#D62728",
    "duke": "#2CA02C",
    "elon": "#9467BD",
    "ncat": "#FFA500",
    "nccu": "#17BECF",
    "ncssm": "#8C564B",
    "ncsu": "#E377C2",
    "osg": "#7F7F7F",
    "unc": "#AEC7E8",
    "uncc": "#BCBD22",
    "uncfsu": "#FF7F0E",
    "uncp": "#1F9A8A",
    "undefined": "#B8B8B8",
    "wfu": "#000000",
}


def get_usage_data(start_date, end_date, partitions=None, tres_type="gres/gpu"):
    """Get usage data for all accounts using sreport."""
    partition_filter = f"Partition={partitions}" if partitions else ""
    cmd = f"sreport job SizesByAccount FlatView -t hours Grouping= Format=Account%30 Start={start_date} End={end_date} -T {tres_type} {partition_filter} --noheader"

    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    data = {}

    if result.returncode == 0:
        for line in result.stdout.strip().split("\n"):
            if line.strip():
                parts = line.split()
                if len(parts) >= 4:
                    account_raw = parts[0]
                    # Handle (null) accounts and map to undefined
                    if account_raw == "(null)":
                        account = "undefined"
                    else:
                        account = account_raw.lower()

                    try:
                        usage_hours = float(parts[1])
                        percentage = float(parts[3].rstrip("%"))
                        data[account] = {
                            "usage_hours": usage_hours,
                            "percentage": percentage,
                        }
                    except (ValueError, IndexError):
                        continue

    return data


def generate_monthly_data(start_month, end_month):
    """Generate monthly date ranges from start month to end month (YYYY-MM format)."""
    months = []
    # Parse YYYY-MM format
    start_year, start_month_num = map(int, start_month.split("-"))
    end_year, end_month_num = map(int, end_month.split("-"))

    current = datetime(start_year, start_month_num, 1)
    end = datetime(end_year, end_month_num, 1)

    while current <= end:
        # Always use the full month (first to last day)
        if current.month == 12:
            next_month = datetime(current.year + 1, 1, 1)
        else:
            next_month = datetime(current.year, current.month + 1, 1)

        month_end = next_month - timedelta(days=1)

        months.append(
            {
                "month_start": current.strftime("%Y-%m-%d"),
                "month_end": month_end.strftime("%Y-%m-%d"),
                "month_name": current.strftime("%b %Y"),
            }
        )

        # Move to next month
        current = next_month

    return months


def collect_usage_data(months, partitions="gpu", tres_type="gres/gpu"):
    """Collect usage data for all accounts across all months."""
    all_accounts = set(ACCOUNT_COLORS.keys())
    data = {account: [] for account in all_accounts}
    text_data = []

    for month in months:
        # Get data for specified partitions
        usage_data = get_usage_data(
            month["month_start"], month["month_end"], partitions, tres_type
        )

        month_usage = {}
        for account in all_accounts:
            month_usage[account] = usage_data.get(account, {}).get("usage_hours", 0.0)
            data[account].append(month_usage[account])

        # Prepare text data for this month
        for account in all_accounts:
            if month_usage[account] > 0:
                text_data.append(
                    {
                        "month": month["month_name"],
                        "account": account,
                        "usage_hours": month_usage[account],
                        "percentage": usage_data.get(account, {}).get(
                            "percentage", 0.0
                        ),
                    }
                )

    return data, months, text_data


def write_monthly_text_files(text_data, tres_type="GPU"):
    """Write separate text file for each month."""
    # Group by month
    months = {}
    for entry in text_data:
        month = entry["month"]
        if month not in months:
            months[month] = []
        months[month].append(entry)

    # Sort months chronologically
    sorted_months = sorted(months.keys(), key=lambda x: datetime.strptime(x, "%b %Y"))

    # Create safe filename prefix from tres_type
    tres_label = tres_type.lower().replace("/", "_").replace(" ", "_")

    # Write separate file for each month
    for month in sorted_months:
        # Create filename from month name (replace spaces with underscores)
        filename = f"{tres_label}_usage_{month.replace(' ', '_')}.txt"

        with open(filename, "w") as f:
            f.write(f"{month} {tres_type} Usage Report\n")
            f.write("=" * (len(month) + len(f" {tres_type} Usage Report")) + "\n\n")
            f.write(f"{'Account':<15} {'Hours':<12} {'Percentage':<12}\n")
            f.write("-" * 40 + "\n")

            # Sort by usage hours (descending)
            month_entries = sorted(
                months[month], key=lambda x: x["usage_hours"], reverse=True
            )
            for entry in month_entries:
                f.write(
                    f"{entry['account']:<15} {entry['usage_hours']:>11.2f} {entry['percentage']:>11.2f}%\n"
                )
            f.write("\n")

    return sorted_months


def write_text_report(text_data, filename):
    """Write monthly usage data to a single text file."""
    with open(filename, "w") as f:
        f.write("Monthly GPU Usage Report\n")
        f.write("=" * 50 + "\n\n")

        # Group by month
        months = {}
        for entry in text_data:
            month = entry["month"]
            if month not in months:
                months[month] = []
            months[month].append(entry)

        # Sort months chronologically
        sorted_months = sorted(
            months.keys(), key=lambda x: datetime.strptime(x, "%b %Y")
        )

        for month in sorted_months:
            f.write(f"{month}\n")
            f.write("-" * len(month) + "\n")
            f.write(f"{'Account':<15} {'GPU Hours':<12} {'Percentage':<12}\n")
            f.write("-" * 40 + "\n")

            # Sort by usage hours (descending)
            month_entries = sorted(
                months[month], key=lambda x: x["usage_hours"], reverse=True
            )
            for entry in month_entries:
                f.write(
                    f"{entry['account']:<15} {entry['usage_hours']:>11.2f} {entry['percentage']:>11.2f}%\n"
                )
            f.write("\n")


def plot_stacked_bar_chart(
    data, months, include_osg=True, title_suffix="", resource_type="GPU"
):
    """Create a stacked bar chart."""
    accounts_to_include = [
        acc for acc in ACCOUNT_COLORS.keys() if include_osg or acc != "osg"
    ]

    # Prepare data for plotting
    plot_data = {acc: data[acc] for acc in accounts_to_include}
    colors = [ACCOUNT_COLORS[acc] for acc in accounts_to_include]

    # Create figure
    if USE_CUSTOM_STYLING:
        fig, ax = plt.subplots(1, 1, figsize=set_size(512, 1.0))
    else:
        fig, ax = plt.subplots(figsize=(14, 8))

    # Create stacked bar chart
    bottom = np.zeros(len(months))
    month_labels = [month["month_name"] for month in months]

    for i, account in enumerate(accounts_to_include):
        values = plot_data[account]
        # Only show label in legend if account has usage
        label = account if sum(values) > 0 else None
        ax.bar(
            month_labels,
            values,
            bottom=bottom,
            color=colors[i],
            label=label,
            width=0.6,
        )
        bottom += values

    # Calculate max value for y-axis range (add 10% padding)
    max_usage = max(bottom) if len(bottom) > 0 and max(bottom) > 0 else 1
    y_max = max_usage * 1.1

    # Customize the plot
    ax.set_xlabel("Month")
    ax.set_ylabel(f"{resource_type}-hours")
    ax.set_title(f"Monthly {resource_type} Usage by Account{title_suffix}")
    ax.legend(bbox_to_anchor=(1.05, 1), loc="upper left")

    # Add grid and set y-axis range
    ax.grid(True, alpha=0.3, linestyle="--")
    ax.set_ylim(0, y_max)

    # Rotate x-axis labels for better readability
    plt.xticks(rotation=45)

    # Adjust layout to prevent legend cutoff
    plt.tight_layout()

    return fig, ax


def main():
    parser = argparse.ArgumentParser(
        description="Generate montly resource usage charts from SLURM data"
    )
    parser.add_argument("--start", default="2025-07", help="Start month (YYYY-MM)")
    parser.add_argument("--end", default="2026-01", help="End month (YYYY-MM)")
    parser.add_argument(
        "--partitions",
        default="gpu",
        help="Partitions (comma-separated, e.g., gpu or osg-gpu or gpu,osg-gpu)",
    )
    parser.add_argument(
        "--tres", default="gres/gpu", help="TRES type (e.g., gres/gpu or cpu)"
    )
    args = parser.parse_args()

    # Determine output filenames based on TRES type
    tres_label = args.tres.replace("/", "_").replace(" ", "_")

    print(
        f"Generating monthly {args.tres} usage data from {args.start} to {args.end}..."
    )
    print(f"Using partitions: {args.partitions}")
    months = generate_monthly_data(args.start, args.end)
    print(f"Collected data for {len(months)} months")

    print("Collecting usage data...")
    data, months, text_data = collect_usage_data(months, args.partitions, args.tres)

    # Write separate text files for each month
    print("Writing monthly text files...")
    month_files = write_monthly_text_files(text_data, args.tres.upper())
    print(f"Created {len(month_files)} monthly files")

    # Create chart
    print("Creating usage chart...")
    # Clean up resource type for display (remove GRES/ prefix)
    display_resource = args.tres.upper().replace("GRES/", "")
    fig1, ax1 = plot_stacked_bar_chart(
        data,
        months,
        include_osg=True,
        title_suffix=f" (partitions:{args.partitions})",
        resource_type=display_resource,
    )
    chart_filename = f"{tres_label}_usage.png"
    fig1.savefig(chart_filename, dpi=300, bbox_inches="tight")
    plt.close(fig1)
    print(f"Chart saved as '{chart_filename}'")

    tres_label = args.tres.lower().replace("/", "_").replace(" ", "_")
    print(f"Monthly files saved with prefix '{tres_label}_usage_'")

    # Print summary statistics
    print("\nSummary Statistics:")
    for account in ACCOUNT_COLORS.keys():
        total_usage = sum(data[account])
        if total_usage > 0:
            print(f"{account}: {total_usage:.2f} {args.tres}-hours")


if __name__ == "__main__":
    main()
