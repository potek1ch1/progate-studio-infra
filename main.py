import boto3
import gzip

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # イベントからS3の情報を取得
    record = event['Records'][0]
    bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']

    # S3からgzipログを取得して解凍
    response = s3.get_object(Bucket=bucket, Key=key)
    compressed_body = response['Body'].read()
    log_content = gzip.decompress(compressed_body).decode('utf-8')

    # 含めたいパスのリスト
    target_paths = ["/api/webhook", " \"GET / HTTP"]  # ALBログでは「"GET / HTTP」になる点に注意

    for line in log_content.splitlines():
        if any(path in line for path in target_paths):
            print(line)