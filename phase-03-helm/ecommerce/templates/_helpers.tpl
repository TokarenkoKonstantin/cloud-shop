{{/*
Общие labels по конвенции app.kubernetes.io/*
Добавляются в metadata всех объектов (но не в selector —
selector неизменяем после создания Deployment).
*/}}
{{- define "ecommerce.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: ecommerce
{{- end }}

{{/* Имя Secret: пользовательский existingSecret или собственный из чарта */}}
{{- define "ecommerce.postgresSecretName" -}}
{{- if .Values.postgres.auth.existingSecret -}}
{{- .Values.postgres.auth.existingSecret -}}
{{- else -}}
ecommerce-secrets
{{- end -}}
{{- end }}

{{/* Пароль обязателен, если не передан existingSecret */}}
{{- define "ecommerce.postgresPassword" -}}
{{- required "Задайте пароль БД: --set postgres.auth.password=<...> (или используйте postgres.auth.existingSecret)" .Values.postgres.auth.password -}}
{{- end }}
