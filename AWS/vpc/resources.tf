resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ec2_ssh_key" {
  filename        = "${path.module}/ec2_ssh_key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"
}
