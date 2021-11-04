import json
from pprint import pprint
import os

import boto3


s3 = boto3.client('s3')

def lambda_handler(event, context):
    resp = s3.list_buckets()
    buckets = [x['Name'] for x in resp['Buckets']]

    my_bucket = 'igorlg-isen-files'
    objs = s3.list_objects(Bucket=my_bucket)

    print(f"Fetched {len(buckets)} buckets")
    print(f"Fetched {len(objs)} objects from {my_bucket}")
    print('Done!')

