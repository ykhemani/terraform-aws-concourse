# aws
variable region {
  type        = string
  description = "AWS Region in which to deploy our instance."
  default     = "us-west-2"
}

variable vpc_id {
  type        = string
  description = "Existing VPC in which to deploy our instance."
}

variable public_subnet_name_regex {
  type        = string
  description = "Pattern to identify public subnets"
  default     = "*-public-*"
}

variable ami_name_filter {
  type        = string
  description = "AMI name filter."
  default     = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
}

variable ami_owner {
  type        = string
  description = "AMI owner."
  default     = "099720109477" # Canonical use "self" for your own images.
}

variable ami_id {
  type        = string
  description = "AMI ID (optional)."
  default     = ""
}

variable instance_count {
  type        = number
  description = "Number of instances to provision."
  default     = 1
}

variable instance_type {
  type        = string
  description = "Instance size."
  default     = "m5a.large"
}

variable kms_key_id {
  type        = string
  description = "KMS Key ID for encrypting root volume."
  default     = ""
}

variable root_volume_type {
  type        = string
  description = "Root volume type."
  default     = "gp2"
}

variable root_volume_encrypt {
  type        = bool
  description = "Encrypt root volume?"
  default     = false
}

variable root_volume_size {
  type        = number
  description = "Root volume size in GB."
  default     = 50
}

variable ssh_key_name {
  type        = string
  description = "Name of SSH key in AWS region."
}

# Security group
variable owner_cidr_blocks {
  type        = list(string)
  description = "CIDR blocks that will be allowed to access our instance."
  default     = []
}

# tags
variable owner {
  type        = string
  description = "Label to identify owner, will be used for tagging resources that are provisioned."
}

# Cloudflare DNS
variable provision_cloudflare_dns {
  type        = bool
  description = "Provision Cloudflare DNS record?"
  default     = false
}

variable domain {
  type        = string
  description = "Domain in which to provision an DNS A record."
  default     = ""
}

variable hostname {
  type        = string
  description = "DNS A records to provision."
  default     = "concourse"
}

# pki stuff
variable tls_private_key_algorithm {
  type        = string
  description = "TLS private key algorithm."
  default     = "RSA"
}

variable email_address {
  type        = string
  description = "Email address for ACME cert request."
}

variable dns_challenge_provider {
  type        = string
  description = "DNS challenge provider for ACME cert request."
}

variable acme_server_url {
  type        = string
  description = "ACME server."
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable san {
  type        = list(string)
  description = "Subject alternative names (SAN) for ACME cert request."
  default     = ["127.0.0.1"]
}

# Concourse
variable concourse_url {
  type        = string
  description = "Concourse download URL."
  default     = "https://github.com/concourse/concourse/releases/download/v6.2.0/concourse-6.2.0-linux-amd64.tgz"
}

variable src_dir {
  type        = string
  description = "Download directory."
  default     = "/data/src"
}

variable top_dir {
  type        = string
  description = "Install path."
  default     = "/usr/local"
}

variable concourse_config_dir {
  type        = string
  description = "Concourse config directory."
  default     = "/etc/concourse"
}

variable web_env_file {
  type        = string
  description = "Concourse web environment file."
  default     = "web.env"
}

variable worker_env_file {
  type        = string
  description = "Concourse worker environment file."
  default     = "worker.env"
}

variable concourse_user {
  type        = string
  description = "Concourse user."
  default     = "concourse"
}

variable concourse_tls_bind_port {
  type        = number
  description = "Concourse web TLS bind port."
  default     = 8443
}

variable concourse_garden_dns_server {
  type        = string
  description = "Concourse Garden DNS Server."
  default     = "1.1.1.1"
}
