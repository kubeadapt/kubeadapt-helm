# KubeAdapt Helm Charts

This repository contains the Helm charts for deploying KubeAdapt components:
- KubeAdapt Agent: Kubernetes agent for collecting metrics and managing cluster resources
- Prometheus: For storing metrics
- OpenCost: For cost analysis

## Platform Support

| Platform | Status | Notes |
|----------|---------|---------|
| Kind     | ✓ Tested | Recommended for local development |
| Amazon EKS | ✓ Supported | Full support |
| Azure AKS | ✓ Supported | Full support |
| Google GKE | ✓ Supported | Full support |

For detailed compatibility information and platform-specific requirements, please see our [Compatibility Matrix](COMPATIBILITY.md).

**Minimum Requirements:**
- Kubernetes 1.24+
- Helm 3.0+

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

## Installation

```bash
# Add the KubeAdapt repository
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm

# Update your helm repositories
helm repo update

# Install the KubeAdapt chart
helm install kubeadapt kubeadapt/kubeadapt
```

## Configuration

See [values.yaml](./charts/kubeadapt/values.yaml) for configuration options.

## Chart Signing & Verification

### Chart Signatures
All Helm charts in this repository are signed using GPG. The signing key details are:

- Key ID: 948AD9EDA6BD626E
- Fingerprint: 3C8109B607AD3E119B7033D8948AD9EDA6BD626E

For detailed verification instructions and troubleshooting, see our [Security Policy](SECURITY.md).


## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Security

Please see our [Security Policy](SECURITY.md) for details about:
- Supported versions
- How to report vulnerabilities
- Chart signing and verification

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details. 