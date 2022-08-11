# CREATING A SEVERLESS WEBSITE ON AWS USING TERRAFORM

Serverless is fast becoming the new way to run softwares and applications in the cloud.<br>
Let's assume you have a python code you want to make available to your users. If you choose to do with with servers, you will have to provision virtual machines,
install he necessary packages, upgrade versions and so on. This is where serveless comes in.
Severless makes it possible to run your code in the cloud with not muh effort needed from your end in terms of setting up and maintaining the infrastructure.
Serverless is a prouction grade and scalable infrastructure built and managed by serverless.

## Objective

Instead of using the AWS console to manually create a lambda function, we will be using Terraform for effeciency.
Part of what we are going to acheive in this article includes:

- Creating AWS Access Key and Secret

- Installing AWS CLI

- Configuring AWS CLI

- Creating Terraform Manifest/files necessary to create our resources

- Executing the Terraform Manifest and Create resourcs

- Final Validation



__Create AWS Access Key and Secret__

To create an aws Access key and secret, do the following:

- Login to AWS Console

- In the services go to IAM

- Create a User and Click on the map of existing Policies

- Choose UserName and Select the Policy (Administrator Access Policy)

- Create user

- The final Stage would present the AccessKEY and Secret Access like given below.


__Install AWS CLI__

Use the following links to install AWSCLI

[Installing AWS CLI version 2 on Linux or Unix](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
Installing AWS CLI version 2 on macOS
Installing AWS CLI version 2 on Windows
