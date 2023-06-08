#!/usr/bin/env bash
# This must be run as root.

set -o pipefail
set -o errexit

# Check required environment is set.
e=0
if [ -z "$HUGEPAGES_GB" ]; then
  >&2 echo "HUGEPAGES_GB environment variable not set"
  e=1
fi

if [ -z "$ISOLATED_CORES" ]; then
  >&2 echo "ISOLATED_CORES environment variable not set"
  e=1
fi

if [ "$e" -eq 1 ]; then
  exit 2
fi

# Having checked environment now error on unset.
set -o nounset

# Copy the ISOLATED_CPUS into the tuned settings.
sed "s/^isolated_cores=.*/isolated_cores=${ISOLATED_CORES}/" -i /etc/tuned/xrd-eks-node-variables.conf

# Copy HUGEPAGES_GB into the tuned settings and hugetlb service env.
# Get the number of NUMA nodes.
numa_node_count=$(lscpu | grep -F "NUMA node(s)" | awk '{ print $3 }')

# Multiply the requested hugepages by the number of NUMA nodes at boot
# so we're guaranteed a contiguous block of pages on each node.
# Then during early boot the systemd service will unreserve all the
# hugepages from all nodes except the first.
boot_hugepages=$((HUGEPAGES_GB * numa_node_count))

sed "s/^hugepages_gb=.*/hugepages_gb=${boot_hugepages}/" -i /etc/tuned/xrd-eks-node-variables.conf
echo "HUGEPAGES_GB=${HUGEPAGES_GB}" > /etc/xrd/hugetlb-reserve-env.conf

# Start and enable TuneD.
systemctl start tuned
systemctl enable tuned
tuned-adm profile xrd-eks-node

# Sanity check for logs that the correct profile is active.
tuned-adm active

# Enable and run the hugepage configuration service.
systemctl start hugetlb-gigantic-pages
systemctl enable hugetlb-gigantic-pages
