# Kubeadapt Helm Charts

This repository contains the Helm charts for deploying Kubeadapt into Kubernetes clusters:

- **kubeadapt** - Main chart. Deploys the Kubeadapt agent (cluster metrics collection), with optional auto-upgrade sidecar and eBPF network agent subchart.
- **ebpf-agent** - Standalone chart for the eBPF network metrics DaemonSet. Usually installed as a dependency of the main chart, but can be deployed independently.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Amazon EKS | Supported | Tested on 1.24 through 1.35 |
| Azure AKS | Supported | Tested on 1.24 through 1.35 |
| Google GKE | Supported | Standard and Autopilot modes |
| On-premise / self-hosted | Supported | kubeadm, kops, Rancher, k3s, RKE2 |

**Requirements:**
- Kubernetes 1.24+
- Helm 3.0+
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) installed in the cluster

## Installation

```bash
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update

helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token="<your-token>"
```

Get a token from [app.kubeadapt.io](https://app.kubeadapt.io) under **Clusters > Add Cluster**.

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
