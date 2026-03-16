# Kubeadapt Helm Charts

Official Helm charts for [Kubeadapt](https://kubeadapt.io) - Kubernetes cost optimization and resource management.

## Quick Start

```bash
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update

helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token="<your-token>"
```

Get a token from [app.kubeadapt.io](https://app.kubeadapt.io) under **Clusters > Add Cluster**.

## What Gets Installed

- **Kubeadapt Agent** - Collects cluster metrics, resource utilization, and cluster state snapshots
- **eBPF Network Agent** (optional) - DaemonSet for pod-to-pod network cost tracking
- **Auto-Upgrade sidecar** (optional) - Checks for chart updates and runs Helm upgrades automatically

**Requirements:** Kubernetes 1.24+, Helm 3.0+, [metrics-server](https://github.com/kubernetes-sigs/metrics-server)

## Charts

| Chart | Description |
|-------|-------------|
| [kubeadapt](https://github.com/kubeadapt/kubeadapt-helm/tree/main/charts/kubeadapt) | Main chart. Agent + optional auto-upgrade + optional eBPF subchart. |
| [ebpf-agent](https://github.com/kubeadapt/kubeadapt-helm/tree/main/charts/ebpf-agent) | Standalone eBPF network metrics DaemonSet. Usually installed via the parent chart. |

## OCI Registry

```bash
helm install kubeadapt oci://ghcr.io/kubeadapt/kubeadapt-helm/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token="<your-token>"
```

## Chart Verification

All charts are GPG-signed.

```bash
curl -fsSL https://kubeadapt.github.io/kubeadapt-helm/pgp_keys.asc | gpg --import
helm verify path/to/chart.tgz
```

**Key ID:** `948AD9EDA6BD626E` | **Fingerprint:** `3C8109B607AD3E119B7033D8948AD9EDA6BD626E`

## Resources

- [Deployment Reference](https://kubeadapt.io/docs/v1/helm-chart/overview/) - Full values documentation
- [Getting Started](https://kubeadapt.io/docs/v1/getting-started/quick-start/) - Installation walkthrough
- [ArtifactHub](https://artifacthub.io/packages/helm/kubeadapt/kubeadapt) - Browse charts
- [Contributing](https://github.com/kubeadapt/kubeadapt-helm/blob/main/CONTRIBUTING.md)
- [Security Policy](https://github.com/kubeadapt/kubeadapt-helm/blob/main/SECURITY.md)

## License

Apache 2.0. See [LICENSE](https://github.com/kubeadapt/kubeadapt-helm/blob/main/LICENSE).
