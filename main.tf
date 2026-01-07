# Setup what cloud we're using
provider "aws" {
  region = var.AWS_REGION
  access_key = var.AWS_KEY
  secret_key = var.AWS_SECRET
}

# refer to existing resources

# data "type of resource" "local name of resource that already exists"
data "aws_vpc" "c21-vpc" {
    id = var.VPC_ID
}

# Describe resources

# # resource "type of resource" "local name of resource"
# resource "aws_s3_bucket" "example_bucket" {
#     bucket = "c21-kieran-example-bucket" # Name of bucket
#     force_destroy = true
# }

# Security Group
resource "aws_security_group" "sg-db" {
    name = "c21-kieran-sg-museum"
    vpc_id = data.aws_vpc.c21-vpc.id
}

# Inbound access rule
resource "aws_vpc_security_group_ingress_rule" "sg-db-inbound-postgres" {
    security_group_id = aws_security_group.sg-db.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 5432
    to_port = 5432
    ip_protocol = "tcp"
}

# Database
resource "aws_db_instance" "db-museum" {
    allocated_storage            = 10
    db_name                      = "postgres"
    identifier                   = "c21-kieran-db-museum"
    engine                       = "postgres"
    engine_version               = "17.6"
    instance_class               = "db.t3.micro"
    publicly_accessible          = true
    performance_insights_enabled = false
    skip_final_snapshot          = true
    db_subnet_group_name         = "c21-public-subnet-group"
    vpc_security_group_ids       = [aws_security_group.sg-db.id]
    username                     = var.DB_USERNAME
    password                     = var.DB_PASSWORD
}

resource "aws_security_group" "sg-ec2" {
    name = "c21-kieran-sg-ec2"
    vpc_id = data.aws_vpc.c21-vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ec2-inbound-postgres" {
    security_group_id = aws_security_group.sg-ec2.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_instance" "ec2" {
    ami="ami-099400d52583dd8c4"
    instance_type = "t2.nano"
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.sg-ec2.id]
    subnet_id = var.SUBNET_ID
    key_name = "c21-kieran-kp"
    tags = {
      Name = "c21-kieran-ec2-museum"
    }
}
