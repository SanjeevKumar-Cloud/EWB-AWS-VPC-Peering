variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "my_ip" {
  description = "Your workstation public IPv4 CIDR (e.g. 103.xxx.xxx.xxx/32) for Bastion SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "ewb-lab"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "student_name" {
  description = "Student name for resource tagging"
  type        = string
  default     = "Sanjeev Kumar"
}
