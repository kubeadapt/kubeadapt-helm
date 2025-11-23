# Kubeadapt Helm Charts Repository

Official Helm charts for [Kubeadapt](https://kubeadapt.io) - a SaaS platform for Kubernetes resource optimization and cost management.

## 🚀 Quick Start

### 1. Create Your Account

Sign up at [kubeadapt.io](https://kubeadapt.io) to get your agent authentication token.

### 2. Add the Helm Repository

```bash
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update
```

### 3. Install the Chart

```bash
# Minimal installation (agent, prometheus, node-exporter, kube-state-metrics, opencost enabled by default)
helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token="<YOUR_AGENT_TOKEN>"
```

> **⚠️ Important**: The agent requires a valid token from the Kubeadapt platform to connect to the backend.

## 📦 What Gets Installed

- **Kubeadapt Agent**: Connects to Kubeadapt SaaS backend for metrics collection
- **Prometheus** (required): Local metrics buffer for agent queries
- **OpenCost** (required): Kubernetes cost analysis integration
- **GPU Operator** (optional): NVIDIA GPU support

**Requirements:**
- Kubernetes 1.24+
- Helm 3.0.0+
- A Kubeadapt account and agent token

## 📦 Alternative: OCI Registry

Charts are also available via GitHub Container Registry:

```bash
helm install kubeadapt oci://ghcr.io/kubeadapt/kubeadapt-helm/kubeadapt \
  --set agent.config.token="your-token-here"
```

## 🔐 Chart Verification

All charts are signed with GPG for security.

```bash
# Import the public key
curl -fsSL https://kubeadapt.github.io/kubeadapt-helm/pgp_keys.asc | gpg --import

# Verify chart signature
helm verify path/to/chart.tgz
```

**GPG Key Details:**
- **Key ID**: `948AD9EDA6BD626E`
- **Fingerprint**: `3C8109B607AD3E119B7033D8948AD9EDA6BD626E`

## 📚 Resources

**Documentation:**
- [Getting Started Guide](https://kubeadapt.io/docs/v1/getting-started/quick-start)
- [Chart Configuration Reference](https://github.com/kubeadapt/kubeadapt-helm/blob/main/charts/kubeadapt/values.yaml)
- [Platform Compatibility Matrix](https://github.com/kubeadapt/kubeadapt-helm/blob/main/COMPATIBILITY.md)

**Community:**
- [ArtifactHub](https://artifacthub.io/packages/helm/kubeadapt/kubeadapt) - Browse and discover charts
- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues) - Report bugs or request features

**Contributing:**
- [Contributing Guide](https://github.com/kubeadapt/kubeadapt-helm/blob/main/CONTRIBUTING.md)
- [Security Policy](https://github.com/kubeadapt/kubeadapt-helm/blob/main/SECURITY.md) - Report vulnerabilities

## 📜 License

This project is licensed under the Apache License 2.0. See [LICENSE](https://github.com/kubeadapt/kubeadapt-helm/blob/main/LICENSE) for details.

---

**Maintained by**: [Kubeadapt Team](https://github.com/kubeadapt) | **Website**: [kubeadapt.io](https://kubeadapt.io)
