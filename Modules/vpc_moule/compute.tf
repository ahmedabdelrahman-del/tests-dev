// Data source to find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
    ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI ID for us-east-1
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.subnet.id
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    root_block_device {
      delete_on_termination = true
      volume_size = 10
      volume_type = "gp3"
    }
    lifecycle {
      create_before_destroy = true
    }

    tags = {
        Name = "web_server"
        managed_by = "terraform"
    }
}
resource "aws_security_group" "web_sg" {
    name        = "web_sg"
    description = "Allow HTTP and HTTPS traffic from port 80 and 443"
    vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "http_rule" {
    security_group_id = aws_security_group.web_sg.id
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https_rule" {
    security_group_id = aws_security_group.web_sg.id
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 443
    to_port           = 443
    cidr_blocks       = ["0.0.0.0/0"]
}