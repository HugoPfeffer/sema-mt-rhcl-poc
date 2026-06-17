{{- define "rbac-poc.name" -}}rbac-sample-api{{- end -}}

{{/*
Resolve the container image: an explicit repository if provided, otherwise the
internal-registry image produced by the in-cluster BuildConfig.
*/}}
{{- define "rbac-poc.image" -}}
{{- if .Values.image.repository -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- else -}}
image-registry.openshift-image-registry.svc:5000/{{ .Release.Namespace }}/{{ include "rbac-poc.name" . }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}

{{- define "rbac-poc.labels" -}}
app: {{ include "rbac-poc.name" . }}
app.kubernetes.io/name: {{ include "rbac-poc.name" . }}
app.kubernetes.io/part-of: rhcl-rbac-poc
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
