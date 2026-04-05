{{- define "poddeck-agent.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "poddeck-agent.labels" -}}
app.kubernetes.io/name: poddeck-agent
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "poddeck-agent.selectorLabels" -}}
app.kubernetes.io/name: poddeck-agent
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "poddeck-agent.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
