#!/usr/bin/env bash

# Get complement of isolated cores.
function get_all_cpus() {
    lscpu | grep "CPU(s):" | head -n 1 | awk '{print $2}'
}

# Convert a range string (e.g., "2-4") to an array of numbers
function expand_range() {
    local range_str=$1
    local expanded=()

    IFS=',' read -ra ranges <<< "$range_str"
    for range in "${ranges[@]}"; do
        if [[ $range == *"-"* ]]; then
            IFS='-' read start end <<< "$range"
            expanded+=($(seq $start $end))
        else
            expanded+=($range)
        fi
    done

    echo "${expanded[@]}"
}

# Compress an array of numbers into a range string
function compress_to_range() {
    local cpu_array=($(echo "$@" | tr ' ' '\n' | sort -n))
    local range_str=""
    local start=${cpu_array[0]}
    local end=$start

    for ((i=1; i<${#cpu_array[@]}; i++)); do
        if [ ${cpu_array[i]} -eq $((end + 1)) ]; then
            end=${cpu_array[i]}
        else
            if [ $start -eq $end ]; then
                range_str+="$start,"
            elif [ $((start + 1)) -eq $end ]; then
                range_str+="$start,$end,"
            else
                range_str+="$start-$end,"
            fi
            start=${cpu_array[i]}
            end=$start
        fi
    done

    if [ $start -eq $end ]; then
        range_str+="$start"
    elif [ $((start + 1)) -eq $end ]; then
        range_str+="$start,$end,"
    else
        range_str+="$start-$end"
    fi

    echo "$range_str"
}

# Function to generate a CPU set excluding specified cores
function exclude_cpus() {
    local exclude_set_str=$1
    local exclude_set=($(expand_range "$exclude_set_str"))
    local total_cpus=$(get_all_cpus)

    # Generate a sequence of all CPU cores
    local all_cpus=($(seq 0 $((total_cpus - 1))))

    # Exclude specified cores
    local included_cpus=()
    for cpu in "${all_cpus[@]}"; do
        if [[ ! " ${exclude_set[@]} " =~ " ${cpu} " ]]; then
            included_cpus+=($cpu)
        fi
    done

    # Compress the included CPUs to a range string
    local included_range=$(compress_to_range "${included_cpus[@]}")
    echo "$included_range"
}

# Main script execution
if [ "$#" -eq 0 ]; then
    # No arguments provided, return all CPUs
    total_cpus=$(get_all_cpus)
    all_cpus=$(seq 0 $((total_cpus - 1)))
    all_cpus_range=$(compress_to_range $all_cpus)
    echo "$all_cpus_range"
else
    exclude_set=$1
    exclude_cpus "$exclude_set"
fi