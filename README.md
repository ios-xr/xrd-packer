# XRd AMI Build Specification

This repository can be used to build an AMI suitable for running
XRd vRouter using [HashiCorp Packer](https://www.packer.io/).

The repository contains resources to help set up a host OS with recommended
best-practices for high-performance XRd vRouter applications, and Packer
templates to use these resources to create an AMI.

## Building an AMI

You must have Packer installed, see
[the official instructions](https://developer.hashicorp.com/packer/downloads).

The template has a single mandatory argument, `kubernetes_version`, which
is used to control the Amazon EKS optimized Amazon Linux 2023 base AMI that
is used to generate the image and also as a tag on the produced image.

To build an AMI:
  1. Clone this repository
  2. Initialize Packer
  3. Run the Packer build with the Packer template.

This can be done by running the following commands from the base of the of
the cloned repository:

```
packer init .
packer build -var kubernetes_version=1.32 amazon-ebs.pkr.hcl
```

The source AMI can be overridden by specifying the `source_ami_id` variable,
e.g.:

```
packer build \
  -var kubernetes_version=1.32 \
  -var source_ami_id=ami-0f114867066b78822 \
  amazon-ebs.pkr.hcl
```

Arbitrary additional tags can be added to the AMI by specifying a JSON
map of tags as the `tags` variable, e.g.:

```
packer build \
  -var kubernetes_version=1.32 \
  -var 'tags={"mykey": "myvalue", "myotherkey": "myothervalue"}' \
  amazon-ebs.pkr.hcl
```

Note that when building the AMI, the following warnings are expected and can be ignored:

* When building the igb_uio driver, a warning for 'Skipping BTF generation' is expected. This doesn't affect the performance of the built driver.
* When building TuneD, the 'desktop-file-install' action is expected to fail. This doesn't affect the installation of the tuned service.

## Using AMIs

The AMIs produced by the template here require further configuration
on first boot, to enable the same AMI to be used across multiple different
EC2 instance types.

When using an AMI to launch an EC2 instance, the `/etc/xrd/bootstrap.sh`
script should be run to finish configuring the worker node. This script
requires the following environment variables to be set:
  - `HUGEPAGES_GB` to the number of required 1GiB hugepages. This should be
    calculated based on the numbers from the XRd Data Sheet, and depends
    on the deployment role XRd is being used for.
  - `ISOLATED_CORES` to the cpuset that should be isolated from the
    rest of the system, and used for an XRd vRouter dataplane. Again, this
    depends on the deployment role XRd is being used for an should be
    calculated based on the XRd Data Sheet.

After this script is run the node must be rebooted for it to take effect.

Additionally, to ensure the worker node joins an EKS cluster, the normal
EKS bootstrap script must be called.

It's recommended to set this up in the User Data for the EC2 instance
to ensure it's run on first boot. An example section containing this in a MIME
multi-part user-data is:

```bash
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

<Other MIME sections, including for NodeConfig>

--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
HUGEPAGES_GB=6 ISOLATED_CORES=16-23 /etc/xrd/bootstrap.sh
reboot

--BOUNDARY--
```

## Image Tuning

The XRd documentation contains more details on required and recommended
host OS settings.

The Packer template uses resources in this repository to run the following
tuning steps:
  - Install the [TuneD](https://github.com/redhat-performance/tuned) tool.
  - Install an XRd TuneD profile, and run it.
  - Set up recommended boot cmdline arguments
  - Build, install, and activate the `igb_uio` interface driver kernel module.
  - Set up recommended core handling behavior.
  - Set up hugepage handling for systems with more than one NUMA node.

Note that the TuneD bootloader plugin does not work in Amazon Linux 2023. The packer template matches the cmdline arguments set by the `realtime-virtual-guest` TuneD profile, in addition to the `default_hugepagesz`, `hugepagesz` and `hugepages` arguments.

## Amazon Linux 2

Amazon Linux 2 is EOL.

To create AMIs for AL2, see the AL2 tagged version of XRd Packer.
