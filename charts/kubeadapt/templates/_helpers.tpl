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
The Secret holding the agent token, key "token": agent.config.existingSecret
when set, else the chart's own <name>-agent.
*/}}
{{- define "kubeadapt.agentTokenSecretName" -}}
{{- .Values.agent.config.existingSecret | default (printf "%s-agent" (include "kubeadapt.name" .)) -}}
{{- end }}

{{/*
"true" when the customer granted the SecureOps opt-in (secureops.enabled) and
the agent is enabled, "" otherwise.

The flag is read nil-safe: `helm upgrade --reuse-values` replaces this chart's
defaults with those of the chart version the release was installed from, so a
release from a version before SecureOps has no secureops key at all. With the
opt-in on but the defaults missing, the render stops with the fix rather than
granting permissions to an agent image too old to use them (--reuse-values
keeps the old agent image as well).
*/}}
{{- define "kubeadapt.secureops.enabled" -}}
{{- $so := .Values.secureops | default dict -}}
{{- if and .Values.agent.enabled (dig "enabled" false $so) -}}
{{- if not (dig "scanner" "image" "repository" "" $so) -}}
{{- fail "secureops.enabled is set, but this release has none of the chart's SecureOps defaults. `helm upgrade --reuse-values` keeps the values, and the agent image, of the chart version the release was installed from. Run the same upgrade with --reset-then-reuse-values (Helm 3.14 or newer) instead of --reuse-values." -}}
{{- end -}}
true
{{- end -}}
{{- end }}

{{/*
Names of the SecureOps objects. Cluster-scoped ones carry the namespace
suffix, like the agent's ClusterRole.
*/}}
{{- define "kubeadapt.secureops.rbacName" -}}
{{- include "kubeadapt.name" . }}-agent-secureops
{{- end }}

{{- define "kubeadapt.secureops.scannerServiceAccountName" -}}
{{- include "kubeadapt.name" . }}-secureops-scanner
{{- end }}

{{/*
PriorityClass for scan Jobs: the chart's own when priorityClass.create, else
the existing class named in priorityClass.name, else "" (none).
*/}}
{{- define "kubeadapt.secureops.priorityClassName" -}}
{{- $pc := .Values.secureops.priorityClass -}}
{{- if $pc.create -}}
{{- $pc.name | default (printf "%s-secureops-scan%s" (include "kubeadapt.name" .) (include "kubeadapt.clusterResourceSuffix" .)) -}}
{{- else -}}
{{- $pc.name -}}
{{- end -}}
{{- end }}

{{/*
Agent environment for SecureOps. Every value here is the customer's own chart
configuration; the agent never takes an image or a schedule from the server.
*/}}
{{- define "kubeadapt.secureops.env" -}}
{{- $s := .Values.secureops.scanner -}}
{{- $digest := toString $s.image.digest -}}
{{- if not (regexMatch "^sha256:[a-f0-9]{64}$" $digest) -}}
{{- fail (printf "secureops.scanner.image.digest must be sha256:<64 hex characters>, got %q" $digest) -}}
{{- end -}}
{{- $concurrency := int $s.concurrency -}}
{{- if or (lt $concurrency 1) (gt $concurrency 8) -}}
{{- fail (printf "secureops.scanner.concurrency must be 1 to 8, got %v" $s.concurrency) -}}
{{- end -}}
{{- $nodeSelector := dict -}}
{{- range $k, $v := $s.nodeSelector -}}
{{- $_ := set $nodeSelector $k (toString $v) -}}
{{- end -}}
{{- $podLabels := dict -}}
{{- if $s.cloudIdentity.azure.clientId -}}
{{- $_ := set $podLabels "azure.workload.identity/use" "true" -}}
{{- end -}}
- name: KUBEADAPT_SECUREOPS_SCANNER_IMAGE
  value: {{ printf "%s@%s" (required "secureops.scanner.image.repository must be set" $s.image.repository) $digest | quote }}
- name: KUBEADAPT_SECUREOPS_SCANNER_SERVICE_ACCOUNT
  value: {{ include "kubeadapt.secureops.scannerServiceAccountName" . | quote }}
- name: KUBEADAPT_SECUREOPS_SCANNER_RESOURCES
  value: {{ $s.resources | default dict | toJson | quote }}
- name: KUBEADAPT_SECUREOPS_SCANNER_SCRATCH_SIZE_LIMIT
  value: {{ required "secureops.scanner.scratchSizeLimit must be set" $s.scratchSizeLimit | toString | quote }}
- name: KUBEADAPT_SECUREOPS_JOB_CONCURRENCY
  value: {{ $concurrency | quote }}
- name: KUBEADAPT_SECUREOPS_JOB_DEADLINE
  value: {{ required "secureops.scanner.jobDeadline must be set" $s.jobDeadline | toString | quote }}
{{- with include "kubeadapt.secureops.priorityClassName" . }}
- name: KUBEADAPT_SECUREOPS_JOB_PRIORITY_CLASS_NAME
  value: {{ . | quote }}
{{- end }}
- name: KUBEADAPT_SECUREOPS_JOB_TOLERATIONS
  value: {{ $s.tolerations | default list | toJson | quote }}
- name: KUBEADAPT_SECUREOPS_JOB_NODE_SELECTOR
  value: {{ $nodeSelector | toJson | quote }}
- name: KUBEADAPT_SECUREOPS_JOB_POD_LABELS
  value: {{ $podLabels | toJson | quote }}
{{- end }}
