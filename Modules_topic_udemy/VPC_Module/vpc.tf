# this map get all public subnet from subnet object if the public is true then i use it to check if i need IGW or not
locals{
    public_subnets = {for key,config in var.subnet_config : key => config if config.public}
    private_subnets = {for key,config in var.subnet_config : key => config if !config.public}
}
# this i need to give the error if he assign zone out of confihured 
data "aws_availability_zones" "available" {
  state = "available"
}
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
# vpc resorce
resource "aws_vpc" "vpc"{
  cidr_block = var.vpc_config.cidr
    tags = {
        Name = var.vpc_config.name
    }
}
# subnet resource attach to the vpc created and has az and public or private 
resource "aws_subnet" "subnets"{
  for_each = var.subnet_config
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value.cidr
  availability_zone = lookup(each.value, "az", null)
    tags = {
        Name = each.value.name
        Access = each.value.public ? "public" : "private"
    }
    lifecycle {
      precondition {
        condition = contains(data.aws_availability_zones.available.names, lookup(each.value, "az", null)) || lookup(each.value, "az", null) == null
        error_message = <<-EOT
        SubnetKey: ${each.key} has invalid availability zone: ${lookup(each.value, "az", "not specified")}
        AWS Region: ${var.aws_region}
        Please choose from the available zones: ${join(", ", data.aws_availability_zones.available.names)}
        EOT
      }
    }
}
#Internet Gateway and Route Table for public subnets
resource "aws_internet_gateway" "igw"{
    count = length(local.public_subnets) > 0 ? 1 : 0
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.vpc_config.name}-igw"
        }

}
#route table for public subnets
resource "aws_route_table" "public_rt"{
    count = length(local.public_subnets) > 0 ? 1 : 0
    vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
    tags = {
        Name = "${var.vpc_config.name}-public-rt"
        }
}
#route table association for public subnets
resource "aws_route_table_association" "rt_associate"{
  count          = length(local.public_subnets) > 0 ? length(local.public_subnets) : 0
  subnet_id      = aws_subnet.subnets[keys(local.public_subnets)[count.index]].id
  route_table_id = aws_route_table.public_rt[0].id
}
#create security group for the ec2 instance
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["20.171.127.73/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# launch an ec2 instance that use the created vpc and private subnet only
resource "aws_instance" "web_server" {
    ami           = data.aws_ami.amazon_linux_2.id
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.subnets[keys(var.subnet_config)[0]].id
    associate_public_ip_address = false
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
