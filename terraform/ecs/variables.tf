variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

# AWS CLI Profile Name (e.g., "default", "wilson-admin", etc.)
variable "aws_profile" {
  type    = string
  default = "wilson-admin"
}

variable "app_name" {
  type    = string
  default = "gst-billing-mvp"
}

variable "container_port" {
  type    = number
  default = 9100
}
