# fusefabric (AWS)

JBoss Fuse Fabric lab environment on AWS.

- 3 x Fabric Servers
- 2 x Managed Container nodes

You will need:

- An AWS account
- An S3 bucket for storing the JBoss Fuse distribution

Fuse requires:

- 700 MB of free disk space
- 2 GB of free RAM

## Make the JBoss Fuse distribution available

Log in to the Red Hat Customer Portal in Chrome or Firefox and navigate to the JBoss Fuse downloads page.

Then, download the Fuse distribution, either:

- Download the file using your web browser, **OR**

- Download the file using `curl`:

  1.  Using your browser's Dev Tools, grab your `JSESSIONID` cookie value.

  2.  At the command line, store the cookie value in an environment variable, and use `curl` to download the binary:

    $ export JSESSIONID=<yoursessionid>
    $ curl --cookie "JSESSIONID=$JSESSIONID;" -OL https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=XXXXX

Finally, upload the binary to an S3 bucket 🐝:

    $ aws s3 cp ./jboss-fuse-karaf-6.3.0.redhat-310.zip s3://mybucket/files/

## To deploy

Run Terraform to build the cloud infrastructure:

    $ terraform init
    $ terraform plan -var-file=../terraform.tfvars
    $ terraform apply -var-file=../terraform.tfvars

## To destroy

**IMPORTANT:** To delete the infrastructure when you've finished with it:

    $ terraform destroy -var-file=../terraform.tfvars

## TODO

CONT: resolve this:

```
4 error(s) occurred:

* aws_key_pair.auth: 1 error(s) occurred:

* aws_key_pair.auth: Error import KeyPair: InvalidParameterValue: Value for parameter PublicKeyMaterial is invalid. Length exceeds maximum of 2048.
	status code: 400, request id: xxxx
* aws_instance.fabric_server[0]: 1 error(s) occurred:

* timeout
* aws_instance.fabric_server[2]: 1 error(s) occurred:

* timeout
* aws_instance.fabric_server[1]: 1 error(s) occurred:

* timeout
```

