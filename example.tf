provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "simple_vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "Simple VPC"
  }
}

resource "aws_internet_gateway" "simple_ig" {
  vpc_id = "${aws_vpc.simple_vpc.id}"

  tags {
    Name = "Simple Internet Gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.simple_vpc.id}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name = "Simple Public Subnet"
  }
}

resource "aws_route" "r" {
  route_table_id         = "rtb-a3bfb6df"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.simple_ig.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.simple_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

resource "aws_launch_configuration" "simple_lc" {
  name_prefix                 = "simple_lc_"
  image_id                    = "ami-2757f631"                         # LAMP AMI"ami-15996268"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.allow_all.id}"]
  key_name                    = "terraform"

  user_data = <<EOF
#cloud-config
repo_update: true
repo_upgrade: all

packages:
 - apache2
 - curl

runcmd:
 - curl "https://omnitruck.chef.io/install.sh" | sudo bash -s -- -P chefdk -c stable -v 2.5.3
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "simple_asg" {
  name_prefix               = "simple_asg_"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  vpc_zone_identifier       = ["${aws_subnet.public_subnet.id}"]
  launch_configuration      = "${aws_launch_configuration.simple_lc.name}"
  termination_policies      = ["OldestInstance"]
}

resource "aws_autoscaling_policy" "avg_cpu_target_tracking_scaling" {
  name                   = "simple_asg_avg_cpu_target_tracking_scaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.simple_asg.name}"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 40.0
  }
}
