#!/usr/bin/env bash
set -Eeu

if [[ ( -n "$DRYCC_DATABASE_USER") &&  ( -n "$DRYCC_DATABASE_PASSWORD")]]; then
  echo "Creating user ${DRYCC_DATABASE_USER}"
  psql "$1" -w -c "create user ${DRYCC_DATABASE_USER} WITH LOGIN ENCRYPTED PASSWORD '${DRYCC_DATABASE_PASSWORD}'"

  echo "Creating passport and controller databases"
  psql "$1" -w -c "CREATE DATABASE passport OWNER ${DRYCC_DATABASE_USER}"
  psql "$1" -w -c "CREATE DATABASE controller OWNER ${DRYCC_DATABASE_USER}"

else
  echo "Skipping user creation"
  echo "Skipping database creation"
fi
