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

- Discount pricing (RI/SP): Requires [cloud account connection](/docs/v1/how-to-guides/integrations/aws) via cross-account IAM role
- EKS cluster auto-discovery included with the cloud account connection

#### Azure AKS

- On-demand and spot pricing works without any setup
- RI/SP discount integration: [Planned](https://feedback.kubeadapt.io/features/azure-reserved-vm-instances-savings-plans-6n8jg2)

#### Google GKE

- On-demand and spot pricing works without any setup
- CUD discount integration: [Planned](https://feedback.kubeadapt.io/features/gcp-committed-use-discounts-cuds-igjr9r)

#### On-Premise

- On-demand pricing works without any setup
- Custom pricing configuration available for non-cloud environments

## Feature Support Matrix

| Feature                           | EKS | AKS | GKE | On-Premise |
| --------------------------------- | --- | --- | --- | ---------- |
| Basic Metrics Collection          | ✓   | ✓   | ✓   | ✓          |
| Cloud Cost Integration            | ✓   | ✓   | ✓   | Custom     |
| GPU Monitoring                    | ✓   | ✓   | ✓   | ✓          |
| Network Cost Monitoring           | ✓   | ✓   | ✓   | -          |
| Persistent Storage                | ✓   | ✓   | ✓   | ✓          |

For issues or questions, please visit:

- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues)
- [Documentation](https://kubeadapt.io/docs)
