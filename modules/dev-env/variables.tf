variable "public_ssh_key_path" {
  description = "Path to public ssh key"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type = string
  default = "us-east-2"
}

variable "aws_availability_zone_letter" {
  description = "AWS availability zone letter to use"
  type = string
  default = "b"
}

variable "user" {
  description = "User using this terraform"
  type = string
  default = "doug"
}