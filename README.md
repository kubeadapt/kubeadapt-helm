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

The network agent needs Linux kernel 5.10 or newer on every node it runs on, and runs privileged with `hostNetwork` and `hostPID`. It is disabled by default. When enabled, it sends flows to the agent over plaintext gRPC with a chart-generated bearer token; the token and the flows travel unencrypted inside the cluster network.

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

## Uninstalling

```bash
helm uninstall kubeadapt --namespace kubeadapt
```

This removes the agent Deployment, its Service, ServiceAccounts, the chart-created token Secret, Roles, ClusterRoles and their bindings. It leaves behind:

- the `kubeadapt` namespace (Helm does not delete namespaces): `kubectl delete namespace kubeadapt`
- a token Secret you created yourself for `existingSecret`
- auto-upgrade Jobs that are still running; finished Jobs delete themselves after their TTL

Nothing is installed outside the release namespace except the cluster-scoped RBAC objects listed above.

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
