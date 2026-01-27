module "vpc" {
  source = "./Modules_topic_udemy/VPC_Module"
  vpc_config = {
    cidr = var.vpc_cidr
    name = "my-vpc"
  }
  subnet_config = {
    subnet1 = {
      cidr = var.subnet_cidr
      name = "my-subnet-1"  
      az = "us-east-1a"
      public = true
      }
      subnet2 = {
      cidr = "10.0.2.0/24"
      name = "my-subnet-2"  
      az = "us-east-1b"
      public = false
}
}
}