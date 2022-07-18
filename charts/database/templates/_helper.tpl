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
- name: "DRYCC_STORAGE_LOOKUP"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: lookup
- name: "DRYCC_STORAGE_BUCKET"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: database-bucket
- name: "DRYCC_STORAGE_ENDPOINT"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: endpoint
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