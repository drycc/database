#!/usr/bin/env bash

set -eof pipefail

cleanup() {
  kill-containers "${MINIO_JOB}" "${PG_JOB}"
}
trap cleanup EXIT

TEST_ROOT=$(dirname "${BASH_SOURCE[0]}")/
# shellcheck source=/dev/null
source "${TEST_ROOT}/test.sh"

# make sure we are in this dir
CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

create-postgres-creds

puts-step "creating fake minio credentials"

mkdir -p "${CURRENT_DIR}"/tmp/aws-user
echo "us-east-1" > "${CURRENT_DIR}"/tmp/aws-user/region
echo "database-bucket" > "${CURRENT_DIR}"/tmp/aws-user/database-bucket
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/accesskey
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/secretkey

# boot minio
mkdir -p "${CURRENT_DIR}"/tmp/bin
echo "ls /data/*/*/basebackups_005" > "${CURRENT_DIR}"/tmp/bin/backups.sh
MINIO_JOB=$(docker run -d \
  -v "${CURRENT_DIR}"/tmp/bin:/tmp/bin \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds \
  drycc/minio:canary server /data/)


puts-step "minio starting, wait 30s."
sleep 30

# boot postgres, linking the minio container and setting DRYCC_MINIO_SERVICE_HOST and DRYCC_MINIO_SERVICE_PORT
PG_CMD="docker run -d --link ${MINIO_JOB}:minio -e PGCTLTIMEOUT=1200 \
  -e BACKUP_FREQUENCY=1s -e DATABASE_STORAGE=minio \
  -e DRYCC_MINIO_SERVICE_HOST=minio -e DRYCC_MINIO_SERVICE_PORT=9000 \
  -v ${CURRENT_DIR}/tmp/creds:/var/run/secrets/drycc/database/creds \
  -v ${CURRENT_DIR}/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds $1"

start-postgres "${PG_CMD}"

# display logs for debugging purposes
puts-step "displaying minio logs"
docker logs "${MINIO_JOB}"

check-postgres "${PG_JOB}"

# check if minio has the 5 backups
puts-step "checking if minio has 5 backups"
BACKUPS="$(docker exec "${MINIO_JOB}" sh /tmp/bin/backups.sh | grep json)"
NUM_BACKUPS="$(echo "${BACKUPS}" | wc -w)"
# NOTE (bacongobbler): the BACKUP_FREQUENCY is only 1 second, so we could technically be checking
# in the middle of a backup. Instead of failing, let's consider N+1 backups an acceptable case
if [[ "${NUM_BACKUPS}" -lt "5" ]]; then
  puts-error "the number of backups is less than 5 (found $NUM_BACKUPS)"
  puts-error "${BACKUPS}"
  exit 1
fi

# kill off postgres, then reboot and see if it's running after recovering from backups
puts-step "shutting off postgres, then rebooting to test data recovery"
kill-containers "${PG_JOB}"

start-postgres "${PG_CMD}"

check-postgres "${PG_JOB}"

puts-step "tests PASSED!"
exit 0
