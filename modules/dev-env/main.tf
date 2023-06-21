# Define a local variable for the cluster name
locals {
  cluster_name = "${var.user}-dev-kind-cluster"
}

provider "aws" {
  region = var.aws_region # Choose the appropriate AWS region
}

# Create a VPC
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.user}-dev-vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id
}

# Create a public subnet in the VPC
resource "aws_subnet" "dev_public_subnet" {

  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}${var.aws_availability_zone_letter}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.user}-dev-public-subnet"
  }
}

# Create a route table associated with the public subnet
resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "${var.user}-dev-public-route-table"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "dev_public_rt_assoc" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_public_rt.id
}

# Create a key pair for SSH access
resource "aws_key_pair" "my_key_pair" {
  key_name   = "${var.user}-dev-key-pair"
  public_key = file("${var.public_ssh_key_path}")
}

# Create a security group to allow all access
resource "aws_security_group" "allow_all" {
  name_prefix        = "allow_all"
  description = "Allow all incoming traffic"
  vpc_id = aws_vpc.dev_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Launch Configuration to define the instance settings
resource "aws_launch_configuration" "dev_server_launch_config" {
  name_prefix          = "${var.user}-dev-launch-config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.my_key_pair.key_name
  security_groups = [aws_security_group.allow_all.id]

  root_block_device {
    volume_size = 400
  }

  # Reference the user_data.sh file for user data
  user_data = filebase64("${path.module}/user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Create an Auto Scaling group using the Launch Configuration
resource "aws_autoscaling_group" "dev_server_asg" {
  name                 = "${var.user}-dev-asg"
  max_size             = 1
  min_size             = 0
  desired_capacity     = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  launch_configuration = aws_launch_configuration.dev_server_launch_config.id

  # Specify the vpc zones for the Auto Scaling group
  vpc_zone_identifier = [aws_subnet.dev_public_subnet.id]

  tag {
    key                 = "Name"
    value               = "${var.user}-dev"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a scheduled action to scale down the Auto Scaling group at midnight
resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "scale-down"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  autoscaling_group_name = aws_autoscaling_group.dev_server_asg.name

  # Set this to your desired time zone
  time_zone = "UTC"

  # "0 0 * * *" is a cron expression for "Every day at 6 UCT"
  recurrence = "0 6 * * *"
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.dev_server_asg.name
}

# ---------------------------------------------------------------------------------------------------------------------
# LOOK UP THE LATEST UBUNTU AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Data source to fetch information about instances in the Auto Scaling group
data "aws_instances" "dev_server_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.dev_server_asg.name]
  }
}

output "dev_server_public_ips" {
  description = "List of public IP addresses of instances in the dev-server Auto Scaling group"
  value       = data.aws_instances.dev_server_instances.public_ips
}