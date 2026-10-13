# kubeadapt

![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: v3.0.1](https://img.shields.io/badge/AppVersion-v3.0.1-informational?style=flat-square)

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

Recommended: keep the agent token in a Secret, so it never appears on a command line or in `helm get values`.

```console
kubectl create namespace kubeadapt
kubectl create secret generic kubeadapt-agent-token --namespace kubeadapt --from-literal=token='<your-token>'
helm install kubeadapt kubeadapt/kubeadapt --namespace kubeadapt --set agent.config.existingSecret=kubeadapt-agent-token
```

The agent pod meets the Kubernetes restricted Pod Security Standard by default. On OpenShift, add
`--set agent.podSecurityContext.runAsUser=null --set agent.podSecurityContext.runAsGroup=null --set agent.podSecurityContext.fsGroup=null`
so the restricted-v2 SCC can assign the user and group.

## Permissions

The agent's ClusterRole is read-only: `list` and `watch` on the resources it collects, `list` on the metrics API, and `get` on `nodes/stats`, which the kubelet maps to its stats endpoints only. It holds no `nodes/proxy` unless you set `agent.rbac.kubeletProxyFallback=true` for kubelets that self-sign their serving certificates; that grant is exec-capable, see `values.yaml`.

With `agent.autoUpgrade.enabled`, the upgrader sidecar (in the agent pod) gets a namespaced Role for its lock ConfigMap, the upgrade Job and Helm's release Secrets, and the upgrade Job runs under its own service account. The upgrader has no `escalate` or `bind`, so it can apply a release only if that release grants no permission it lacks; such a release needs a manual `helm upgrade`.

## Network Telemetry

`--set kubeadapt-k8s-pulse.enabled=true` deploys the network agent DaemonSet and connects it to the agent on port 9091 (`global.pulseChannel.port`). Every push carries a bearer token that the agent checks; the chart generates it into the Secret `<name>-pulse-token` on install and reuses it on upgrades. To rotate, delete the Secret, run `helm upgrade`, then restart the network agent DaemonSet.

**The channel is plaintext gRPC.** The token authenticates the network agent to the agent, but it travels unencrypted inside the cluster network, and so do the flow batches (pod IPs, DNS names, HTTP routes). Anything that can observe node or pod traffic can read both.

Rendering without cluster access (`helm template`, Argo CD) cannot see that Secret and would generate a new token each time. Create the Secret yourself with the key `token` and set `global.pulseChannel.existingSecret`.

`agent.networkPolicy.pulseFrom` limits port 9091 to the sources you list. Read its comment in `values.yaml` first: the network agent runs with `hostNetwork`, and a list that does not match it on your network plugin stops network telemetry.

The network agent image must be a release that sends the token without TLS (cut from pulse main after the TLS client was removed). Released v3.1.0 refuses to send a token without TLS.

## Uninstalling the Chart

```console
helm uninstall kubeadapt --namespace kubeadapt
```

The namespace and any token Secret you created yourself stay behind; delete them with `kubectl` if you no longer need them. Then delete the cluster on the **Clusters** page in Kubeadapt so its token stops working.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://ghcr.io/kubeadapt/kubeadapt-helm | kubeadapt-k8s-pulse | 1.1.0 |

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
| agent.autoUpgrade.image.repository | string | `"public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-upgrader"` |  |
| agent.autoUpgrade.image.tag | string | `"v3.0.2"` |  |
| agent.autoUpgrade.initialDelay | string | `"1m"` |  |
| agent.autoUpgrade.jobImage | string | `"alpine/helm:3.14.3"` |  |
| agent.autoUpgrade.policy | string | `"minor"` |  |
| agent.autoUpgrade.rbac.create | bool | `true` |  |
| agent.autoUpgrade.resources.limits.cpu | string | `"100m"` |  |
| agent.autoUpgrade.resources.limits.memory | string | `"128Mi"` |  |
| agent.autoUpgrade.resources.requests.cpu | string | `"10m"` |  |
| agent.autoUpgrade.resources.requests.memory | string | `"32Mi"` |  |
| agent.autoUpgrade.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| agent.autoUpgrade.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| agent.autoUpgrade.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| agent.autoUpgrade.serviceAccount.annotations | object | `{}` |  |
| agent.autoUpgrade.serviceAccount.create | bool | `true` |  |
| agent.autoUpgrade.serviceAccount.name | string | `""` |  |
| agent.autoUpgrade.timeout | string | `"15m"` |  |
| agent.config.backendUrl | string | `"https://ingest.kubeadapt.io"` |  |
| agent.config.bufferMaxBytes | string | `"52428800"` |  |
| agent.config.compressionLevel | int | `3` |  |
| agent.config.dcgmEndpoints | string | `""` |  |
| agent.config.dcgmNamespace | string | `""` |  |
| agent.config.dcgmPort | int | `9400` |  |
| agent.config.debugEndpoints | bool | `false` |  |
| agent.config.existingSecret | string | `""` |  |
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
| agent.image.repository | string | `"public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-agent"` |  |
| agent.image.tag | string | `"v3.0.1"` |  |
| agent.networkPolicy.pulseFrom | list | `[]` |  |
| agent.nodeSelector | object | `{}` |  |
| agent.podSecurityContext.fsGroup | int | `65532` |  |
| agent.podSecurityContext.runAsGroup | int | `65532` |  |
| agent.podSecurityContext.runAsNonRoot | bool | `true` |  |
| agent.podSecurityContext.runAsUser | int | `65532` |  |
| agent.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| agent.rbac.create | bool | `true` |  |
| agent.rbac.kubeletProxyFallback | bool | `false` |  |
| agent.resources.limits.cpu | string | `"2000m"` |  |
| agent.resources.limits.memory | string | `"16Gi"` |  |
| agent.resources.requests.cpu | string | `"100m"` |  |
| agent.resources.requests.memory | string | `"256Mi"` |  |
| agent.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| agent.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| agent.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| agent.service.type | string | `"ClusterIP"` |  |
| agent.serviceAccount.annotations | object | `{}` |  |
| agent.serviceAccount.create | bool | `true` |  |
| agent.serviceAccount.name | string | `""` |  |
| agent.spool.enabled | bool | `true` |  |
| agent.spool.maxBytes | string | `"1073741824"` |  |
| agent.spool.mountPath | string | `"/var/lib/kubeadapt"` |  |
| agent.spool.sizeLimit | string | `"2Gi"` |  |
| agent.terminationGracePeriodSeconds | int | `120` |  |
| agent.tmpVolume.sizeLimit | string | `"64Mi"` |  |
| agent.tolerations | list | `[]` |  |
| agent.topologySpreadConstraints | list | `[]` |  |
| global.fullnameOverride | string | `""` |  |
| global.name | string | `"kubeadapt"` |  |
| global.nameOverride | string | `""` |  |
| global.pulseChannel.existingSecret | string | `""` |  |
| global.pulseChannel.port | int | `9091` |  |
| kubeadapt-k8s-pulse.affinity | object | `{}` |  |
| kubeadapt-k8s-pulse.enabled | bool | `false` |  |
| kubeadapt-k8s-pulse.nodeSelector | object | `{}` |  |
| kubeadapt-k8s-pulse.tolerations | list | `[]` |  |
| kubeadapt-k8s-pulse.topologySpreadConstraints | list | `[]` |  |