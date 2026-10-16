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
Create the name of the service account to use
*/}}
{{- define "kubeadapt-k8s-pulse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubeadapt-k8s-pulse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Where pulse sends flow batches. Empty means export is off.

An explicit config.export.agentEndpoint wins. Otherwise, when installed by the
kubeadapt chart (which sets global.pulseChannel), it is that chart's agent
Service in this namespace, on the port the agent listens on. The name has no
cluster domain, so it resolves through the pod's DNS search path on any
cluster.
*/}}
{{- define "kubeadapt-k8s-pulse.agentEndpoint" -}}
{{- $global := .Values.global | default dict -}}
{{- if .Values.config.export.agentEndpoint -}}
{{- .Values.config.export.agentEndpoint -}}
{{- else if $global.pulseChannel -}}
{{- $name := default "kubeadapt" $global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- printf "%s-agent.%s.svc:%v" $name .Release.Namespace $global.pulseChannel.port -}}
{{- end -}}
{{- end }}

{{/*
Secret holding the bearer token the agent checks on every push, under the key
"token". Empty means pulse sends no token.

An explicit config.export.tokenSecret wins. Otherwise, under the kubeadapt
chart, it is the Secret that chart generates, or the one named by
global.pulseChannel.existingSecret.
*/}}
{{- define "kubeadapt-k8s-pulse.tokenSecret" -}}
{{- $global := .Values.global | default dict -}}
{{- if .Values.config.export.tokenSecret -}}
{{- .Values.config.export.tokenSecret -}}
{{- else if $global.pulseChannel -}}
{{- $name := default "kubeadapt" $global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- default (printf "%s-pulse-token" $name) $global.pulseChannel.existingSecret -}}
{{- end -}}
{{- end }}

{{/*
Name of the ClusterRole and ClusterRoleBinding. Cluster-scoped objects have no
namespace, so the release namespace is part of the name: two installs in
different namespaces would otherwise claim the same ClusterRole.
*/}}
{{- define "kubeadapt-k8s-pulse.clusterRoleName" -}}
{{- printf "%s-%s" (include "kubeadapt-k8s-pulse.fullname" .) .Release.Namespace | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Rules of the ClusterRole. Every call the DaemonSet makes to the Kubernetes API
is a read. The kubeadapt chart's upgrader includes this list too, since it
must hold a permission to write it.
*/}}
{{- define "kubeadapt-k8s-pulse.clusterRules" -}}
# Pod identity: a node-scoped pod informer (field selector
# spec.nodeName=<this node>). RBAC cannot narrow a rule by field selector, so
# the grant is cluster-wide although each pod reads only its own node's pods.
# Without it the informer never syncs and flows carry no pod identity.
- apiGroups: [""]
  resources:
    - pods
  verbs: ["list", "watch"]

# Node identity: one Get of this pod's own Node at startup, for its UID and
# topology zone.
- apiGroups: [""]
  resources:
    - nodes
  verbs: ["get"]

# L7 detector: one List of CiliumEnvoyConfig at startup, to tell whether an
# Envoy dataplane hides backend pod IPs. Matches nothing without Cilium.
- apiGroups: ["cilium.io"]
  resources:
    - ciliumenvoyconfigs
  verbs: ["list"]
{{- end }}
