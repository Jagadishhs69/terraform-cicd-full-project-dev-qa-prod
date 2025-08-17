variable "app_role_name" {
  description = "IAM role name of the EC2 instance"
  type        = string
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = var.app_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
