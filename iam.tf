resource "aws_iam_role" "ecsTaskExecutionRole" {
  name_prefix        = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs-autoscale-role" {
  name_prefix = "ecs-scale-application"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
  role       = aws_iam_role.ecs-autoscale-role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}


# [Data] IAM policy to define S3 permissions

data "aws_iam_policy_document" "s3_data_bucket_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.env-s3.arn}"
    ]
  }
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${data.aws_s3_bucket.selected.arn}/${var.env}/backend/*",
    ]
  }
}

# AWS IAM policy

resource "aws_iam_policy" "s3_policy" {
  name_prefix = "ecs-s3-policy-${var.env}"
  policy      = data.aws_iam_policy_document.s3_data_bucket_policy.json
}

# Attaches a managed IAM policy to an IAM role

resource "aws_iam_role_policy_attachment" "ecs_role_s3_data_bucket_policy_attach" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.s3_policy.arn
}