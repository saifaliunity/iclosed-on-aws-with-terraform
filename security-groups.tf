resource "aws_security_group" "lb_sg" {
  name        = "lb_sg-${var.env}"
  description = "Load Balancer sg"
  vpc_id      = aws_vpc.iclosed_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aurora_sg" {
  name        = "rds_aurora_sg-${var.env}"
  description = "Open MySQL port 3306 for EC2 instances"
  vpc_id      = aws_vpc.iclosed_vpc.id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.iclosed-backend-service_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "redis_sg-${var.env}"
  description = "Opening redis port for iclosed autoscaling group security group"
  vpc_id      = aws_vpc.iclosed_vpc.id

  ingress {
    from_port       = var.ec_redis_port
    to_port         = var.ec_redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.iclosed-backend-service_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
