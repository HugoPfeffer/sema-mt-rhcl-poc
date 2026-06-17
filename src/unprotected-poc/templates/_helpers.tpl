{{- define "unprotected-poc.name" -}}unprotected-sample-api{{- end -}}

{{/*
Resolve the container image: an explicit repository if provided, otherwise the
internal-registry image produced by the in-cluster BuildConfig.
*/}}
{{- define "unprotected-poc.image" -}}
{{- if .Values.image.repository -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- else -}}
image-registry.openshift-image-registry.svc:5000/{{ .Release.Namespace }}/{{ include "unprotected-poc.name" . }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}

{{- define "unprotected-poc.labels" -}}
app: {{ include "unprotected-poc.name" . }}
app.kubernetes.io/name: {{ include "unprotected-poc.name" . }}
app.kubernetes.io/part-of: rhcl-unprotected-poc
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
