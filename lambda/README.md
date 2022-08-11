# CREATING A SEVERLESS WEBSITE ON AWS USING TERRAFORM|AWS|API GATEWAY|LAMBDA


<img width="445" alt="image" src="https://user-images.githubusercontent.com/99150197/184138746-0b74d6bd-83de-4be7-96f7-f6ee604a7aca.png">


Serverless is fast becoming the new way to run softwares and applications in the cloud.<br>
Let's assume you have a python code you want to make available to your users. If you choose to do with with servers, you will have to provision virtual machines,
install the necessary packages, upgrade versions and so on. This is where serveless comes in.
Severless makes it possible to run your code in the cloud with not muh effort needed from your end in terms of setting up and maintaining the infrastructure.
Serverless is a production grade and scalable infrastructure built and managed by serverless.

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

- [Installing AWS CLI version 2 on Linux or Unix](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- [Installing AWS CLI version 2 on macOS](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

- [Installing AWS CLI version 2 on Windows](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


__Configure AWS CLI__

To configure the AWS CLI, do the following,

- Use `aws --version` to check that he CLI has been installed

- Do `aws configure`. This will prompt you to enter your access key, secret key and region.


__Lambda function code__

create a file named `lambda.py`  and paste in the following code. When triggered by the API gateway, the code will display the IP address of users.

```python
import json

def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps(event['headers']['X-Forwarded-For'])
    }
```

__Terraform script to configure Lambda__

We will create a `main.tf` file. This file will define our requirements and necessary resources to create Lambda on AWS.

```terraform
provider "aws" {
  region = "us-east-1"
}

provider "archive" {}
data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda.zip"
}

resource "aws_iam_role" "lamda-iam" {
  name               = "lambda-iam"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts.AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]

    
  }
  EOF
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "lambda-function"
  role             = aws_iam_role.lamda-iam.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = "python3.8"
}

resource "aws_apigatewayv2_api" "lambda-api" {
  name          = "v2-http-api"
  protocol_type = "HTTP"

}

resource "aws_apigatewayv2_stage" "lambda-stage" {
  api_id      = aws_apigatewayv2_api.lambda-api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda-integration" {
  api_id               = aws_apigatewayv2_api.lambda-api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda-api.id
  route_key = "GET/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda-integration.id}"
}


resource "aws_lambda_permission" "api-gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda-api.execution_arn}/*/*/*"
}
```

Let's see what each block in our `main.tf` does

___Provider block___

With this block, we instruct terraform to use AWS as our provider.
```terraform
provider "aws" {
  region = "us-east-1"
}
```

___Archive block___

The archive block creates a zip file of our source code to deploy it into Lambda

```terraform
provider "archive" {}
data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda.zip"

```

___Iam_role block___

The iam_role block creates an iam role that will later be attached to our lambda_function resource block

```terraform
resource "aws_iam_role" "lamda-iam" {
  name               = "lambda-iam"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts.AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]

    
  }
  EOF
}


```

___aws_lambda_function_block___

Here, we can now use all previous resources created to create our core lambda function.
we are going to create a lambda function named lambda using the zip file we have created earlier with archive_file block
Also, we are using the role we have created with aws_iam_role and define our runtime which is needed for our python sourcecode to run properly.


```terraform
resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "lambda-function"
  role             = aws_iam_role.lamda-iam.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = "python3.8"
}

```

___apigateway block___

Now we create the aws service that will be used to trigger our lambda function.
In this case, we will use API gateway. Together with AWS Lambda, API Gateway forms the app-facing part of the AWS serverless infrastructure.

```terraform
resource "aws_apigatewayv2_api" "lambda-api" {
  name          = "v2-http-api"
  protocol_type = "HTTP"

}

resource "aws_apigatewayv2_stage" "lambda-stage" {
  api_id      = aws_apigatewayv2_api.lambda-api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda-integration" {
  api_id               = aws_apigatewayv2_api.lambda-api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda-api.id
  route_key = "GET/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda-integration.id}"
}


resource "aws_lambda_permission" "api-gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda-api.execution_arn}/*/*/*"
}

```
