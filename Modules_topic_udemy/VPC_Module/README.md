# This network module should:
#   1- create vpc module within cidir block
#   2- Allow the user to provide the configuration for multiaple subnet
#       2.1- the user should able to mark the subnet private or public
#           2.1.1- we need to if there is one public subnet we need to deploy IGTW
#           2.1.2- we need to associate the public subnet with public route table
#       2.2- the user should able to provide cidr block
#       2.3- the user should able to provide aws (az)
