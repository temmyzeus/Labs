resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ec2_ssh_key" {
  filename        = "${path.module}/ec2_ssh_key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "lab-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
  depends_on = [local_sensitive_file.ec2_ssh_key]
}
resource "aws_vpc" "lab" {
  instance_tenancy   = "default"
  enable_dns_support = true
  cidr_block         = "10.0.0.0/20"
  tags = {
    "Name" = "lab-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.0.0/22"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "Lab Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.4.0/22"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "Lab Private Subnet"
  }
}

resource "aws_internet_gateway" "lab" {
  tags = {
    "Name" = "Lab IGW"
  }
}

# Attaching the IGW to the VPC
resource "aws_internet_gateway_attachment" "attach_lab_igw_n_vpc" {
  vpc_id              = aws_vpc.lab.id
  internet_gateway_id = aws_internet_gateway.lab.id
}

resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.lab_instance_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name
  tags = {
    "Name" = "Lab Public EC2"
  }
}

resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.lab_instance_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name
  tags = {
    "Name" = "Lab Private EC2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  tags = {
    "Name" = "Lab Public Route Table"
  }
}

# Associating the public subnet with the public route table to stop implicit association with the main route table.
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

# Routing traffic from main route table to the IGW
resource "aws_route" "main_rt_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}
