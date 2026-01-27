#1- vpc id
#2- public subnet key=>- id 
#3- private subnet key=>- id
locals{
    public_subnet_outputs = {for key in keys(local.public_subnets): key =>{ id = aws_subnet.subnets[key].id
    availability_zone =  aws_subnet.subnets[key].availability_zone
    }
    }
    private_subnet_outputs = {for key in keys(local.private_subnets): key =>{ id = aws_subnet.subnets[key].id
    availability_zone =  aws_subnet.subnets[key].availability_zone
    }
    }
}
output "vpc_id"{
    description = "vpc_id"
    value = aws_vpc.vpc.id
}
output "public_subnet"{
    description = "public subnet ids"
    value = local.public_subnet_outputs
}
output "private_subnet"{
    description = "private subnet ids"
    value = local.private_subnet_outputs
}