variable "public_ssh_key_path" {
  description = "Path to public ssh key"
  type        = string
}

variable "key_pair_name" {
  description = "Name of key pair resource"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use"
  type        = string
}

variable "launch_config_name" {
  description = "Launch config name"
  type        = string
}

variable "asg_name" {
  description = "Name of auto scaling group"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type = string
  default = "us-east-2"
}