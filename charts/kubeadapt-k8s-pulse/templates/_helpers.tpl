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
Where flow batches are sent.

Defaults to the agent Service the kubeadapt umbrella chart installs, in this
release's namespace. The port comes from the umbrella's global value so the
listener and the sender cannot be configured apart.
*/}}
{{- define "kubeadapt-k8s-pulse.agentEndpoint" -}}
{{- if .Values.config.export.agentEndpoint -}}
{{- .Values.config.export.agentEndpoint -}}
{{- else -}}
{{- $global := .Values.global | default dict -}}
{{- $name := default "kubeadapt" $global.nameOverride -}}
{{- printf "%s-agent.%s.svc.cluster.local:%v" $name .Release.Namespace (default 9091 $global.pulseListenPort) -}}
{{- end -}}
{{- end }}

{{/*
Name of the ClusterRole and ClusterRoleBinding.

Cluster-scoped objects have no namespace, so the release namespace is part of
the name: two installs in different namespaces would otherwise claim the same
ClusterRole and the second install would fail.
*/}}
{{- define "kubeadapt-k8s-pulse.clusterRoleName" -}}
{{- printf "%s-%s" (include "kubeadapt-k8s-pulse.fullname" .) .Release.Namespace | trunc 63 | trimSuffix "-" }}
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
