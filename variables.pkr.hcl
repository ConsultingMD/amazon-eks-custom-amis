variable "aws_region" {
  description = "Region where AMI will be created"
  type        = string
  default     = "us-west-2"
}

variable "data_volume_size" {
  description = "Size of the AMI data EBS volume"
  type        = number
  default     = 50
}

variable "root_volume_size" {
  description = "Size of the AMI root EBS volume"
  type        = number
  default     = 10
}

variable "encrypt_boot" {
  description = "Whether or not to encrypt the resulting AMI when copying a provisioned instance to an AMI."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "ID, alias or ARN of the KMS key to use for AMI encryption. This only applies to the main."
  type        = string
  default     = null
}

variable "region_kms_key_ids" {
  description = "Regions to copy the ami to, along with the custom kms key id (alias or arn) to use for encryption for that region."
  type        = map(string)
  default     = null
}

variable "eks_version" {
  description = "The EKS cluster version associated with the AMI created"
  type        = string
  default     = "1.22"
}

variable "http_proxy" {
  description = "The HTTP proxy to set on the AMI created"
  type        = string
  default     = ""
}

variable "https_proxy" {
  description = "The HTTPS proxy to set on the AMI created"
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "Disables proxying on the AMI created"
  type        = string
  default     = ""
}

variable "source_ami_arch" {
  description = "The architecture of the source AMI. Either `x86_64` or `arm64`"
  type        = string
  default     = "x86_64"
}

variable "source_ami_owner" {
  description = "The owner of the source AMI"
  type        = string
  default     = "amazon"
}

variable "source_ami_owner_govcloud" {
  description = "The owner of the source AMI in the GovCloud region"
  type        = string
  default     = "219670896067"
}

variable "source_ami_ssh_user" {
  description = "The SSH user used when connecting to the AMI for provisioning"
  type        = string
  default     = "ec2-user"
}

variable "subnet_id" {
  description = "The subnet ID where the AMI can be created. Required if a default VPC is not present in the `aws_region`"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The instance type to use when creating the AMI. Note: this should be adjusted based on the `source_ami_arch` provided"
  type        = string
  default     = "c6i.large"
}

variable "ami_name_prefix" {
  description = "The prefix to use when creating the AMI name. i.e. - `<ami_name_prefix>-<eks_version>-<timestamp>"
  type        = string
  default     = "amazon-eks-node"
}

variable "associate_public_ip_address" {
  description = "If using a non-default VPC, public IP addresses are not provided by default. If this is true, your new instance will get a Public IP."
  type        = bool
  default     = false
}


variable "temporary_security_group_source_cidrs" {
  description = "A list of IPv4 CIDR blocks to be authorized access to the instance, when packer is creating a temporary security group."
  type        = list(string)
  default     = []
}

variable "temporary_security_group_source_public_ip" {
  description = "When enabled, use public IP of the host (obtained from https://checkip.amazonaws.com) as IPv4 CIDR block to be authorized access to the instance, when packer is creating a temporary security group"
  type        = bool
  default     = false
}

variable "ssh_interface" {
  description = "If set, either the public IP address, private IP address, public DNS name or private DNS name will be used as the host for SSH. The default behaviour if inside a VPC is to use the public IP address if available, otherwise the private IP address will be used. If not in a VPC the public DNS name will be used."
  type        = string
  default     = "private_ip"
}

variable "ami_regions" {
  description = "A list of regions to copy the AMI to. Tags and attributes are copied along with the AMI. AMI copying takes time depending on the size of the AMI, but will generally take many minutes."
  type        = list(string)
  default     = []
}

variable "ami_org_arns" {
  description = "A list of Amazon Resource Names (ARN) of AWS Organizations that have access to launch the resulting AMI(s)."
  type        = list(string)
  default     = []
}

variable "ami_users" {
  description = "A list of account IDs that have access to launch the resulting AMI(s). By default no additional users other than the user creating the AMI has permissions to launch it."
  type        = list(string)
  default     = []
}

variable "snapshot_users" {
  description = "A list of account IDs that have access to create volumes from the snapshot(s)."
  type        = list(string)
  default     = []
}
