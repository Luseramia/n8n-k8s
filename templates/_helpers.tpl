{{/*
Expand the name of the chart.
*/}}
{{- define "n8n.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "n8n.fullname" -}}
{{- if .Values.fullnameOverride }}
{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" (include "n8n.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
