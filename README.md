# Kubeadapt Helm Charts

This repository contains the Helm charts for deploying Kubeadapt into Kubernetes clusters:

- **kubeadapt** - Main chart. Deploys the Kubeadapt agent (cluster metrics collection), with an optional auto-upgrade sidecar and the optional eBPF network agent subchart.
- **kubeadapt-k8s-pulse** - Standalone chart for the eBPF network metrics DaemonSet. Usually installed as a dependency of the main chart, but can be deployed independently.

## Platform Support

The agent is a single Deployment that reads the Kubernetes API and the metrics API. It runs anywhere a normal pod runs, and by default it meets the Kubernetes **restricted** Pod Security Standard.

| Platform | Agent (`kubeadapt`) | Network agent (`kubeadapt-k8s-pulse`) |
|----------|---------------------|----------------------------------------|
| Amazon EKS (EC2 nodes) | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Amazon EKS on Fargate | Supported | Not supported (Fargate runs no DaemonSets) |
| Azure AKS | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Standard | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Autopilot | Supported | Not supported (no privileged pods) |
| Red Hat OpenShift / ROSA | Supported (see below) | Requires the `privileged` SCC |
| Self-managed (kubeadm, kops, Rancher, k3s, RKE2) | Supported, Kubernetes 1.24 - 1.35 | Supported |

The network agent needs Linux kernel 5.10 or newer on every node it runs on, and runs privileged with `hostNetwork` and `hostPID`. It is disabled by default.

**Requirements:**
- Kubernetes 1.24+
- Helm 3.0+
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) installed in the cluster. Without it, cost appears but CPU and memory usage, efficiency and rightsizing stay empty. EKS and kind/k3d do not install it by default.

See [COMPATIBILITY.md](COMPATIBILITY.md) for pricing support per cloud and the feature matrix.

## Installation

Get a token from [app.kubeadapt.io](https://app.kubeadapt.io) under **Clusters > Add cluster**.

**Recommended: keep the token in a Secret.** The token then never appears on a command line, in shell history or in `helm get values`.

```bash
kubectl create namespace kubeadapt
kubectl create secret generic kubeadapt-agent-token \
  --namespace kubeadapt \
  --from-literal=token='<your-token>'

helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update

helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token
```

The agent never writes the token Secret, so External Secrets Operator, Sealed Secrets or a GitOps sync can own it. When the agent replaces its token, it stores the new one in `kubeadapt-agent-rotated-token`, a Secret the chart creates empty. The agent has `get` and `update` on that one Secret, by name, through the `kubeadapt-agent-token` Role. Upgrades and auto-upgrades keep what the agent wrote there; `helm uninstall` deletes it.

**Quick try:**

```bash
helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token='<your-token>'
```

### OpenShift

The restricted-v2 SCC assigns the user and group from the namespace's range, so drop the chart's fixed IDs:

```bash
helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token \
  --set agent.podSecurityContext.runAsUser=null \
  --set agent.podSecurityContext.runAsGroup=null \
  --set agent.podSecurityContext.fsGroup=null
```

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

## Uninstalling

```bash
helm uninstall kubeadapt --namespace kubeadapt
```

This removes the agent Deployment, its Service, ServiceAccounts, the chart-created token Secret, Roles, ClusterRoles, their bindings and the SecureOps PriorityClass. It leaves behind:

- the `kubeadapt` namespace (Helm does not delete namespaces): `kubectl delete namespace kubeadapt`
- a token Secret you created yourself for `existingSecret`
- auto-upgrade Jobs that are still running; finished Jobs delete themselves after their TTL
- with SecureOps on, scan Jobs the agent had not removed yet, with the pull secret copies they own: `kubectl delete jobs -n kubeadapt -l kubeadapt.io/run-id` deletes both

Nothing is installed outside the release namespace except the cluster-scoped RBAC objects listed above and, with SecureOps on, its PriorityClass.

Then delete the cluster on the **Clusters** page in Kubeadapt, so its token stops working and it no longer shows as disconnected.

## Configuration

See [charts/kubeadapt/values.yaml](./charts/kubeadapt/values.yaml) for all configuration options.

Full documentation: [kubeadapt.io/docs/v1/configuration/overview](https://kubeadapt.io/docs/v1/configuration/overview/)

## Chart Signing & Verification

All Helm charts are GPG-signed. Signing key details:

- **Key ID:** 948AD9EDA6BD626E
- **Fingerprint:** 3C8109B607AD3E119B7033D8948AD9EDA6BD626E

See [SECURITY.md](SECURITY.md) for verification instructions and how to report vulnerabilities.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

Apache License 2.0. See [LICENSE](LICENSE).
