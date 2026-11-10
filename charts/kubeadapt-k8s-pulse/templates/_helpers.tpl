{{/*
Expand the name of the chart.
*/}}
{{- define "kubeadapt-k8s-pulse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kubeadapt-k8s-pulse.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubeadapt-k8s-pulse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubeadapt-k8s-pulse.labels" -}}
helm.sh/chart: {{ include "kubeadapt-k8s-pulse.chart" . }}
{{ include "kubeadapt-k8s-pulse.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubeadapt-k8s-pulse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeadapt-k8s-pulse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: kubeadapt-k8s-pulse
{{- end }}

{{/*
Base name of the kubeadapt chart's objects in this namespace, used for the
default agent endpoint and token Secret.
*/}}
{{- define "kubeadapt-k8s-pulse.parentName" -}}
{{- $global := .Values.global | default dict -}}
{{- default "kubeadapt" $global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Agent listener the traffic records are sent to.
*/}}
{{- define "kubeadapt-k8s-pulse.agentEndpoint" -}}
{{- if .Values.config.export.agentEndpoint -}}
{{- .Values.config.export.agentEndpoint -}}
{{- else -}}
{{- $pulse := (.Values.global | default dict).pulse | default dict -}}
{{- printf "%s-agent-pulse.%s.svc:%v" (include "kubeadapt-k8s-pulse.parentName" .) .Release.Namespace (default 9091 $pulse.listenPort) -}}
{{- end -}}
{{- end }}

{{/*
Secret holding the token presented to the agent.
*/}}
{{- define "kubeadapt-k8s-pulse.tokenSecretName" -}}
{{- $pulse := (.Values.global | default dict).pulse | default dict -}}
{{- coalesce .Values.config.export.tokenSecret $pulse.existingSecret (printf "%s-pulse-token" (include "kubeadapt-k8s-pulse.parentName" .)) -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubeadapt-k8s-pulse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubeadapt-k8s-pulse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
