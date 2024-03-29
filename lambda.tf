# Run Trigger 적용 시, Source Workspace상의 output을 활용하기 위하여 추가
data "terraform_remote_state" "lambda-app" {
  backend = "remote"

  config = {
    organization = "snapshot_tf_serverless"
    workspaces = {
      name = "lambda-app"
    }
  }
}

provider "aws" {
   region = "ap-northeast-2"
}

resource "aws_lambda_function" "example" {
   function_name = "ServerlessExample"
   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = "jsp-lambda-code-bucket1"
   #s3_key    = "v${var.code_version}/example.zip"
   # Remote state 사용을 위해 아래와 같이 수정
   s3_key    = "v${data.terraform_remote_state.lambda-app.outputs.code_version}/example.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "main.handler"
   runtime = "nodejs16.x"

   role = aws_iam_role.lambda_exec.arn
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "lambda_exec" {
   name = "jsp-serverless_example_lambda1"

   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
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


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.example.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
