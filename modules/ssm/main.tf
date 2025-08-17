resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = var.app_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
