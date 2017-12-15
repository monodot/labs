variable "aws_credentials_file" {}
variable "aws_profile" {}
variable "aws_region" {}
variable "aws_default_subnet" {}

variable "ami" {
  default = "CentOS Linux*"
}

provider "aws" {
  shared_credentials_file = "${var.aws_credentials_file}"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

data "aws_subnet" "default" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_default_subnet}"]
  }
}

data "aws_ami" "default" {
  //provider    = "aws.${var.aws_region}"
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami}"]
  }
}

# ......

resource "aws_instance" "basic" {
  ami = "ami-bb9a6bc2"
  ami = "${data.aws_ami.default.image_id}"
  instance_type = "t2.micro"
  subnet_id = "${data.aws_subnet.default.id}"
  
  tags {
    Name = "labs-minishift"
  }
}
