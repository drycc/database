#!/bin/bash
if [[ $UID -ge 10000 ]]; then
    GID=$(id -g)
    sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
fi

cat > /data/patroni.yaml <<__EOF__
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    failsafe_mode: true
    postgresql:
      use_pg_rewind: true
      use_slots: true
  initdb:
  - auth-host: scram-sha-256
  - auth-local: trust
  - encoding: UTF8
  - locale: ${LANG}
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 scram-sha-256
  - host replication ${DRYCC_DATABASE_REPLICATOR} ${PATRONI_KUBERNETES_POD_IP}/16 scram-sha-256
  post_bootstrap: /usr/share/scripts/patroni/post_init.sh
restapi:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:8008'
postgresql:
  data_dir: '${PGDATA}'
  parameters:
    shared_preload_libraries: 'auto_explain,pg_stat_statements'
    hot_standby: "on"
    max_connections: 1005
    max_worker_processes: 8
    max_wal_senders: 10
    max_replication_slots: 10
    hot_standby_feedback: on
    max_prepared_transactions: 0
    max_locks_per_transaction: 64
    wal_log_hints: "on"
    wal_level: logical
    track_commit_timestamp: "off"
    archive_mode: "on"
    archive_timeout: 300s
    archive_command: "/bin/true"
    log_min_duration_statement: 1000
    log_lock_waits: on
    log_statement: 'ddl' 
    jit: off
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  authentication:
    superuser:
      username: '${DRYCC_DATABASE_SUPERUSER}'
      password: '${DRYCC_DATABASE_SUPERUSER_PASSWORD}'
    replication:
      username: '${DRYCC_DATABASE_REPLICATOR}'
      password: '${DRYCC_DATABASE_REPLICATOR_PASSWORD}'
watchdog:
  mode: off
__EOF__

unset DRYCC_DATABASE_SUPERUSER_PASSWORD DRYCC_DATABASE_REPLICATION_PASSWORD

exec patroni /data/patroni.yaml
