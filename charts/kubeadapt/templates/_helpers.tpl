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
Get cluster name
If not provided in values.yaml, generates a name using release name: <release-name>-cluster
Example: If release name is "prod", default will be "prod-cluster"
*/}}
{{- define "kubeadapt.clusterName" -}}
{{- $defaultClusterName := printf "%s-cluster" .Release.Name -}}
{{- default $defaultClusterName .Values.global.clusterName }}
{{- end }}

{{/*
Get cluster ID
If not provided in values.yaml, generates an ID using release name and namespace: <release-name>-<namespace>
Example: If release is "prod" in "monitoring" namespace, default will be "prod-monitoring"
*/}}
{{- define "kubeadapt.clusterId" -}}
{{- $defaultClusterId := printf "%s-%s" .Release.Name .Release.Namespace -}}
{{- default $defaultClusterId .Values.global.clusterId }}
{{- end }}

{{/*
Get environment
If not provided in values.yaml, defaults to the namespace name or "development" if namespace matches "default"
*/}}
{{- define "kubeadapt.environment" -}}
{{- $defaultEnv := "development" -}}
{{- if ne .Release.Namespace "default" -}}
{{- $defaultEnv = .Release.Namespace -}}
{{- end -}}
{{- default $defaultEnv .Values.global.environment }}
{{- end }}

{{/*
Get region
If not provided in values.yaml, attempts to extract from release name (format: <region>-<env>) or defaults to "unknown"
Example: If release name is "eu-west-1-prod", default will be "eu-west-1"
*/}}
{{- define "kubeadapt.region" -}}
{{- $defaultRegion := "unknown" -}}
{{- if contains "-" .Release.Name -}}
{{- $parts := splitList "-" .Release.Name -}}
{{- if gt (len $parts) 2 -}}
{{- $defaultRegion = printf "%s-%s-%s" (index $parts 0) (index $parts 1) (index $parts 2) -}}
{{- end -}}
{{- end -}}
{{- default $defaultRegion .Values.global.region }}
{{- end }}

{{/*
Get agent token
If not provided in values.yaml, generates a token using release info: <release-name>-<namespace>-token
This should only be used for development/testing. Production should always provide a real token.
*/}}
{{- define "kubeadapt.agentToken" -}}
{{- $defaultToken := printf "%s-%s-token" .Release.Name .Release.Namespace -}}
{{- default $defaultToken .Values.agent.config.token }}
{{- end }} 