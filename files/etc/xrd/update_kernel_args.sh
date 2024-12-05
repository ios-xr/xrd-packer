#!/usr/bin/env bash
# This must be run as root

# Add boot cmd line args
non_isolated_cores=$(/etc/xrd/get_non_isolated_cores.sh $ISOLATED_CORES)
grubby --update-kernel ALL --args "nohz_full=${ISOLATED_CORES} nohz=on skew_tick=1 intel_pstate=disable tsc=reliable nosoftlockup isolcpus=${ISOLATED_CORES} irqaffinity=${non_isolated_cores} hugepages=${HUGEPAGES_GB} rcu_nocbs=${ISOLATED_CORES} hugepagesz=1G default_hugepagesz=1G rcupdate.rcu_normal_after_boot=1"
