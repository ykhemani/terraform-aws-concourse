# terraform-aws-concourse

This [Terraform](https://terraform.io) configuration allows you to provision a single instance running [Concourse CI](https://concourse-ci.org/) in [AWS](https://aws.amazon.com/).

A DNS record is provisioned in [Cloudflare](https://www.cloudflare.com/), but the configuration can be adapted to create DNS records with other DNS providers.

An [ACME](https://www.terraform.io/docs/providers/acme/r/certificate.html) PKI certificate is provisioned from [LetsEncrypt](https://letsencrypt.org/) using Cloudflare for the DNS challenge.

This Terraform configuration was created to enable Concourse CI for evaluation purposes. Do NOT use this Terraform configuration in production.

## Prequisites / Dependencies

### Environment variables

The Terraform code requires you to define the following environment variables.

* Environment variables required for authenticating with [AWS](https://www.terraform.io/docs/providers/aws/index.html). For example: `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID` are your AWS credentials.

* `CF_API_EMAIL`, `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY` are your Cloudflare credentials. The reason that we define the Clouldflare email address using two different variables is because `CF_API_EMAIL` is required for the [ACME provider](https://www.terraform.io/docs/providers/acme/dns_providers/cloudflare.html) and `CLOUDFLARE_EMAIL` is required by the [Clouldflare provider](https://www.terraform.io/docs/providers/cloudflare/index.html). You can generate a Cloudflare API key by logging into your Cloudflare account, clicking on *My Profile* in the menu on the top right, and then selecting API Tokens.

### Terraform variables

A number of the Terraform variables in this configuration have defaults that you can use. Others are required and must be configured. The variables are documented in the [variables.tf](variables.tf) file, so we won't repeat the definitions here. Variables that do not have a default must be set. The [terraform.tfvars.example](terraform.tfvars.example) file provides sample values for the variables that do not have defaults.

### Ubuntu 18.04 Image

This Terraform code builds upon the Ubuntu 18.04 machine image, and encrypts the root volume, but the configuration can be adapted to use not encrypt the machine image.

## Running this Terraform code
There is a [tf.sh.example](tf.sh.example) script that sets the aforementioned environment variables. The sensitive variables are set in our example by pulling the values from [LastPass](https://www.lastpass.com/) using the [LastPass CLI](https://github.com/lastpass/lastpass-cli). You can make a copy of this script and save it as `tf.sh`, and customize it to pull from your LastPass account or set these environment variables any way you like, but please don't store them in plain text and please do NOT check them into GitHub or other VCS provider, be it public or privately hosted.

### Initialize Terraform
```
./tf.sh init
```

Or if you are running Terraform directly:

```
terraform init
```

### Plan
```
./tf.sh plan
```

Or if you are running Terraform directly:

```
terraform plan
```

### Apply
```
./tf.sh apply
```

Or if you are running Terraform directly:

```
terraform apply
```

### Outputs
* `a_concourse_instance_ip` - When you run Terraform, you'll get the public IP address of the instance that you've provisioned.
* `b_concourse_hostname` - The hostname of the instance you have provisioned. e.g. `concourse.example.com`.
* `c_ssh_connection` - SSH connection string - e.g. `ssh ubuntu@concourse.example.com`
* `d_concourse_url` - The URL for the Concourse server - .eg. `https://concourse.example.com:8443`
* `e_concourse_username` and `f_concourse_password` - credentials for accessing Concourse.

## Troubleshooting

### Where you ran Terraform
```
./tf.sh show
```

or
```
terraform show
```

### On the instance
* Cloud init logs: `/var/log/cloud-init.log`
* Cloud init output: `cloud-init-output.log`
* User data script that can be identified by running `find /var/lib -name 'part-001'`

---
