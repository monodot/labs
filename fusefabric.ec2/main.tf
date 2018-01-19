# Based on the great examples in the `terraform-provider-aws` module:
# https://github.com/terraform-providers/terraform-provider-aws/blob/master/examples/two-tier/main.tf
#
# EC2 instance sizing/pricing quick reference:
# t2.medium = 2 vCPU, 4 GiB RAM, EBS Only, $0.05/hour
# t2.large = 2 vCPU, 8 GiB RAM, EBS Only, $0.1008/hour

variable "resource_tag_name" { default = "labs-fusefabric" }
variable "aws_ami" { default = "ami-bb9a6bc2" }
variable "key_name" { default = "mykeyname" }
variable "key_path" { default = "~/.ssh/mykeyname.pem" }
variable "fabric_server_count" { default = "3" }
variable "fabric_server_instance_type" { default = "t2.medium" }
variable "managed_container_count" { default = "2" }
variable "managed_container_instance_type" { default = "t2.medium"} 
variable "security_group" { default = "labs-fusefabric" }
variable "ebs_root_block_size" { default = "50" }
variable "aws_availability_zone" { default = "eu-west-1" }
variable "aws_region" { default = "eu-west-1" }
variable "aws_credentials_file" {} 
variable "aws_profile" {}
variable "aws_s3_bucket_name" { default = "mybucket" }
variable "aws_s3_folder_name" { default = "files" }


provider "aws" {
  shared_credentials_file = "${var.aws_credentials_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

# A VPC to unite them all
# This will also create a default security group for this VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "${var.resource_tag_name}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.resource_tag_name}"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.resource_tag_name}"
  }
}

# Security Group for all servers in the Fuse deployment
resource "aws_security_group" "default" {
  name        = "${var.security_group}"  # labs-fusefabric
  description = "Fuse Fabric Security Group"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.resource_tag_name}"
  }
}

#resource "aws_key_pair" "auth" {
#  key_name   = "${var.key_name}"
#  public_key = "${file(var.key_path)}"
#}

# An AWS IAM role and role_policy that Allows fetching stuff from S3 buckets
# From: https://optimalbi.com/blog/2016/07/12/aws-tips-and-tricks-moving-files-from-s3-to-ec2-instance/
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  name               = "${var.resource_tag_name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

resource "aws_iam_role_policy" "default" {
  name   = "${var.resource_tag_name}"
  role   = "${aws_iam_role.default.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:ListBucket",
      "Resource": [
        "arn:aws:s3:::${var.aws_s3_bucket_name}"
      ],
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::${var.aws_s3_bucket_name}/${var.aws_s3_folder_name}"
      ],
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# Map an IAM Instance Profile to the role we just created
resource "aws_iam_instance_profile" "default" {
  name = "${var.resource_tag_name}"
  role = "${aws_iam_role.default.name}"
}

# Create instances for Fabric Servers (Ensemble/Zookeeper nodes)
resource "aws_instance" "fabric_server" {
  connection {
    # The default username for our AMI
    user        = "ec2-user"
    private_key = "${file(var.key_path)}"
  }

  count                  = "${var.fabric_server_count}"
  
  # TODO update this with a lookup for the correct AMI - ami = "${lookup(var.aws_amis, var.aws_region)}"
  ami                    = "${var.aws_ami}"

  instance_type          = "${var.fabric_server_instance_type}"
  # availability_zone = "${var.aws_availability_zone}"
  key_name               = "${var.key_name}"
  
  # Configure the fascinating storage
  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.ebs_root_block_size}"
  }
  
  # Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  
  # Launch the instances into the Subnet we created
  subnet_id              = "${aws_subnet.default.id}"
  
  # Add the instance profile to allow it to pull files from S3
  iam_instance_profile   = "${aws_iam_instance_profile.default.name}"
  
  # Wait for instance profile to appear due to https://github.com/terraform-providers/terraform-provider-aws/issues/838
  provisioner "local-exec" {
    command = "sleep 40" 
  }

  # Run a remote provisioner on the instance to install OpenJDK
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y java-1.8.0-openjdk-devel",
      "curl -O https://bootstrap.pypa.io/get-pip.py",
      "sudo python get-pip.py",
      "pip install awscli --upgrade --user"
    ]
  }

  tags {
    Name = "fabricserver${count.index}"
    sshUser = "ec2-user"
    role = "fabricservers"
  }
}

# Create instances for Managed Containers (Karaf nodes)
/*
resource "aws_instance" "managed-container" {
  count = "${var.managed_container_count}"
  ami = "${var.aws_ami}"
  instance_type = "${var.managed_container_instance_type}"
  security_groups = [ "${var.security_group}" ]
  # availability_zone = "${var.aws_availability_zone}"
  key_name = "${var.key_name}"
  
  tags {
    Name = "managedcontainer${count.index}"
    sshUser = "ec2-user"
    role = "managedcontainers"
  }
  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.ebs_root_block_size}"
  }
}
*/



# ---------------------------------------------------

output "fabric_server_instance_ips" {
  value = ["${aws_instance.fabric_server.*.public_ip}"]
}

#output "managed_container_instance_ips" {
#  value = ["${aws_instance.managed_container.*.public_ip}"]
#}
