############################
### Global Configuration ###

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "codehub_prod_cluster" {
  name = "codehub-prod-cluster"
}

locals {
  prod_private_subnets    = ["subnet-0eb0727ca38b96d02", "subnet-005743ce787e8baee", "subnet-0c568259d248437e5", "subnet-0c88df334bec87921", "subnet-05849499a2a28b0df", "subnet-05106e617d70bbe7b"]
  prod_vpc_id             = "vpc-0384dfcb3a1d6b9e6"
  prod_task_role_arn      = "arn:aws:iam::797335914619:role/BAHServiceRoleForECS"
  prod_execution_role_arn = "arn:aws:iam::797335914619:role/BAHServiceRoleForECSTaskExecution"
}
