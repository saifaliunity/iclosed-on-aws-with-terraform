# resource "aws_s3_bucket" "env-s3" {
#   bucket = "iclosed-envs"

#   tags = {
#     Name        = "iclosed-envs"
#     Environment = "${var.env}"
#   }
# }

resource "aws_s3_bucket" "fe-s3" {
  bucket = var.fe_domain_name

  tags = {
    Name        = "${var.fe_domain_name}"
    Environment = "${var.env}"
  }
}