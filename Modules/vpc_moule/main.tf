//vpc creation
resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "vpc"
        managed_by = "terraform"
    }
}
//this public subnet
resource "aws_subnet" "subnet" {
    vpc_id            = aws_vpc.this.id
    cidr_block        = var.subnet_cidr
    availability_zone = "${var.aws_region}a"
    tags = {
        Name = "subnet"
        managed_by = "terraform"
        } 
}
// aws internet gate way
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.this.id
    tags = {
        Name = "internet_gateway"
        managed_by = "terraform"
    }
}
//route table for public subnet
resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {
        Name = "public_route_table"
        managed_by = "terraform"
    }

}
resource "aws_route_table_association" "public_subnet_association" {
    subnet_id      = aws_subnet.subnet.id
    route_table_id = aws_route_table.public_subnet.id
}
