# 1. SSH-നും ആപ്ലിക്കേഷനുമുള്ള സെക്യൂരിറ്റി ഗ്രൂപ്പ് നിർമ്മിക്കുന്നു
resource "aws_security_group" "testing_sg" {
  name        = "gst-billing-testing-sg"
  description = "Security group for GST Billing Testing Server"

  # GitHub Actions-ൽ നിന്നും നിങ്ങൾക്ക് SSH ചെയ്യാനുള്ള പോർട്ട്
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # സുരക്ഷയ്ക്കായി ഇവിടെ നിങ്ങളുടെ ഓഫീസിലെ/GitHub-ലെ IP നൽകുന്നത് നന്നായിരിക്കും
  }

  # ആപ്ലിക്കേഷൻ ആക്സസ് ചെയ്യാനുള്ള പോർട്ട്
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # പുറത്തേക്കുള്ള എല്ലാ കണക്ഷനുകളും അനുവദിക്കുന്നു (Outbound Traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gst-billing-sg"
  }
}

# 2. EC2 സെർവറിന് AWS ECR ആക്സസ് ചെയ്യാനുള്ള IAM Role നിർമ്മിക്കുന്നു
resource "aws_iam_role" "ec2_ecr_role" {
  name = "gst-billing-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role-ലേക്ക് ECR Read-Only പോളിസി അറ്റാച്ച് ചെയ്യുന്നു
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 ഇൻസ്റ്റൻസിൽ ഈ റോൾ ഉപയോഗിക്കാൻ Instance Profile നിർമ്മിക്കുന്നു
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "gst-billing-ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# 3. AWS EC2 ഇൻസ്റ്റൻസ് നിർമ്മിക്കുന്നു
resource "aws_instance" "testing_server" {
  ami                  = "ami-03f4fa076d2981b45" # Ubuntu 22.04 LTS AMI (ap-south-1 മുംബൈ റീജിയന് അനുയോജ്യമായത്)
  instance_type        = "t3.medium"              # ടെസ്റ്റിംഗിനും ഡോക്കർ റൺ ചെയ്യാനും അനുയോജ്യമായ സൈസ്
  key_name             = "dev-ssh-key"            # നിങ്ങൾ AWS-ൽ നേരത്തെ നിർമ്മിച്ച SSH Key-യുടെ പേര് ഇവിടെ നൽകുക
  security_groups      = [aws_security_group.testing_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # സെർവറിൽ ഓട്ടോമാറ്റിക് ആയി Docker, Docker Compose എന്നിവ ഇൻസ്റ്റാൾ ചെയ്യാനുള്ള യൂസർ ഡാറ്റ
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu

              # Docker Compose v2 ഇൻസ്റ്റാൾ ചെയ്യുന്നു
              mkdir -p /usr/local/lib/docker/cli-plugins/
              sudo curl -SL https://github.com -o /usr/local/lib/docker/cli-plugins/docker-compose
              sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

              # ആപ്പ് ഡയറക്ടറി നിർമ്മിക്കുന്നു
              mkdir -p /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app
              EOF

  tags = {
    Name = "gst-billing-testing-server"
    Env  = "Testing"
  }
}

# 4. സെർവർ റെഡിയാകുമ്പോൾ പബ്ലിക് IP അഡ്രസ് ഔട്ട്പുട്ട് ആയി കാണിക്കുന്നു
output "testing_server_public_ip" {
  value       = aws_instance.testing_server.public_ip
  description = "The public IP address of the testing server"
}
