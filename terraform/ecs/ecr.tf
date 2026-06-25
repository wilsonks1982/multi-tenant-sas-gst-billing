resource "aws_ecr_repository" "app_repo" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "ecr_bootstrap" {
  depends_on = [aws_ecr_repository.app_repo]

  provisioner "local-exec" {
    command = <<-EOF
      aws ecr get-login-password --region ${var.aws_region} --profile ${var.aws_profile} | docker login --username AWS --password-stdin ${aws_ecr_repository.app_repo.repository_url}

      docker build -t ${var.app_name}:latest .

      docker tag ${var.app_name}:latest ${aws_ecr_repository.app_repo.repository_url}:latest

      docker push ${aws_ecr_repository.app_repo.repository_url}:latest
    EOF
  }
}
