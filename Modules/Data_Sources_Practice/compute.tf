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
data "aws_caller_identity" "current" {
}



resource "aws_instance" "web_server" {
    ami           = data.aws_ami.amazon_linux_2.id
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