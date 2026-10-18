# kubeadapt

![Version: 1.2.0](https://img.shields.io/badge/Version-1.2.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: v3.0.1](https://img.shields.io/badge/AppVersion-v3.0.1-informational?style=flat-square)

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

The agent replaces its token with a new one from time to time and writes it into the token Secret's `token` key, so every install has a `kubeadapt-agent-token` Role with `get` and `update` on that one Secret, by name. With `agent.config.existingSecret`, that is your Secret; the chart never writes it. If a tool such as External Secrets Operator, Sealed Secrets or a GitOps sync manages it, the tool can write its stored token back over the new one. Let it create the Secret once and leave it alone afterwards (External Secrets Operator: `refreshInterval: 0`), or keep your store updated from the Secret.

The agent pod meets the Kubernetes restricted Pod Security Standard by default. On OpenShift, add
`--set agent.podSecurityContext.runAsUser=null --set agent.podSecurityContext.runAsGroup=null --set agent.podSecurityContext.fsGroup=null`
so the restricted-v2 SCC can assign the user and group.

## SecureOps (optional)

SecureOps scans the images your cluster runs and reviews its security configuration. It needs permissions the agent does not have by default, so you grant them with one value, `secureops.enabled`, which is off by default:

```bash
helm upgrade kubeadapt kubeadapt/kubeadapt -n kubeadapt --reuse-values --set secureops.enabled=true
```

If the release was installed from an earlier chart version, use `--reset-then-reuse-values` (Helm 3.14+) instead of `--reuse-values`. `--reuse-values` keeps the earlier version's defaults, including its agent image. The chart detects this and stops with an error that says so, rather than grant permissions to an agent too old to use them.

Turning it on gives the agent's service account exactly this, in a ClusterRole and a Role named `kubeadapt-agent-secureops`:

| Permission | Where | Used for |
|---|---|---|
| `get` on Secrets | Whole cluster | Reading the image pull secrets your workloads reference, by name. No `list` or `watch`, so the agent cannot enumerate Secrets outside its own namespace. |
| `list` on Roles, ClusterRoles, RoleBindings, ClusterRoleBindings | Whole cluster | Reviewing who can do what, during a scan. |
| `list` on Gateways and HTTPRoutes (Gateway API) | Whole cluster | Finding workloads exposed outside the cluster, during a scan. The agent already lists Ingresses and NetworkPolicies. |
| `create` and `delete` on Secrets | The release namespace (`kubeadapt`) | A copy of a pull secret for one scan Job. The Job owns the copy, so Kubernetes deletes it with the Job. |

Scan Jobs run in the release namespace with the Job permissions the agent already has. The chart also creates:

- the `kubeadapt-secureops-scanner` service account that scan Jobs run as. It has no Kubernetes API token and no permissions.
- the `kubeadapt-secureops-scan` PriorityClass (value -10, `preemptionPolicy: Never`), so your workloads schedule first and a scan never preempts them. Set `secureops.priorityClass.create=false` and `secureops.priorityClass.name` to use an existing class.

With `agent.autoUpgrade.enabled`, the upgrader also holds the cluster-wide rules above, because Kubernetes lets it update the agent's binding only if it holds them. It may also create PriorityClasses, and update or delete the SecureOps one.

**Private registries.** The scanner first uses the pull secret a workload references. Where nodes pull with their own cloud identity and no pull secret exists, give the scanner service account an identity of its own:

| Cloud | Value | What the identity needs |
|---|---|---|
| Amazon EKS, IAM roles for service accounts | `secureops.scanner.cloudIdentity.aws.roleArn` | `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer` |
| Amazon EKS Pod Identity | none: create a Pod Identity association for `kubeadapt-secureops-scanner` in namespace `kubeadapt` | The same three ECR actions |
| Google GKE, Workload Identity | `secureops.scanner.cloudIdentity.gcp.serviceAccount` | `roles/artifactregistry.reader` |
| Azure AKS, Workload Identity | `secureops.scanner.cloudIdentity.azure.clientId` (scan pods also get the `azure.workload.identity/use: "true"` label) | `AcrPull` |

**Scan Jobs.** `secureops.scanner` sets their resources (200m CPU and 256Mi requested, 768Mi limit), scratch volume (`scratchSizeLimit`, 4Gi), how many run at once (`concurrency`, 2, at most 8), the deadline per Job (`jobDeadline`, 15m), `tolerations` and `nodeSelector`. The scanner image is pinned by digest.

To revoke, set `secureops.enabled=false` the same way. The chart removes the roles, bindings, service account and PriorityClass.

## Uninstalling the Chart

```console
helm uninstall kubeadapt --namespace kubeadapt
```

The namespace and any token Secret you created yourself stay behind; delete them with `kubectl` if you no longer need them. With SecureOps on, so do scan Jobs the agent had not removed yet and the pull secret copies they own: `kubectl delete jobs -n kubeadapt -l kubeadapt.io/run-id` deletes both. Then delete the cluster on the **Clusters** page in Kubeadapt so its token stops working.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://ghcr.io/kubeadapt/kubeadapt-helm | kubeadapt-k8s-pulse | 1.0.1 |

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
| agent.nodeSelector | object | `{}` |  |
| agent.podSecurityContext.fsGroup | int | `65532` |  |
| agent.podSecurityContext.runAsGroup | int | `65532` |  |
| agent.podSecurityContext.runAsNonRoot | bool | `true` |  |
| agent.podSecurityContext.runAsUser | int | `65532` |  |
| agent.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| agent.rbac.create | bool | `true` |  |
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
| agent.tmpVolume.sizeLimit | string | `"64Mi"` |  |
| agent.tolerations | list | `[]` |  |
| agent.topologySpreadConstraints | list | `[]` |  |
| global.fullnameOverride | string | `""` |  |
| global.name | string | `"kubeadapt"` |  |
| global.nameOverride | string | `""` |  |
| kubeadapt-k8s-pulse.affinity | object | `{}` |  |
| kubeadapt-k8s-pulse.enabled | bool | `false` |  |
| kubeadapt-k8s-pulse.nodeSelector | object | `{}` |  |
| kubeadapt-k8s-pulse.tolerations | list | `[]` |  |
| kubeadapt-k8s-pulse.topologySpreadConstraints | list | `[]` |  |
| secureops.enabled | bool | `false` |  |
| secureops.priorityClass.create | bool | `true` |  |
| secureops.priorityClass.name | string | `""` |  |
| secureops.scanner.cloudIdentity.aws.roleArn | string | `""` |  |
| secureops.scanner.cloudIdentity.azure.clientId | string | `""` |  |
| secureops.scanner.cloudIdentity.gcp.serviceAccount | string | `""` |  |
| secureops.scanner.concurrency | int | `2` |  |
| secureops.scanner.image.digest | string | `"sha256:0000000000000000000000000000000000000000000000000000000000000000"` |  |
| secureops.scanner.image.repository | string | `"public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-scanner"` |  |
| secureops.scanner.jobDeadline | string | `"15m"` |  |
| secureops.scanner.nodeSelector | object | `{}` |  |
| secureops.scanner.resources.limits.memory | string | `"768Mi"` |  |
| secureops.scanner.resources.requests.cpu | string | `"200m"` |  |
| secureops.scanner.resources.requests.memory | string | `"256Mi"` |  |
| secureops.scanner.scratchSizeLimit | string | `"4Gi"` |  |
| secureops.scanner.tolerations | list | `[]` |  |