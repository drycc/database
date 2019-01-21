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

echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/accesskey
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/secretkey

echo $CURRENT_DIR
# boot minio
MINIO_JOB=$(docker run -d \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/minio/user \
  quay.io/drycc/minio:canary server /home/minio/)

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
BACKUPS="$(docker exec "${MINIO_JOB}" ls /home/minio/dbwal/basebackups_005/ | grep json)"
NUM_BACKUPS="$(echo "${BACKUPS}" | wc -w)"
# NOTE (bacongobbler): the BACKUP_FREQUENCY is only 1 second, so we could technically be checking
# in the middle of a backup. Instead of failing, let's consider N+1 backups an acceptable case
if [[ ! "${NUM_BACKUPS}" -eq "5" && ! "${NUM_BACKUPS}" -eq "6" ]]; then
  puts-error "did not find 5 or 6 base backups. 5 is the default, but 6 may exist if a backup is currently in progress (found $NUM_BACKUPS)"
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
