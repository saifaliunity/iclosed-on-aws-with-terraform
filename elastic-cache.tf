resource "aws_elasticache_subnet_group" "redis-sng" {
  name       = "redis-sng"
  subnet_ids = aws_subnet.private_subnets.*.id
}

resource "aws_security_group" "iclosed-backend-redis_security_group" {
  vpc_id = aws_vpc.iclosed_vpc.id
  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    # Only allowing traffic in from the user-service security group
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.iclosed-backend-service_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "iclosed-backend-redis_cw_log_group" {
  name = "iclosed-backend-redis-engine-logs"
  tags = {
    Environment = "${var.env}"
    Application = "iclosed-backend-redis"
  }
}

resource "aws_elasticache_replication_group" "redis_cluster_rg" {
  replication_group_id       = "iclosed-cluster-rg"
  description                = "iclosed-redis-cluster"
  node_type                  = var.ec_node_type
  port                       = var.ec_redis_port
  multi_az_enabled           = true
  apply_immediately          = true
  automatic_failover_enabled = true
  security_group_ids         = [aws_security_group.iclosed-backend-redis_security_group.id]
  subnet_group_name          = aws_elasticache_subnet_group.redis-sng.name
  num_node_groups            = var.ec_nodes_count
  replicas_per_node_group    = 1
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.iclosed-backend-redis_cw_log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis_cluster_rg.primary_endpoint_address
}