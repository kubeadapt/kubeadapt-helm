{{/*
Expand the name of the chart.
*/}}
{{- define "kubeadapt.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubeadapt.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
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
{{- define "kubeadapt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubeadapt.labels" -}}
helm.sh/chart: {{ include "kubeadapt.chart" . }}
{{ include "kubeadapt.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubeadapt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeadapt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Suffix appended to cluster-scoped resource names (ClusterRole, ClusterRoleBinding)
so multiple chart installs in different namespaces don't collide on the cluster-wide
namespace. Cluster-scoped resources have no namespace and would otherwise share a
single global name across all installs.

Behaviour:
  - When .Release.Namespace == kubeadapt.name (the chart's default namespace),
    returns "" → resource names stay unchanged for backward compatibility with
    existing installs (no resource renames on `helm upgrade`).
  - Otherwise returns "-<release-namespace>" so each install in a non-default
    namespace gets a unique cluster-scoped resource name.
*/}}
{{- define "kubeadapt.clusterResourceSuffix" -}}
{{- if ne .Release.Namespace (include "kubeadapt.name" .) -}}
-{{ .Release.Namespace }}
{{- end -}}
{{- end }}

{{/*
"true" when the network monitor is deployed and sends to this release's agent:
the agent's listener, its Service and the shared token exist only then.
*/}}
{{- define "kubeadapt.pulseConnected" -}}
{{- $pulse := index .Values "kubeadapt-k8s-pulse" | default dict -}}
{{- if and .Values.agent.enabled $pulse.enabled (dig "config" "export" "enabled" false $pulse) -}}
true
{{- end -}}
{{- end }}

{{/*
Secret holding the token the network monitor presents to the agent. The
kubeadapt-k8s-pulse chart derives the same default name.
*/}}
{{- define "kubeadapt.pulseTokenSecretName" -}}
{{- .Values.global.pulse.existingSecret | default (printf "%s-pulse-token" (include "kubeadapt.name" .)) -}}
{{- end }}

{{/*
Name of the kubeadapt-k8s-pulse ClusterRole, derived as that chart derives it.
*/}}
{{- define "kubeadapt.pulseClusterRoleName" -}}
{{- $pulse := index .Values "kubeadapt-k8s-pulse" | default dict -}}
{{- $full := "" -}}
{{- if $pulse.fullnameOverride -}}
{{- $full = $pulse.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "kubeadapt-k8s-pulse" $pulse.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- $full = .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $full = printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- printf "%s-%s" $full .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end }}
