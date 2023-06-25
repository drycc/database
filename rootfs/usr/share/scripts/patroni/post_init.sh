#!/usr/bin/env bash
set -Eeu

if [[ ( -n "$DRYCC_DATABASE_USER") &&  ( -n "$DRYCC_DATABASE_PASSWORD")]]; then
  echo "Creating user ${DRYCC_DATABASE_USER}"
  psql "$1" -w -c "create user ${DRYCC_DATABASE_USER} WITH LOGIN ENCRYPTED PASSWORD '${DRYCC_DATABASE_PASSWORD}'"
  for dbname in ${DRYCC_DATABASE_INIT_NAMES//,/ }
  do
    echo "Creating database ${dbname}"
    psql "$1" -w -c "CREATE DATABASE ${dbname} OWNER ${DRYCC_DATABASE_USER}"
    for extension in ${DRYCC_DATABASE_EXTENSIONS//,/ }
    do
      echo "Creating extension ${extension}"
      psql "$1" -w << EOF
\c ${dbname};
create extension ${extension};
EOF
    done
  done
else
  echo "Skipping user creation"
  echo "Skipping database creation"
fi
