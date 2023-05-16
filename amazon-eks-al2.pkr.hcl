data "amazon-ami" "this" {
  filters = {
    architecture        = var.source_ami_arch
    name                = "${var.ami_name_prefix}-${var.eks_version}-*"
    root-device-type    = "ebs"
    state               = "available"
    virtualization-type = "hvm"
  }

  most_recent = true
  owners = [
    var.source_ami_owner,
    var.source_ami_owner_govcloud,
  ]
  region = var.aws_region
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  target_ami_name = "${var.ami_name_prefix}-${var.eks_version}-v${local.timestamp}"

  block_device_mappings = {
    "/" = {
      device_name = "/dev/xvda"
      volume_size = var.root_volume_size
    }
    "/home" = {
      device_name = "/dev/sdf"
      volume_size = var.home_volume_size
    }
    "/var" = {
      device_name = "/dev/sdg"
      volume_size = var.var_volume_size
    }
    "/var/log" = {
      device_name = "/dev/sdh"
      volume_size = var.varlog_volume_size
    }
    "/var/log/audit" = {
      device_name = "/dev/sdi"
      volume_size = var.varlogaudit_volume_size
    }
    "/var/lib/containerd" = {
      device_name = "/dev/sdj"
      volume_size = var.varlibcontainerd_volume_size
    }
  }
}

source "amazon-ebs" "this" {
  ami_description         = "EKS Kubernetes Worker AMI with AmazonLinux2 image"
  ami_name                = local.target_ami_name
  ami_virtualization_type = "hvm"
  instance_type           = var.instance_type

  dynamic "ami_block_device_mappings" {
    for_each = local.block_device_mappings

    content {
      device_name           = ami_block_device_mappings.value.device_name
      volume_size           = ami_block_device_mappings.value.volume_size
      delete_on_termination = true
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  dynamic "launch_block_device_mappings" {
    for_each = local.block_device_mappings

    content {
      device_name           = launch_block_device_mappings.value.device_name
      volume_size           = launch_block_device_mappings.value.volume_size
      delete_on_termination = true
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_id
    }
  }

  encrypt_boot = var.encrypt_boot
  kms_key_id   = var.kms_key_id

  region = var.aws_region

  run_tags = {
    Name = local.target_ami_name
  }

  source_ami = data.amazon-ami.this.id

  subnet_id     = var.subnet_id
  ssh_pty       = true
  ssh_interface = var.ssh_interface
  ssh_username  = var.source_ami_ssh_user

  associate_public_ip_address               = var.associate_public_ip_address
  temporary_security_group_source_cidrs     = var.temporary_security_group_source_cidrs
  temporary_security_group_source_public_ip = var.temporary_security_group_source_public_ip

  ami_regions        = var.ami_regions
  region_kms_key_ids = var.region_kms_key_ids
  ami_org_arns       = var.ami_org_arns
  ami_users          = var.ami_users
  snapshot_users     = var.snapshot_users

  tags = {
    os_version        = "Amazon Linux 2"
    source_image_name = "{{ .SourceAMIName }}"
    ami_type          = "al2"
  }
}

build {
  sources = ["source.amazon-ebs.this"]

  provisioner "shell" {
    execute_command   = "echo 'packer' | {{ .Vars }} sudo -S -E bash -eux '{{ .Path }}'"
    expect_disconnect = true
    pause_after       = "15s"
    script            = "scripts/update.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} sudo -S -E bash -eux '{{ .Path }}'"
    environment_vars = [
      "HTTP_PROXY=${var.http_proxy}",
      "HTTPS_PROXY=${var.https_proxy}",
      "NO_PROXY=${var.no_proxy}",
    ]

    expect_disconnect = true
    pause_after       = "15s"
    scripts = [
      "scripts/partition-disks.sh",
      "scripts/configure-proxy.sh",
      "scripts/configure-containers.sh",
    ]
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} sudo -S -E bash -eux '{{ .Path }}'"

    env = {
      MOTD_CONTENT = var.motd_content
    }

    scripts = [
      "scripts/cis-benchmark.sh",
      "scripts/cis-docker.sh",
      "scripts/cis-eks.sh",
      "scripts/cleanup.sh",
    ]
  }
}
