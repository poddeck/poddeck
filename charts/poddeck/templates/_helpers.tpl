{{- define "poddeck.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "poddeck.labels" -}}
app.kubernetes.io/name: poddeck
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "poddeck.coreImage" -}}
{{ .Values.core.image.repository }}:{{ .Values.core.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{- define "poddeck.panelImage" -}}
{{ .Values.panel.image.repository }}:{{ .Values.panel.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{- define "poddeck.dbHost" -}}
{{- if .Values.postgresql.enabled -}}
{{ include "poddeck.fullname" . }}-postgresql
{{- else -}}
{{ .Values.externalDatabase.host }}
{{- end -}}
{{- end -}}

{{- define "poddeck.dbPort" -}}
{{- if .Values.postgresql.enabled -}}
5432
{{- else -}}
{{ .Values.externalDatabase.port }}
{{- end -}}
{{- end -}}

{{- define "poddeck.dbName" -}}
{{- if .Values.postgresql.enabled -}}
{{ .Values.postgresql.auth.database }}
{{- else -}}
{{ .Values.externalDatabase.database }}
{{- end -}}
{{- end -}}

{{- define "poddeck.dbUser" -}}
{{- if .Values.postgresql.enabled -}}
{{ .Values.postgresql.auth.username }}
{{- else -}}
{{ .Values.externalDatabase.username }}
{{- end -}}
{{- end -}}
