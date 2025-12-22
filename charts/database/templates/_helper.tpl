{{- define "database.envs" }}
env:
- name: RETAIN_BACKUPS_AGE
  value: "{{.Values.cronjob.retainBackupsAge}}"
{{- if (.Values.storageEndpoint) }}
- name: "DRYCC_STORAGE_BUCKET"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: storage-bucket
- name: "DRYCC_STORAGE_ENDPOINT"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: storage-endpoint
- name: "DRYCC_STORAGE_ACCESSKEY"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: storage-accesskey
- name: "DRYCC_STORAGE_SECRETKEY"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: storage-secretkey
- name: "DRYCC_STORAGE_PATH_STYLE"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: storage-path-style
{{- else if .Values.storage.enabled  }}
- name: "DRYCC_STORAGE_BUCKET"
  value: "database"
- name: "DRYCC_STORAGE_ENDPOINT"
  value: http://drycc-storage:9000
- name: "DRYCC_STORAGE_ACCESSKEY"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: accesskey
- name: "DRYCC_STORAGE_SECRETKEY"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: secretkey
- name: "DRYCC_STORAGE_PATH_STYLE"
  value: "true"
{{- end }}
{{- if eq .Values.debug "true" }}
- name: PATRONI_LOG_LEVEL
  value: DEBUG
- name: PATRONI_LOG_TRACEBACK_LEVEL
  value: DEBUG
{{- end }}
- name: PGCTLTIMEOUT
  value: "{{.Values.timeout}}"
- name: PATRONI_KUBERNETES_POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: PATRONI_KUBERNETES_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: PATRONI_KUBERNETES_BYPASS_API_SERVICE
  value: 'true'
- name: PATRONI_KUBERNETES_USE_ENDPOINTS
  value: 'true'
- name: PATRONI_KUBERNETES_LABELS
  value: '{app: drycc-database, cluster-name: drycc-database}'
- name: PATRONI_SCOPE
  value: drycc-database
- name: PATRONI_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: PATRONI_POSTGRESQL_PGPASS
  value: /tmp/pgpass
- name: PATRONI_POSTGRESQL_LISTEN
  value: '0.0.0.0:5432'
- name: PATRONI_RESTAPI_LISTEN
  value: '0.0.0.0:8008'
- name: "DRYCC_DATABASE_INIT_NAMES"
  value: "{{.Values.initDatabases}}"
- name: "DRYCC_DATABASE_EXTENSIONS"
  value: "{{.Values.databaseExtensions}}"
- name: DRYCC_DATABASE_SUPERUSER
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: superuser
- name: DRYCC_DATABASE_SUPERUSER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: superuser-password
- name: DRYCC_DATABASE_REPLICATOR
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: replicator
- name: DRYCC_DATABASE_REPLICATOR_PASSWORD
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: replicator-password
- name: "DRYCC_DATABASE_USER"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: user
- name: "DRYCC_DATABASE_PASSWORD"
  valueFrom:
    secretKeyRef:
      name: database-creds
      key: password
{{- end }}
