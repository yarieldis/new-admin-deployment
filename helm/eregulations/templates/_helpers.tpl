{{/*
Tenant name — uses release name if tenant.name is not set
*/}}
{{- define "eregulations.tenantName" -}}
{{- default .Release.Name .Values.tenant.name }}
{{- end }}

{{/*
Common labels applied to all resources
*/}}
{{- define "eregulations.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: eregulations
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
SPA selector labels
*/}}
{{- define "eregulations.spa.selectorLabels" -}}
app.kubernetes.io/name: spa
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
WebAPI selector labels
*/}}
{{- define "eregulations.webapi.selectorLabels" -}}
app.kubernetes.io/name: webapi
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Build a .NET connection string
*/}}
{{- define "eregulations.connectionString" -}}
Data Source={{ .host }},{{ .port }};Initial Catalog={{ .catalog }};User Id={{ .user }};Password={{ .password }};MultipleActiveResultSets=true;TrustServerCertificate=True
{{- end }}
