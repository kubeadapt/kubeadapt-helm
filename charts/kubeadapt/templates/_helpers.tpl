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
Rules of the agent ClusterRole.

The upgrader ClusterRole includes the same list: it has no `escalate`, so the
API server lets it write the agent ClusterRole only while it holds every
permission in it. One definition keeps the two from drifting apart.

Every rule is read-only and matches an informer or client call in the agent.
*/}}
{{- define "kubeadapt.agent.clusterRules" -}}
- apiGroups: [""]
  resources:
    - nodes
    - namespaces
    - persistentvolumes
    - services
  verbs: ["list", "watch"]

- apiGroups: [""]
  resources:
    - pods
    - persistentvolumeclaims
    - resourcequotas
    - limitranges
  verbs: ["list", "watch"]

- apiGroups: ["apps"]
  resources:
    - deployments
    - replicasets
    - statefulsets
    - daemonsets
  verbs: ["list", "watch"]

- apiGroups: ["batch"]
  resources:
    - jobs
    - cronjobs
  verbs: ["list", "watch"]

- apiGroups: ["autoscaling"]
  resources:
    - horizontalpodautoscalers
  verbs: ["list", "watch"]

- apiGroups: ["policy"]
  resources:
    - poddisruptionbudgets
  verbs: ["list", "watch"]

- apiGroups: ["networking.k8s.io"]
  resources:
    - ingresses
  verbs: ["list", "watch"]

# The Kubernetes API server Service has no selector, so it publishes no
# Endpoints through any other resource: EndpointSlices are the only way to
# learn which addresses belong to it. Without this rule the agent's service
# informer never syncs, every Service-owned address falls back to
# `__unresolved__`, and API-server traffic is billed as an external domain.
- apiGroups: ["discovery.k8s.io"]
  resources:
    - endpointslices
  verbs: ["list", "watch"]

- apiGroups: ["storage.k8s.io"]
  resources:
    - storageclasses
  verbs: ["list", "watch"]

- apiGroups: ["scheduling.k8s.io"]
  resources:
    - priorityclasses
  verbs: ["list", "watch"]

# Metrics API (requires metrics-server). The agent lists on a timer;
# metrics.k8s.io serves no watch, so the verb is "list" alone.
- apiGroups: ["metrics.k8s.io"]
  resources:
    - pods
    - nodes
  verbs: ["list"]

# kubelet /stats/summary - the only source of per-pod network bytes.
# metrics.k8s.io above carries CPU and memory and nothing else.
#
# The agent reads it straight from each kubelet on port 10250 and verifies the
# kubelet's serving certificate against the cluster CA. The kubelet authorises
# /stats/* as `nodes/stats` and nothing else as `nodes/stats`, so this grant
# reaches the stats endpoints only: no exec, attach, port-forward, run or logs.
- apiGroups: [""]
  resources:
    - nodes/stats
  verbs: ["get"]
{{- if .Values.agent.rbac.kubeletProxyFallback }}

# agent.rbac.kubeletProxyFallback: the API server's node proxy, for kubelets
# whose serving certificate does not chain to the cluster CA (self-signed,
# serverTLSBootstrap off). This grant is EXEC-CAPABLE. The kubelet authorises
# exec, attach, port-forward and run as `nodes/proxy`, and a WebSocket upgrade
# is an HTTP GET, so "get" on nodes/proxy lets the holder of the agent's token
# run commands in every pod on every node. RBAC cannot narrow it to
# /stats/summary.
- apiGroups: [""]
  resources:
    - nodes/proxy
  verbs: ["get"]
{{- end }}

# VPA (optional, if installed)
- apiGroups: ["autoscaling.k8s.io"]
  resources:
    - verticalpodautoscalers
  verbs: ["list", "watch"]

# Karpenter (optional, if installed)
- apiGroups: ["karpenter.sh"]
  resources:
    - nodepools
  verbs: ["list", "watch"]
{{- end }}

{{/*
"true" when the kubeadapt-k8s-pulse subchart is enabled, "" otherwise.
*/}}
{{- define "kubeadapt.pulse.enabled" -}}
{{- if (index .Values "kubeadapt-k8s-pulse" | default dict).enabled -}}true{{- end -}}
{{- end }}

{{/*
Secret holding the pulse -> agent bearer token (key "token"): the user's
global.pulseChannel.existingSecret, or the one this chart generates. The
kubeadapt-k8s-pulse subchart derives the same name from the same values.
*/}}
{{- define "kubeadapt.pulseChannel.secretName" -}}
{{- default (printf "%s-pulse-token" (include "kubeadapt.name" .)) .Values.global.pulseChannel.existingSecret -}}
{{- end }}

{{/*
The generated bearer token, base64-encoded.

Generated once per render and cached, because the Secret and the agent's
checksum annotation both need it and every randAlphaNum call returns a new
value. On an upgrade the Secret already in the cluster is reused, so the token
stays put; a render without cluster access (helm template, Argo CD) cannot see
it and generates a new one, which is why global.pulseChannel.existingSecret
exists.
*/}}
{{- define "kubeadapt.pulseChannel.token" -}}
{{- if not (hasKey .Values "__kubeadaptPulseToken") -}}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace (include "kubeadapt.pulseChannel.secretName" .)) | default dict -}}
{{- $token := get ((get $existing "data") | default dict) "token" -}}
{{- $_ := set .Values "__kubeadaptPulseToken" (default (randAlphaNum 64 | b64enc) $token) -}}
{{- end -}}
{{- get .Values "__kubeadaptPulseToken" -}}
{{- end }}
