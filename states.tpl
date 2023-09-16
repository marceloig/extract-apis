{
    "Comment": "Mercado Livre Flow",
    "StartAt": "Get Mercado Livre Items",
    "States": {
      "Get Mercado Livre Items": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${lambda_function_arn}:$LATEST"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "Has Next Items?"
      },
      "Has Next Items?": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.next_items",
            "IsPresent": true,
            "Next": "Get Mercado Livre Items"
          }
        ],
        "Default": "Success"
      },
      "Success": {
        "Type": "Succeed"
      }
    }
  }