#!/usr/bin/env bash
# This script must be run as the root user.

set -ex

yum install -y \
    "kernel-devel-$(uname -r)" \
    git

# Download and build the igb_uio driver, and load it into the kernel.
git clone git://dpdk.org/dpdk-kmods
cd dpdk-kmods
git switch e721c733cd24206399bebb8f0751b0387c4c1595 --detach
make -C linux/igb_uio
cp linux/igb_uio/igb_uio.ko "/lib/modules/$(uname -r)/kernel/drivers/uio"
depmod "$(uname -r)"
cd ../
rm -rf dpdk-kmods

# Download a much newer version of TuneD that available from the
# Amazon Linux 2 repositories. This fixes several issues with the old
# version available there.
yum install -y \
    dbus \
    dbus-python \
    ethtool \
    gawk \
    polkit \
    python-configobj \
    python-decorator \
    python-gobject \
    python-linux-procfs \
    python-perf \
    python-pyudev \
    python-schedutils \
    tuna \
    util-linux \
    virt-what

mkdir tuned
curl -L https://github.com/redhat-performance/tuned/archive/refs/tags/v2.20.0.tar.gz | tar -xz -C tuned --strip-components 1
# N.B. The 'desktop-file-install' action is expected to fail. This doesn't
# affect the installation of the tuned service.
if ! make -C tuned PYTHON=/usr/bin/python2 install; then
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
