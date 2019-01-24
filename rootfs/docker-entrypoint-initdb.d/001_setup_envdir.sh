#!/usr/bin/env bash

cd "$WALG_ENVDIR"

AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/drycc/objectstore/creds/accesskey)
AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/drycc/objectstore/creds/secretkey)
BUCKET_NAME=$(cat /var/run/secrets/drycc/objectstore/creds/database-bucket)

echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
echo "s3://$BUCKET_NAME/$PG_MAJOR" > WALE_S3_PREFIX
echo "http://$DRYCC_MINIO_SERVICE_HOST:$DRYCC_MINIO_SERVICE_PORT" > AWS_ENDPOINT
echo "true" > AWS_S3_FORCE_PATH_STYLE
echo $AWS_REGION > S3_REGION
echo $BUCKET_NAME > BUCKET_NAME
