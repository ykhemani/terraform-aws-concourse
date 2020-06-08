################################################################################
provider aws {
  region                    = var.region
}

################################################################################
# vpc
data aws_vpc vpc {
  id                          = var.vpc_id
}

# public subnet ids
data aws_subnet_ids subnet_ids {
  vpc_id                      = var.vpc_id

  filter {
    name                      = "tag:Name"
    values                    = [var.public_subnet_name_regex]
  }

  filter {
    name                      = "tag:owner"
    values                    = [var.owner]
  }

}

################################################################################
# ubuntu 18.0.4 image
data aws_ami ubuntu {
  most_recent                 = true

  filter {
    name                      = "name"
    values                    = [var.ami_name_filter]
  }

  filter {
    name                      = "virtualization-type"
    values                    = ["hvm"]
  }

  // filter {
  //   name                      = "tag:Owner"
  //   values                    = [var.owner]
  // }

  owners                      = [var.ami_owner]
}

################################################################################
# concourse credentials
resource random_string concourse_username {
  length                      = 16
  special                     = false
}

resource random_integer concourse_password_length {
  min                         = 60
  max                         = 72
}

resource random_password concourse_password {
  length                      = random_integer.concourse_password_length.result
  special                     = false
}

resource random_integer postgres_password_length {
  min                         = 32
  max                         = 64
}

resource random_password postgres_password {
  length                      = random_integer.postgres_password_length.result
  special                     = false
}

################################################################################
# locals
locals {
  common_name                   = "${var.hostname}.${var.domain}"
  concourse_tls_bind_port       = 8443
  # use ami_id variable if it isn't empty, otherwise use Canonical Ubuntu ami.
  ami_id                        = var.ami_id == "" ? data.aws_ami.ubuntu.id : var.ami_id
}

################################################################################
# let's define our user data
data template_file user_data {
  template                      = file("userdata.tpl")
  vars                          = {
    aws_region                  = var.region

    tls_fullchain               = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
    tls_private_key             = acme_certificate.certificate.private_key_pem

    src_dir                     = "/data/src"
    concourse_config_dir        = "/etc/concourse"
    bin_dir                     = "/usr/local/bin"
    caddy_config_dir            = "/etc/caddy"

    web_env_file                = "web.env"
    worker_env_file             = "worker.env"

    concourse_user              = "concourse"

    common_name                 = local.common_name
    concourse_username          = random_string.concourse_username.result
    concourse_password          = random_password.concourse_password.result

    concourse_tls_bind_port     = local.concourse_tls_bind_port

    postgres_password           = random_password.postgres_password.result
  }
}

################################################################################
# aws instance
resource aws_instance instance {
  count                       = var.instance_count
  subnet_id                   = element(tolist(data.aws_subnet_ids.subnet_ids.ids), count.index)
  ami                         = local.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sg_ingress.id, aws_security_group.sg_egress.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  root_block_device {
    volume_type               = var.root_volume_type
    encrypted                 = var.root_volume_encrypt
    volume_size               = var.root_volume_size
    kms_key_id                = var.kms_key_id
  }

  user_data                   = data.template_file.user_data.rendered

  tags = {
    Owner                     = var.owner
    Name                      = var.hostname
    Image_Name                = local.ami_id
  }
}
