resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  user_data = <<-EOF
            #!/bin/bash
            set -e
            echo "Starting user data script" > /var/log/user-data.log

            # Update packages
            apt-get update -y >> /var/log/user-data.log 2>&1

            # Install Docker
            echo "Installing Docker" >> /var/log/user-data.log
            apt-get install -y docker.io unzip curl amazon-ssm-agent >> /var/log/user-data.log 2>&1
            systemctl enable docker >> /var/log/user-data.log 2>&1
            systemctl start docker >> /var/log/user-data.log 2>&1
            usermod -a -G docker ubuntu >> /var/log/user-data.log 2>&1

            # Enable & start SSM Agent
            echo "Starting SSM Agent" >> /var/log/user-data.log
            systemctl enable amazon-ssm-agent >> /var/log/user-data.log 2>&1
            systemctl start amazon-ssm-agent >> /var/log/user-data.log 2>&1

            # Install AWS CLI v2
            echo "Installing AWS CLI v2" >> /var/log/user-data.log
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install

            # Authenticate to ECR
            echo "Logging into ECR" >> /var/log/user-data.log
            aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repository_url} >> /var/log/user-data.log 2>&1

            # Run Node.js App container
            echo "Running Docker container" >> /var/log/user-data.log
            docker run -d -p 3000:3000 \
              -e DB_USER=appadmin2 \
              -e DB_PASSWORD=securepassword123 \
              -e DB_HOST=${var.rds_endpoint} \
              ${var.ecr_repository_url}:latest >> /var/log/user-data.log 2>&1

            echo "User data script completed" >> /var/log/user-data.log
            EOF

  tags = {
    Name = "${var.env}-app-server"
  }
}

# IAM Role
resource "aws_iam_role" "app_role" {
  name = "${var.env}-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy with ECR, CloudWatch + SSM
resource "aws_iam_role_policy" "app_policy" {
  name   = "${var.env}-app-policy"
  role   = aws_iam_role.app_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:DescribeInstanceInformation",
          "ssmmessages:*",
          "ec2messages:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "app" {
  name = "${var.env}-app-profile"
  role = aws_iam_role.app_role.name
}
