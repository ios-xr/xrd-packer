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
is used to control the Amazon EKS optimized Amazon Linux 2 base AMI that
is used to generate the image and also as a tag on the produced image.

To build an AMI:
  1. Clone this repository
  2. Initialize Packer
  3. Run the Packer build with the Packer template.

This can be done by running the following commands from the base of the of
the cloned repository:

```
packer init .
packer build -var kubernetes_version=1.28 amazon-ebs.pkr.hcl
```

The source AMI can be overridden by specifying the `source_ami_id` variable,
e.g.:

```
packer build \
  -var kubernetes_version=1.27 \
  -var source_ami_id=ami-0f114867066b78822
```

Arbitrary additional tags can be added to the AMI by specifying a JSON
map of tags as the `tags` variable, e.g.:

```
packer build \
  -var kubernetes_version=1.27 \
  -var 'tags={"mykey": "myvalue", "myotherkey": "myothervalue"}'
```

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
to ensure it's run on first boot. An example user data for this is:

```bash
#!/usr/bin/env bash
HUGEPAGES_GB=6 ISOLATED_CORES=16-23 /etc/xrd/bootstrap.sh
/etc/eks/bootstrap.sh my-cluster-name
reboot
```

## Image Tuning

The XRd documentation contains more details on required and recommended
host OS settings.

The Packer template uses resources in this repository to run the following
tuning steps:
  - Install the [TuneD](https://github.com/redhat-performance/tuned) tool.
  - Install an XRd TuneD profile, and run it.
  - Build, install, and activate the `igb_uio` interface driver kernel module.
  - Set up recommended core handling behavior.
  - Set up hugepage handling for systems with more than one NUMA node.
