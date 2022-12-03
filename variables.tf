######################
## Global Variables #######
#####################

variable "env" {
  type        = string
  description = "current enviroment pod, dev etc.."
}

variable "region" {
  type        = string
  description = "AWS Region to use"
  default     = "us-east-1"
}

#####################
## RDS Variables #######
#####################

variable "db_instance_type" {
  type        = string
  description = "The DB instance class type db.t2.micro, db.m5.larage, etc.."
}

variable "db_engine" {
  type        = string
  description = "The type of engine to run on the DB instance aurora, mysql, postgresql, etc.."
}

variable "db_engine_version" {
  type        = string
  description = "The version of the engine running on the DB instance"
}

variable "db_engine_mode" {
  type        = string
  description = "The mode of the engine running on the DB instance"
}


variable "db_port" {
  type        = number
  description = "The port that the DB engine listening on"
}

variable "db_min_capacity" {
  type        = string
  description = "The min capacity of the  DB instance"
}

variable "db_max_capacity" {
  type        = string
  description = "The max capacity of the  DB instance"
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

############################
## Elastic Cache Variables #######
############################
variable "ec_node_type" {
  type        = string
  description = "The instance type for each node in the cluster"
}

variable "ec_nodes_count" {
  type        = number
  description = "Number of nodes in the cluster if az_mode is cross-az this must be more than 1"
}

variable "ec_az_mode" {
  type        = string
  description = "Specifies whether the nodes is going to be created across azs or in a single az"

  validation {
    condition     = var.ec_az_mode == "cross-az" || var.ec_az_mode == "single-az"
    error_message = "The az_mode value can only be 'cross-az' or 'single-az'."
  }
}

variable "ec_redis_port" {
  type        = number
  description = "The Memcache port that the nodes will be listing on"
}

############################
## Elastic Container Service Variables #######
############################

variable "task_cpu" {
  description = "(Required) Task CPU to the iclosed task"
}

variable "task_memory" {
  description = "(Required) Task Memory to the iclosed task"
}

variable "application_tag" {
  description = "(Required) tag to application"
}

variable "healthcheck_path" {
  description = "(Required) Healthcheck path for iclosed."
}

############################
## Route53 Variables #######
############################

variable "bk_domain_name" {
  description = "(Required) Domain name to use in load balancer configuration for listener rule."
}

variable "fe_domain_name" {
}

variable "hosted_zone_domain" {

}

############################
## Cloudfront Variables #######
############################

variable "virginia" {

}

variable "cache_policy_name" {
  default = "Managed-CachingOptimized"
}

variable "origin_request_policy_name" {
  default = "Managed-CORS-S3Origin"
}