{
    "Comment": "Spotify Flow",
    "StartAt": "Get Spotify Playlists",
    "States": {
      "Get Spotify Playlists": {
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
        "Next": "Has Next Playlist?"
      },
      "Has Next Playlist?": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.next_playlist",
            "IsPresent": true,
            "Next": "Get Spotify Playlists"
          }
        ],
        "Default": "Success"
      },
      "Success": {
        "Type": "Succeed"
      }
    }
  }