
import os
import requests
import boto3
import json
from aws_lambda_powertools import Logger

logger = Logger()
BUCKET_NAME = os.environ["BUCKET_NAME"]

@logger.inject_lambda_context
def handler(event, context):
    
    try:
        logger.info(event)

        validate(event)

        ml = MercadoLivre(access_token=event.get('access_token'))
        
        data = ml.get(event.get('next_items'))

        save(event.get('entity'), data['results'])

        if not build_next(data):
            event.pop('next_items')
            return event
        
        event['next_items'] = build_next(data)

        return event
    except Exception as e:
        logger.error(e)
        raise e

def save(entity, items):
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(BUCKET_NAME)
    for item in items:
        bucket.put_object(Key=f'{entity}/{item["id"]}.json', Body=json.dumps(item))

def validate(event):
    if event.get('next_items') == None:
        raise Exception("Attribute 'next_items' have been present with string value")
    if not event.get('next_items'):
        raise Exception("Attribute 'next_items' not have been empty string")

def build_next(data):
    return data.get('next')

class MercadoLivre:
    def __init__(self, access_token):
        self.headers = {"Authorization": "Bearer " + access_token}

    def get(self, url):
        response =  requests.get(url, headers=self.headers)
        if response.status_code != 200:
            logger.error(f"Error: Request returned status code {response.status_code}")
            raise Exception(response.text)
        return response.json()