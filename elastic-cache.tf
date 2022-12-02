resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "iclosed-cluster"
  replication_group_id = aws_elasticache_replication_group.redis_cluster_rg.id
}

resource "aws_elasticache_replication_group" "redis_cluster_rg" {
  replication_group_id       = "iclosed-cluster-rg"
  description                = "iclosed-redis-cluster"
  node_type                  = var.ec_node_type
  port                       = var.ec_redis_port
  parameter_group_name       = "default.redis3.2.cluster.on"
  automatic_failover_enabled = true

  num_node_groups         = var.ec_nodes_count
  replicas_per_node_group = 1
}

output "redis_endpoint" {
  value = "${aws_elasticache_replication_group.redis_cluster_rg.*.primary_endpoint_address}"
}