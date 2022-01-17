#!/usr/bin/env bash

# check if there are any backups -- if so, let's restore
# we could probably do better than just testing number of lines -- one line is just a heading, meaning no backups

if [[ $(envdir "$WALG_ENVDIR" wal-g backup-list | wc -l) -gt "1" ]]; then
  echo "Found backups. Restoring from backup..."
  {
    gosu postgres pg_ctl -D "$PGDATA" -w stop > /dev/null 2>&1
  } || {
    echo "ignore script errors"
  }
  rm -rf "$PGDATA"
  envdir "$WALG_ENVDIR" wal-g backup-fetch "$PGDATA" LATEST
  touch "$PGDATA/recovery.signal"
  cat << EOF > "$PGDATA/postgresql.conf"
# These settings are initialized by initdb, but they can be changed.
log_timezone = 'UTC'
lc_messages = 'C'     # locale for system error message
lc_monetary = 'C'     # locale for monetary formatting
lc_numeric = 'C'      # locale for number formatting
lc_time = 'C'       # locale for time formatting
default_text_search_config = 'pg_catalog.english'
huge_pages = try
wal_level = archive
archive_mode = on
archive_command = 'envdir "${WALG_ENVDIR}" wal-g wal-push %p'
archive_timeout = 60
listen_addresses = '*'
max_connections = 1024
restore_command = 'envdir "${WALG_ENVDIR}" wal-g wal-fetch \"%f\" \"%p\"'
EOF
  cat << EOF > "$PGDATA/pg_hba.conf"
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# IPv4 global connections
host    all             all             0.0.0.0/0               md5
EOF
  touch "$PGDATA/pg_ident.conf"
  touch "$PGDATA/recovery.signal"
  chown -R postgres:postgres "$PGDATA"
  chmod 0700 "$PGDATA"
  gosu postgres pg_ctl -D "$PGDATA" \
      -o "-c listen_addresses=''" \
      -w start
else
  cat << EOF >> "$PGDATA/postgresql.conf"
huge_pages = try
wal_level = archive
archive_mode = on
archive_command = 'envdir "${WALG_ENVDIR}" wal-g wal-push %p'
archive_timeout = 60
max_connections = 1024
EOF

  # ensure $PGDATA has the right permissions
  chown -R postgres:postgres "$PGDATA"
  chmod 0700 "$PGDATA"

  # reboot the server for wal_level to be set before backing up
  echo "Rebooting postgres to enable archive mode"
  gosu postgres pg_ctl -D "$PGDATA" -w restart
fi

# ensure $PGDATA has the right permissions
chown -R postgres:postgres "$PGDATA"
chmod 0700 "$PGDATA"
