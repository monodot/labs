# labs

Terraform + Ansible scripts for setting up disposable environments for testing, POCs, etc. 

This repo also serves a second purpose as my testing ground for learning [Terraform][terraform]. :)

## Prerequisites

The labs almost exclusively depend on AWS. So you need an AWS account and billing set up, etc.

Before applying, make sure that you create a file containing your AWS credentials so that Terraform can use it. Put them in `~/.aws/credentials` (If you use the [AWS CLI tool][awscli] then this should already be created for you.) The file should look like this:

    [default]
    aws_access_key_id = SOMETHINGSECRET
    aws_secret_access_key = somethingevenmoresecretwsssss

[terraform]: https://www.terraform.io/
[awscli]: https://aws.amazon.com/cli/
