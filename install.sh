#!/usr/bin/env bash
# This script must be run as the root user.

set -x

# Download and build the igb_uio driver, and load it into the kernel.
dnf install -y \
    "kernel-devel-$(uname -r)" \
    dwarves

mkdir igb_uio
curl https://git.dpdk.org/dpdk-kmods/snapshot/dpdk-kmods-e721c733cd24206399bebb8f0751b0387c4c1595.tar.gz | tar -xz -C igb_uio --strip-components 1
make -C igb_uio/linux/igb_uio
cp igb_uio/linux/igb_uio/igb_uio.ko "/lib/modules/$(uname -r)/kernel/drivers/uio"
depmod "$(uname -r)"
rm -rf igb_uio

# Download a much newer version of TuneD that available from the
# Amazon Linux 2 repositories. This fixes several issues with the old
# version available there.
dnf install -y \
    dbus \
    ethtool \
    gawk \
    polkit \
    python-configobj \
    python-decorator \
    python-gobject \
    python-linux-procfs \
    python-perf \
    python-pyudev \
    util-linux \
    virt-what

mkdir tuned
curl -L https://github.com/redhat-performance/tuned/archive/refs/tags/v2.24.1.tar.gz | tar -xz -C tuned --strip-components 1
# N.B. The 'desktop-file-install' action is expected to fail. This doesn't
# affect the installation of the tuned service.
make -C tuned install
rm -rf tuned

# Set up the sysctls.
# These override values already in /etc/sysctl.conf
cat "$ASSETS_DIR/xrd-sysctl.conf" >> /etc/sysctl.conf

# Copy the files in the etc/ subfolder into /etc
cp -r "$ASSETS_DIR/etc/" /

# Copy the files in the usr/ subfolder into /usr
cp -r "$ASSETS_DIR/usr/" /
