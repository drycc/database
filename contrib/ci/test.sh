#!/usr/bin/env bash

set -eof pipefail

puts-step() {
  echo "-----> $*"
}

puts-error() {
  echo "!!!    $*"
}

kill-containers() {
	puts-step "destroying containers $*"
	docker rm -f "$@"
}

create-postgres-creds() {
  puts-step "creating fake postgres credentials"

  # create fake postgres credentials
  mkdir -p "${CURRENT_DIR}"/tmp/creds
  echo "testuser" > "${CURRENT_DIR}"/tmp/creds/user
  echo "icanttellyou" > "${CURRENT_DIR}"/tmp/creds/password
  echo "drycc_controller" > "${CURRENT_DIR}"/tmp/creds/controller-database-name
  echo "drycc_passport" > "${CURRENT_DIR}"/tmp/creds/passport-database-name
}

start-postgres() {
  export PG_JOB
  PG_JOB=$($1)
  # wait for postgres to boot
  puts-step "sleeping for 30s while postgres is booting..."
  sleep 30s
}

check-postgres() {
  # display logs for debugging purposes
  puts-step "displaying postgres logs"
  docker logs "$1"

  # check if postgres is running
  puts-step "checking if postgres is running"
  docker exec "$1" init-stack is_running
}
