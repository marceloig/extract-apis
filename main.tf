data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

data "aws_region" "current" {}

locals {
  name = "extract-apis"
}

module "docker_image_mercado_livre" {
  source = "terraform-aws-modules/lambda/aws//modules/docker-build"

  create_ecr_repo = true
  ecr_repo        = "${local.name}-mercado-livre"
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 2 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 2
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
  image_tag   = "0.1"
  source_path = "mercado-livre"
  platform    = "linux/amd64"
}


module "lambda_mercado_livre" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "5.0.0"

  function_name = "${local.name}-mercado-livre"
  description   = "My awesome lambda function"

  memory_size    = 1024
  timeout        = 60 # seconds
  create_package = false
  image_uri      = module.docker_image_mercado_livre.image_uri
  package_type   = "Image"
  architectures  = ["x86_64"]

  environment_variables = {
    TABLE_NAME = ""
  }
  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["s3:*"],
      resources = ["*"]
    }
  }
  create_current_version_allowed_triggers = false
}

module "step_function" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "3.1.0"

  name = "sf-${local.name}-mercado-livre"
  definition = templatefile("${path.module}/states.tpl", {
    lambda_function_arn = module.lambda_mercado_livre.lambda_function_arn
  })

  logging_configuration = {
    include_execution_data = false
    level                  = "ERROR"
  }
  service_integrations = {
    lambda = {
      lambda = [module.lambda_mercado_livre.lambda_function_arn, "${module.lambda_mercado_livre.lambda_function_arn}:*"]
    }
  }

  type = "STANDARD"
}

