resource "aws_db_subnet_group" "iclosed_db_subnets" {
  name       = "iclosed_db_subnets"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "iclosed DB subnet group"
  }
}

resource "aws_rds_cluster" "iclosed_db_cluster" {
  cluster_identifier = "iclosed-aurora-cluster"
  engine             = var.db_engine
  engine_version     = var.db_engine_version
  engine_mode        = var.db_engine_mode
  port               = var.db_port
  database_name      = var.db_name
  master_username    = var.db_username
  master_password    = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.iclosed_db_subnets.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = false
  serverlessv2_scaling_configuration {
    min_capacity = var.db_min_capacity
    max_capacity = var.db_max_capacity
  }

}

resource "aws_rds_cluster_instance" "iclosed_cluster_instances" {
  count                = 2
  identifier           = "iclosed-db-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.iclosed_db_cluster.id
  instance_class       = var.db_instance_type
  engine               = aws_rds_cluster.iclosed_db_cluster.engine
  engine_version       = aws_rds_cluster.iclosed_db_cluster.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_rds_cluster.iclosed_db_cluster.db_subnet_group_name
}