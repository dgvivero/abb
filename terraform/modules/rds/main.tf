#NETWOERKIG
module "networking"  {
  source = "../networking"
}

#RDS postgres

resource "aws_security_group" "sg_visitor_db" {
  name = "sg_visitor_rds"
  description = "Ingress and egress for visitors RDS"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "db ingress from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = module.networking.private_subnet_cidrs
  }

  egress {
    description = "db egress from private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "subnet_group_visitor_db" {
  name       = "visitors_db-subnet-group"
  subnet_ids = module.networking.subnets_private
}

resource "aws_db_instance" "visitors_db" {
    allocated_storage    = 20
    engine               = "postgres"
    engine_version       = "14"
    identifier           = "visitors-postgres-db"
    instance_class       = "db.t2.micro"
    password             = "postgres"
    skip_final_snapshot  = true
    db_subnet_group_name   = aws_db_subnet_group.subnet_group_visitor_db.name
    vpc_security_group_ids = [aws_security_group.sg_visitor_db.id]
    storage_encrypted    = false
    publicly_accessible    = false
    username             = "postgres"
    apply_immediately = true
  }