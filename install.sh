#!/usr/bin/env bash
# This script must be run as the root user.

set -ex

dnf install -y \
    "kernel-devel-$(uname -r)" \
    git

# Download and build the igb_uio driver, and load it into the kernel.
# N.B. A warning for 'Skipping BTF generation' is expected. This doesn't affect
# the performance of the built driver.
git clone git://dpdk.org/dpdk-kmods
cd dpdk-kmods
git checkout e721c733cd24206399bebb8f0751b0387c4c1595
make -C linux/igb_uio
cp dpdk-kmods/linux/igb_uio/igb_uio.ko "/lib/modules/$(uname -r)/kernel/drivers/uio"
depmod "$(uname -r)"
cd ../
rm -rf dpdk-kmods

# TuneD is not available in the Amazon Linux 2023 repository, so download our
# own version instead.
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
if ! make -C tuned install; then
    echo "desktop-file-install failure is expected. Continuing with installation..."
fi
rm -rf tuned

# Set up the sysctls.
# These override values already in /etc/sysctl.conf
cat "$ASSETS_DIR/xrd-sysctl.conf" >> /etc/sysctl.conf

# Copy the files in the etc/ subfolder into /etc
cp -r "$ASSETS_DIR/etc/" /

# Copy the files in the usr/ subfolder into /usr
cp -r "$ASSETS_DIR/usr/" /
