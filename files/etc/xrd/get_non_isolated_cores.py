#!/usr/bin/python3

import os
import sys

def expand_range(range_str):
    """Expand a range string like '2-4,6' into a list of integers."""
    expanded = []
    for part in range_str.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            expanded.extend(range(start, end + 1))
        else:
            expanded.append(int(part))
    return expanded

def compress_to_range(cpu_list):
    """Compress a list of integers into a range string like '2-4,6'."""
    cpu_list = sorted(cpu_list)
    ranges = []
    start = cpu_list[0]
    end = start

    for i in range(1, len(cpu_list)):
        if cpu_list[i] == end + 1:
            end = cpu_list[i]
        else:
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")
            start = cpu_list[i]
            end = start

    if start == end:
        ranges.append(str(start))
    else:
        ranges.append(f"{start}-{end}")

    return ','.join(ranges)

def exclude_cpus(exclude_set_str):
    """Return a CPU set excluding the specified CPUs."""
    all_cpus = set(range(os.cpu_count()))
    exclude_cpus = set(expand_range(exclude_set_str))
    included_cpus = sorted(all_cpus - exclude_cpus)
    return compress_to_range(included_cpus)

def main():
    if len(sys.argv) < 2:
        # No arguments provided, return all CPUs
        all_cpus = list(range(os.cpu_count()))
        print(compress_to_range(all_cpus))
    else:
        exclude_set_str = sys.argv[1]
        print(exclude_cpus(exclude_set_str))

if __name__ == "__main__":
    main()