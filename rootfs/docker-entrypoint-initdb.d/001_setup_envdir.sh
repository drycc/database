#!/usr/bin/env bash

cd "$WALG_ENVDIR"

AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/drycc/minio/creds/accesskey)
AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/drycc/minio/creds/secretkey)

BUCKET_FILE="/var/run/secrets/drycc/minio/creds/database-bucket"
if [ -f $BUCKET_FILE ]; then
  BUCKET_NAME=$(cat "$BUCKET_FILE")
  export BUCKET_NAME
else
  export BUCKET_NAME="database"
fi

echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
echo "s3://$BUCKET_NAME/$PG_MAJOR" > WALE_S3_PREFIX
echo "http://${DRYCC_MINIO_ENDPOINT}" > AWS_ENDPOINT
echo "true" > AWS_S3_FORCE_PATH_STYLE
echo $AWS_REGION > S3_REGION
echo $BUCKET_NAME > BUCKET_NAME
