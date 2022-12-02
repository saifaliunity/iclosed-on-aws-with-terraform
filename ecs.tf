resource "aws_ecs_cluster" "iclosed-cluster" {
  name = "iclosed-cluster" # Naming the cluster
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  depends_on = [
    aws_vpc.iclosed_vpc
  ]
}

resource "aws_ecs_cluster_capacity_providers" "cluster-cp" {

  cluster_name       = aws_ecs_cluster.iclosed-cluster.name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
  depends_on = [
    aws_ecs_cluster.iclosed-cluster
  ]
}