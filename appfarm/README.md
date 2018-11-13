# appfarm

A module that creates a bunch of RHEL servers, and a bastion host.

Run Terraform to **deploy** the cloud infrastructure:

    $ export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
    $ export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
    $ terraform init
    $ terraform plan -var-file=../terraform.tfvars
    $ terraform apply -var-file=../terraform.tfvars
    
To refresh the current state and show the machine IP addresses:

    $ terraform refresh -var-file=../terraform.tfvars

Then optionally install extra stuff.

Then you can SSH into the boxes using:

    $ ssh -i /path/to/key.pem ec2-user@x.x.x.x
    
    
    

Optional:

- clone the https://github.com/mantl/terraform.py so that it's available in the directory above.


