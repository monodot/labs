# labs

Terraform + Ansible scripts for setting up disposable environments for testing, POCs, etc.

## Prerequisites

Most of the labs depend on AWS. 

Before applying, ensure that AWS credentials have first been set in `~/.aws/credentials`, e.g.:

    [default]
    aws_access_key_id = SOMETHINGSECRET
    aws_secret_access_key = somethingevenmoresecret
