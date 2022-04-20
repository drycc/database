{{- define "database.envs" }}
env:
- name: DATABASE_STORAGE
  value: "{{.Values.global.storage}}"
- name: PGCTLTIMEOUT
  value: "{{.Values.timeout}}"
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
- name: "DRYCC_MINIO_LOOKUP"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: lookup
- name: "DRYCC_MINIO_BUCKET"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: database-bucket
- name: "DRYCC_MINIO_ENDPOINT"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: endpoint
- name: "DRYCC_MINIO_ACCESSKEY"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: accesskey
- name: "DRYCC_MINIO_SECRETKEY"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: secretkey
{{- end }}

{{/* Generate database deployment limits */}}
{{- define "database.limits" -}}
{{- if or (.Values.limitsCpu) (.Values.limitsMemory)}}
resources:
  limits:
    {{- if (.Values.limitsCpu) }}
    cpu: {{.Values.limitsCpu}}
    {{- end }}
    {{- if (.Values.limitsMemory) }}
    memory: {{.Values.limitsMemory}}
    {{- end }}
    {{- if (.Values.limitsHugepages2Mi) }}
    hugepages-2Mi: {{.Values.limitsHugepages2Mi}}
    {{- end }}
    {{- if (.Values.limitsHugepages1Gi) }}
    hugepages-1Gi: {{.Values.limitsHugepages1Gi}}
    {{- end }}
{{- end }}
{{- end }}