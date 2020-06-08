################################################################################
# outputs

output a_concourse_instance_ip {
  value                       = aws_instance.instance.*.public_ip
}

output b_concourse_hostname {
  value                       = local.common_name
}

output c_ssh_connection {
  value                       = "ssh ubuntu@${local.common_name}"
}

output d_concourse_url {
  value                       = "https://${local.common_name}:${local.concourse_tls_bind_port}"
}

output e_concourse_username {
  value                       = random_string.concourse_username.result
}

output f_concourse_password {
  value                       = random_password.concourse_password.result
}
