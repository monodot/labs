# fusefabric (AWS)

JBoss Fuse Fabric lab environment on AWS (**WORK IN PROGRESS**):

- 3 x [Fabric Server][fabricconcepts] nodes (`t2.medium`)
- 2 x [Managed Container][fabricconcepts] (`t2.medium`)

You will need:

- An AWS account
- An S3 bucket for storing the JBoss Fuse distribution

Fuse requires:

- 700 MB of free disk space
- 2 GB of free RAM

Each node is provisioned with:

- OpenJDK (`java-1.8.0-openjdk-devel`)
- `pip` and `awscli` (for easy S3 access)

## Make the JBoss Fuse distribution available

Log in to the Red Hat Customer Portal in Chrome or Firefox and navigate to the JBoss Fuse downloads page.

Then, download the Fuse distribution, either:

- Download the file using your web browser, **OR**

- Download the file using `curl`:

  1.  Using your browser's Dev Tools, grab your `JSESSIONID` cookie value.

  2.  At the command line, store the cookie value in an environment variable, and use `curl` to download the binary:

      ```
      $ export JSESSIONID=<yoursessionid>
      $ curl --cookie "JSESSIONID=$JSESSIONID;" -OL https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=XXXXX
      ```

Finally, upload the binary to an S3 bucket 🐝:

    $ aws s3 cp ./jboss-fuse-karaf-6.3.0.redhat-310.zip s3://mybucket/files/

## Deploy

Run Terraform to **deploy** the cloud infrastructure:

    $ terraform init
    $ terraform plan -var-file=../terraform.tfvars
    $ terraform apply -var-file=../terraform.tfvars

## To describe

To show the current Terraform state:

    $ terraform refresh -var-file=../terraform.tfvars
    $ terraform state

To show the IP addresses of the containers, fetch the relevant _output_ that has been configured in `main.tf`:

    $ terraform output fabric_server_instance_ips
    192.2.3.4,
    192.2.3.5,
    192.2.3.6
    $ terraform output managed_container_instance_ips

## To play

To connect to a container:

    $ ssh -i /path/to/yourkey.pem ec2-user@<ip-address>

## To destroy

Don't forget to **destroy the infrastructure** when you've finished with it:

    $ terraform destroy -var-file=../terraform.tfvars


[fabricconcepts]: https://access.redhat.com/documentation/en-us/red_hat_jboss_fuse/6.3/html/fabric_guide/fabric_overview#Fabric_Overview-Concepts
