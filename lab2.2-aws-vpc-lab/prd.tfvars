# VALUES for the variables declared in variables.tf.
# Terraform loads this file automatically.

region            = "eu-west-1"
availability_zone = "eu-west-1a"
project_name      = "lab"

vpc_cidr            = "20.0.0.0/16"
public_subnet_cidr  = "20.0.1.0/24"
private_subnet_cidr = "20.0.2.0/24"

instance_type = "t3.micro"
volume_size   = 1
