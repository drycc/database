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
    postgresql:
      use_pg_rewind: true
  initdb:
  - auth-host: md5
  - auth-local: trust
  - encoding: UTF8
  - locale: ${LANG}
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 md5
  - host replication ${DRYCC_DATABASE_REPLICATOR} ${PATRONI_KUBERNETES_POD_IP}/16 md5
  post_bootstrap: /usr/share/scripts/patroni/post_init.sh
restapi:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:8008'
postgresql:
  data_dir: '${PGDATA}'
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
