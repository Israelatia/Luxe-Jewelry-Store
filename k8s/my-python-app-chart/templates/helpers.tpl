{{- define "frontend.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "frontend.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}
