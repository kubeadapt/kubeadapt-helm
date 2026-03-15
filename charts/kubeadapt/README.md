# kubeadapt

![Version: 0.18.3](https://img.shields.io/badge/Version-0.18.3-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for Kubeadapt

## Prerequisites

- Kubernetes 1.24+
- Helm 3.0.0+
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) installed in the cluster (required for resource metrics collection)

## Get Repo Info

```console
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update
```

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release kubeadapt/kubeadapt
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://ghcr.io/kubeadapt/kubeadapt-helm | ebpf-agent | 0.2.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.affinity | object | `{}` |  |
| agent.autoUpgrade.channel | string | `"fast"` |  |
| agent.autoUpgrade.chartRepo | string | `""` |  |
| agent.autoUpgrade.checkInterval | string | `"24h"` |  |
| agent.autoUpgrade.dryRun | bool | `false` |  |
| agent.autoUpgrade.enabled | bool | `false` |  |
| agent.autoUpgrade.image.pullPolicy | string | `"IfNotPresent"` |  |
| agent.autoUpgrade.image.repository | string | `"public.ecr.aws/w3l5x6r6/kubeadapt/app/kubeadapt-upgrader"` |  |
| agent.autoUpgrade.image.tag | string | `"v0.1.1"` |  |
| agent.autoUpgrade.initialDelay | string | `"1m"` |  |
| agent.autoUpgrade.jobImage | string | `"alpine/helm:3.14.3"` |  |
| agent.autoUpgrade.policy | string | `"minor"` |  |
| agent.autoUpgrade.rbac.create | bool | `true` |  |
| agent.autoUpgrade.resources.limits.cpu | string | `"100m"` |  |
| agent.autoUpgrade.resources.limits.memory | string | `"128Mi"` |  |
| agent.autoUpgrade.resources.requests.cpu | string | `"10m"` |  |
| agent.autoUpgrade.resources.requests.memory | string | `"32Mi"` |  |
| agent.autoUpgrade.serviceAccount.annotations | object | `{}` |  |
| agent.autoUpgrade.serviceAccount.create | bool | `true` |  |
| agent.autoUpgrade.serviceAccount.name | string | `""` |  |
| agent.autoUpgrade.timeout | string | `"15m"` |  |
| agent.config.backendUrl | string | `"https://agent.kubeadapt.io"` |  |
| agent.config.bufferMaxBytes | string | `"52428800"` |  |
| agent.config.compressionLevel | int | `3` |  |
| agent.config.dcgmEndpoints | string | `""` |  |
| agent.config.dcgmNamespace | string | `""` |  |
| agent.config.dcgmPort | int | `9400` |  |
| agent.config.debugEndpoints | bool | `false` |  |
| agent.config.gpuMetricsEnabled | bool | `true` |  |
| agent.config.healthPort | int | `8080` |  |
| agent.config.informerResync | string | `"300s"` |  |
| agent.config.maxRetries | int | `5` |  |
| agent.config.metricsInterval | string | `"60s"` |  |
| agent.config.requestTimeout | string | `"30s"` |  |
| agent.config.snapshotInterval | string | `"60s"` |  |
| agent.config.token | string | `""` |  |
| agent.enabled | bool | `true` |  |
| agent.env | list | `[]` |  |
| agent.image.pullPolicy | string | `"IfNotPresent"` |  |
| agent.image.repository | string | `"public.ecr.aws/w3l5x6r6/kubeadapt/app/kubeadapt-agent"` |  |
| agent.image.tag | string | `"v2.0.1"` |  |
| agent.nodeSelector | object | `{}` |  |
| agent.rbac.create | bool | `true` |  |
| agent.resources.limits.cpu | string | `"1000m"` |  |
| agent.resources.limits.memory | string | `"1Gi"` |  |
| agent.resources.requests.cpu | string | `"100m"` |  |
| agent.resources.requests.memory | string | `"128Mi"` |  |
| agent.service.type | string | `"ClusterIP"` |  |
| agent.serviceAccount.annotations | object | `{}` |  |
| agent.serviceAccount.create | bool | `true` |  |
| agent.serviceAccount.name | string | `""` |  |
| agent.tolerations | list | `[]` |  |
| agent.topologySpreadConstraints | list | `[]` |  |
| ebpf-agent.affinity | object | `{}` |  |
| ebpf-agent.enabled | bool | `false` |  |
| ebpf-agent.nodeSelector | object | `{}` |  |
| ebpf-agent.tolerations | list | `[]` |  |
| ebpf-agent.topologySpreadConstraints | list | `[]` |  |
| global.fullnameOverride | string | `""` |  |
| global.name | string | `"kubeadapt"` |  |
| global.nameOverride | string | `""` |  |