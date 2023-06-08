packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "source_ami_id" {
  type        = string
  default     = null
  description = "(Optional) source AMI to use as a base"
}

variable "version" {
  type        = string
  default     = "1.26"
  description = "EKS Cluster Kubernetes version"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to add to the created AMI"
}

locals {
  default_tags = {
    Generated_By       = "xrd-packer"
    Kubernetes_Version = var.version
    Base_AMI_ID        = "{{ .SourceAMI }}"
    Base_AMI_Name      = "{{ .SourceAMIName }}"
  }
}

source "amazon-ebs" "base" {
  ami_name      = format("xrd-%s-{{timestamp}}", var.version)
  instance_type = "m5.xlarge"
  ssh_username  = "ec2-user"

  source_ami = var.source_ami_id

  source_ami_filter {
    most_recent = true
    owners      = ["amazon"]

    filters = {
      name                = format("amazon-eks-node-%s-*", var.version)
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
  }

  tags = merge(local.default_tags, var.tags)
}

locals {
  assets_dir = "/tmp/worker"
}

build {
  sources = ["source.amazon-ebs.base"]

  provisioner "shell" {
    inline = [format("mkdir -p %s", local.assets_dir)]
  }

  provisioner "file" {
    source      = "${path.root}/files/"
    destination = local.assets_dir
  }

  provisioner "shell" {
    env             = { "ASSETS_DIR" : local.assets_dir }
    execute_command = "sudo sh -c \"{{ .Vars }} {{ .Path }}\""
    script          = "${path.root}/install.sh"
  }
}
