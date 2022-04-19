{{- define "database.envs" -}}
env:
- name: DATABASE_STORAGE
  value: "{{.Values.global.storage}}"
- name: PGCTLTIMEOUT
  value: "{{.Values.timeout}}"
{{- if eq .Values.global.minioLocation "on-cluster" }}
- name: "DRYCC_MINIO_ENDPOINT"
  value: ${DRYCC_MINIO_SERVICE_HOST}:${DRYCC_MINIO_SERVICE_PORT}
{{- else }}
- name: "DRYCC_MINIO_ENDPOINT"
  value: "{{ .Values.minio.endpoint }}"
{{- end }}
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