# Kubeadapt Helm Charts

This repository contains the Helm charts for deploying Kubeadapt into Kubernetes clusters:

- **kubeadapt** - Main chart. Deploys the Kubeadapt agent (cluster metrics collection), with an optional auto-upgrade sidecar and the optional network monitor subchart.
- **kubeadapt-k8s-pulse** - The network monitor: an eBPF DaemonSet that measures each pod's network traffic and sends it to the agent. Usually installed through the main chart, but can be deployed on its own.

## Platform Support

The agent is a single Deployment that reads the Kubernetes API and the metrics API. It runs anywhere a normal pod runs, and by default it meets the Kubernetes **restricted** Pod Security Standard.

| Platform | Agent (`kubeadapt`) | Network monitor (`kubeadapt-k8s-pulse`) |
|----------|---------------------|----------------------------------------|
| Amazon EKS (EC2 nodes) | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Amazon EKS on Fargate | Supported | Not supported (Fargate runs no DaemonSets) |
| Azure AKS | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Standard | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Autopilot | Supported | Not supported (no host network or added capabilities) |
| Red Hat OpenShift / ROSA | Supported (see below) | Requires the `privileged` SCC |
| Self-managed (kubeadm, kops, Rancher, k3s, RKE2) | Supported, Kubernetes 1.24 - 1.35 | Supported |

The network monitor needs Linux kernel 5.10 or newer on every node it runs on, the node's network namespace and a small set of Linux capabilities. It is disabled by default. See [Network monitoring](#network-monitoring).

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

### Network monitoring

The network monitor (`kubeadapt-k8s-pulse`) is off by default. To turn it on:

```bash
helm upgrade --install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token \
  --set kubeadapt-k8s-pulse.enabled=true
```

The agent then listens for the DaemonSet on port 9091 behind the `kubeadapt-agent-pulse` ClusterIP Service, and accepts traffic records only from a sender that presents a shared token. The chart creates that token in the `kubeadapt-pulse-token` Secret on first install and keeps it on every upgrade. To use your own, create a Secret with the token under the key `token` and set `global.pulse.existingSecret` to its name. Do this as well when you deploy with a tool that renders the chart without cluster access, such as Argo CD; otherwise each render creates a new token. To rotate the token, change the Secret: both pods read it again while running.

What the DaemonSet needs on each node:

- Linux kernel 5.10 or newer
- the node's network namespace (`hostNetwork`)
- the Linux capabilities `BPF`, `PERFMON` and `NET_ADMIN`, plus `SYS_RESOURCE` on kernels older than 5.11 and `SYS_PTRACE` for the container runtime inventory; every other capability is dropped, privilege escalation is off and the root filesystem is read-only
- read-only access to the node's `/proc`, cgroup tree, CNI configuration (`/etc/cni/net.d`) and Istio ztunnel directory (`/var/run/ztunnel`), and write access to the BPF filesystem (`/sys/fs/bpf`)
- read-only Kubernetes API access: list and watch pods, get nodes, list CiliumEnvoyConfigs

It runs at the `system-node-critical` priority and tolerates every taint, so it covers every node. The host network, host paths and added capabilities place it outside the baseline Pod Security Standard, so its namespace must allow the privileged level. Where a platform's security policy blocks the reduced capability set, `--set kubeadapt-k8s-pulse.privileged=true` runs it as a privileged container.

## Uninstalling

```bash
helm uninstall kubeadapt --namespace kubeadapt
```

This removes the agent Deployment, its Services, ServiceAccounts, the chart-created token Secrets, Roles, ClusterRoles and their bindings, and the network monitor DaemonSet and its ResourceQuota. It leaves behind:

- the `kubeadapt` namespace (Helm does not delete namespaces): `kubectl delete namespace kubeadapt`
- a token Secret you created yourself for `existingSecret`
- auto-upgrade Jobs that are still running; finished Jobs delete themselves after their TTL
- on nodes that did not have them, the empty directories `/etc/cni/net.d` and `/var/run/ztunnel`, which the network monitor creates to mount

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
