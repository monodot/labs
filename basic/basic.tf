provider "aws" {
  shared_credentials_file = "${var.aws_credentials_file}"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

data "aws_subnet" "default" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["default-public-subnet"]
  }
}

resource "aws_instance" "basic" {
  ami = "ami-bb9a6bc2"
  instance_type = "t2.micro"
  subnet_id = "${data.aws_subnet.default.id}"
  
  tags {
    Name = "labs-basic"
  }
}

/*
resource "aws_vpc" "basic" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "eu-west-1a-public" {
  vpc_id = "${aws_vpc.basic.id}"
  cidr_block = "10.0.1.0/25"
  availability_zone = "eu-west-1a"
}
*/
