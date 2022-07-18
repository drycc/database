#!/usr/bin/env bash

set -eof pipefail

cleanup() {
  kill-containers "${STORAGE_JOB}" "${PG_JOB}"
}
trap cleanup EXIT

TEST_ROOT=$(dirname "${BASH_SOURCE[0]}")/
# shellcheck source=/dev/null
source "${TEST_ROOT}/test.sh"

# make sure we are in this dir
CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

create-postgres-creds

puts-step "creating fake storage credentials"

s3Accesskey="1234567890123456789012345678901234567890"
s3Secretkey="1234567890123456789012345678901234567890"
# boot storage
mkdir -p "${CURRENT_DIR}"/tmp/bin
echo "ls /data/database/*/basebackups_005" > "${CURRENT_DIR}"/tmp/bin/backups.sh
STORAGE_JOB=$(docker run -d \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey \
  -v "${CURRENT_DIR}"/tmp/bin:/tmp/bin \
  "${DEV_REGISTRY}"/drycc/storage:canary server /data/)

puts-step "storage starting, wait 30s."
sleep 30

# boot postgres, linking the storage container and setting DRYCC_STORAGE_ENDPOINT
STORAGE_IP=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" "${STORAGE_JOB}")
PG_CMD="docker run -d \
  --add-host storage.local:${STORAGE_IP} \
  -e PGCTLTIMEOUT=1200 \
  -e BACKUP_FREQUENCY=1s \
  -e DATABASE_STORAGE=storage \
  -e DRYCC_STORAGE_LOOKUP=path \
  -e DRYCC_STORAGE_BUCKET=database \
  -e DRYCC_STORAGE_ENDPOINT=http://storage.local:9000 \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey $1"

start-postgres "${PG_CMD}"

# display logs for debugging purposes
puts-step "displaying storage logs"
docker logs "${STORAGE_JOB}"

check-postgres "${PG_JOB}"

# check if storage has the 5 backups
puts-step "checking if storage has 5 backups"
BACKUPS="$(docker exec "${STORAGE_JOB}" sh /tmp/bin/backups.sh | grep json)"

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
