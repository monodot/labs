variable "name"                   {}
variable "app_node_count"         {}

variable "aws_credentials_file"   {} 
variable "aws_profile"            {}
variable "aws_region"             {}

variable "vpc_id"                 {}
variable "vpc_cidr"               {}
variable "azs"                    {}
variable "public_subnets"         {}

variable "bastion_instance_type"  {}
variable "key_name"               {}


/*
variable "aws_credentials_file"   {} 
variable "aws_profile"            {}
variable "aws_region"             { default = "us-west-1" }
variable "key_name"               {}
variable "key_path"               {}
variable "aws_s3_bucket_name"     { default = "mybucket" }
variable "aws_s3_binaries_path"   { default = "files" }
variable "vpc_id"                 {}
variable "vpc_cidr"               {}

variable "aws_ami_rhel75"         { default = "ami-6871a115"}
variable "app_node_count"         { default = "1" }
variable "app_node_instance_type" { default = "t2.medium" }
variable "resource_tag_name"      { default = "rhelfarm" }
variable "bastion_name"           { default = "bastion" }
*/

provider "aws" {
  shared_credentials_file = "${var.aws_credentials_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

module "vpc" {
  source = "../terraform-modules/vpc"

  name = "${var.name}-vpc"
  cidr = "${var.vpc_cidr}"
}

module "public_subnet" {
  source = "../terraform-modules/public_subnet"

  name   = "${var.name}-public"
  vpc_id = "${module.vpc.vpc_id}"
  cidrs  = "${var.public_subnets}"
  azs    = "${var.azs}"
}

module "bastion_host" {
  source = "../terraform-modules/bastion_host"

  name              = "${var.name}-bastion"
  vpc_id            = "${module.vpc.vpc_id}"
  vpc_cidr          = "${module.vpc.vpc_cidr}"
  region            = "${var.aws_region}"
  public_subnet_ids = "${module.public_subnet.subnet_ids}"
  key_name          = "${var.key_name}"
  instance_type     = "${var.bastion_instance_type}"
}


# VPC
output "vpc_id"   { value = "${module.vpc.vpc_id}" }
output "vpc_cidr" { value = "${module.vpc.vpc_cidr}" }

# Bastion
output "bastion_user"       { value = "${module.bastion_host.user}" }
output "bastion_private_ip" { value = "${module.bastion_host.private_ip}" }
output "bastion_public_ip"  { value = "${module.bastion_host.public_ip}" }



/*
# Grab the AWS default VPC so that we can put stuff into it
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "rhelfarm" {
  name   = "rhelfarm-sg"
  vpc_id = "${aws_default_vpc.default.id}"

  # allow inbound SSH
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # web port
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # admin console port
  ingress {
    protocol    = "tcp"
    from_port   = 9990
    to_port     = 9990
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow outbound internet access
  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "${var.resource_tag_name}"
  }
}

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

# Create an IAM role so we can pull from S3
resource "aws_iam_role" "default" {
  name               = "${var.resource_tag_name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

# Create an IAM policy to be able to pull binaries/installers from S3
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
        "arn:aws:s3:::${var.aws_s3_bucket_name}${var.aws_s3_binaries_path}/*"
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

resource "aws_instance" "app_node" {
  ami             = "${var.aws_ami_rhel75}"
  count           = "${var.app_node_count}"
  instance_type   = "${var.app_node_instance_type}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.rhelfarm.name}"]
  
  # Add the instance profile to allow it to pull files from S3
  iam_instance_profile   = "${aws_iam_instance_profile.default.name}"
  
/*
  # COMMENTING this out because it just doesn't work....
  
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
*

  tags {
    Name = "rhelfarm${count.index}"
    sshUser = "ec2-user"
    role = "app_node"
  }
}

output "app_node_instance_ips" {
  value = ["${aws_instance.app_node.*.public_ip}"]
}

/*
resource "aws_instance" "bastion" {
  ami                         = "${var.aws_ami}"
  key_name                    = "${aws_key_pair.bastion_key.key_name}"
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.bastion-sg.name}"]
  associate_public_ip_address = true
}

resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
  vpc_id = "${aws_default_vpc.default.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "rhelfarm"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
*/
