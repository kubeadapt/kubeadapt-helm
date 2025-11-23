# Kubeadapt Compatibility Matrix

> **Note**: This repository is a monorepo containing multiple Helm charts. For specific component versions and dependencies, please refer to each chart's README.md in the `charts/` directory.

## Platform Support

### Supported Platforms

| Platform   | Status      | Kubernetes Versions | Tested | Notes                                                                                |
| ---------- | ----------- | ------------------- | ------ | ------------------------------------------------------------------------------------ |
| Amazon EKS | ✓ Supported | 1.24 - 1.34         | ✓ Yes  | Full support with IRSA                                                               |
| Azure AKS  | ✓ Supported | 1.24 - 1.34         | ✓ Yes  | Full support with Managed Identity                                                   |
| Google GKE | ✓ Supported | 1.24 - 1.34         | ✓ Yes  | Full support with Workload Identity                                                  |
| On-Premise | ✓ Supported | 1.24 - 1.34         | ✓ Yes  | Full support for On-premise environments and recommended for development and testing |

### Platform-Specific Requirements

#### Amazon EKS

- **IRSA (IAM Roles for Service Accounts)**: Recommended for OpenCost integration

#### Azure AKS

- **Managed Identity**: Recommended for OpenCost integration

#### Google GKE

- **Workload Identity**: Recommended for OpenCost integration

#### On-Premise

- **Limitations**: Cloud cost integration requires manual pricing provided as configuration

## Feature Support Matrix

| Feature                           | EKS | AKS | GKE | On-Premise |
| --------------------------------- | --- | --- | --- | ---------- |
| Basic Metrics Collection          | ✓   | ✓   | ✓   | ✓          |
| Cloud Cost Integration (OpenCost) | ✓   | ✓   | ✓   | Custom     |
| GPU Monitoring                    | ✓   | ✓   | ✓   | ✓          |
| Network Cost Monitoring           | ✓   | ✓   | ✓   | -          |
| Persistent Storage                | ✓   | ✓   | ✓   | ✓          |

For issues or questions, please visit:

- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues)
- [Documentation](https://kubeadapt.io/docs)
