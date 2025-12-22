#!/bin/bash
set -e

# Setup Rclone 
/usr/share/scripts/create_bucket

# Backup PostgreSQL databases to S3-compatible object storage
export PGPASSWORD=$DRYCC_DATABASE_SUPERUSER_PASSWORD
PGPORT=$DRYCC_DATABASE_REPLICA_SERVICE_PORT_POSTGRES
PGUSER=postgres
POSTGRES_HOST=$DRYCC_DATABASE_REPLICA_SERVICE_HOST
RETAIN_BACKUPS_AGE=$RETAIN_BACKUPS_AGE

# PostgreSQL global objects backup 
BACKUP_PATH="${DRYCC_STORAGE_BUCKET}/$(date +%Y%m%d%H%M)"
echo "DB: ${POSTGRES_USER}@${POSTGRES_HOST}"
echo "S3 Storage: storage:${BACKUP_PATH}"
# Backup global objects
if pg_dumpall -g -U "${POSTGRES_USER}" -h "${POSTGRES_HOST}" \
  | pigz -c -p 4 -6 \
  | rclone rcat \
      "storage:${BACKUP_PATH}/roles_globals.sql.gz" \
      --bwlimit 10M \
      --transfers 4 \
      --s3-chunk-size 64M \
      --stats 5s \
      --progress \
      --retries 3; then  
  echo "✅ PostgreSQL global objects backup complated!" 
fi 
  # fetch the list of databases
  DATABASES=$(psql -U "$POSTGRES_USER" -h "$POSTGRES_HOST" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

  # backup each database individually
  for DB in $DATABASES; do
    echo "Backing up $DB to $MINIO_PATH/$DB.sql.gz"
    if pg_dump -U "${POSTGRES_USER}" -h "${POSTGRES_HOST}" "$DB" \
        | pigz -c -p 4 -6 \
        | rclone rcat \
            "storage:${BACKUP_PATH}/$DB.sql.gz" \
            --bwlimit 10M \
            --transfers 4 \
            --s3-chunk-size 64M \
            --stats 5s \
            --progress \
            --retries 3; then
        echo "✅ PostgreSQL $DB global objects backup completed!"
    fi
  done

  echo "Backup process completed!"

  echo "delete storage before ${RETAIN_BACKUPS_AGE} ..."
  rclone delete "storage:${DRYCC_STORAGE_BUCKET}" \
    --min-age ${RETAIN_BACKUPS_AGE} \
    --include "*.sql.gz" \
    --dry-run \
    -v  || true

  rclone delete "storage:${DRYCC_STORAGE_BUCKET}" \
    --min-age ${RETAIN_BACKUPS_AGE} \
    --include "*.sql.gz" \
    || true
  echo "delete completed."

echo "=== backup completed: $(date) ==="
