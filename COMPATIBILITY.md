# Kubeadapt Compatibility Matrix

> **Note**: This repository is a monorepo containing multiple Helm charts. For specific component versions and dependencies, please refer to each chart's README.md in the `charts/` directory.

## Platform Support

### Supported Platforms

| Platform                 | Kubernetes Versions | Agent (`kubeadapt`) | Network agent (`kubeadapt-k8s-pulse`) | Notes                                                                 |
| ------------------------ | ------------------- | ------------------- | -------------------------------------- | --------------------------------------------------------------------- |
| Amazon EKS (EC2 nodes)   | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with IRSA                                                |
| Amazon EKS on Fargate    | 1.24 - 1.35         | ✓                   | -                                      | Fargate runs no DaemonSets                                            |
| Azure AKS                | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with Managed Identity                                    |
| Google GKE Standard      | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with Workload Identity                                   |
| Google GKE Autopilot     | 1.24 - 1.35         | ✓                   | -                                      | Autopilot does not allow privileged pods                              |
| Red Hat OpenShift / ROSA | 1.24 - 1.35         | ✓                   | Privileged SCC required                | Unset the agent's fixed UID/GID (see README)                          |
| On-Premise               | 1.24 - 1.35         | ✓                   | ✓                                      | kubeadm, kops, Rancher, k3s, RKE2                                     |

**Agent:** one Deployment, restricted Pod Security Standard by default (non-root, read-only root filesystem, no capabilities). Needs [metrics-server](https://github.com/kubernetes-sigs/metrics-server) for CPU and memory usage.

**Network agent:** a privileged DaemonSet (`hostNetwork`, `hostPID`), Linux kernel 5.10+ on every node it runs on. Disabled by default.

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

Network cost monitoring needs the network agent, so it is not available on EKS Fargate or GKE Autopilot.
| Persistent Storage                | ✓   | ✓   | ✓   | ✓          |

For issues or questions, please visit:

- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues)
- [Documentation](https://kubeadapt.io/docs)
