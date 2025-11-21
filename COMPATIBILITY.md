# KubeAdapt Compatibility Matrix

## Current Release
Version: 0.5.0
Status: Production Ready

### Core Components
| Component          | Version | Status     | Notes |
|-------------------|---------|------------|-------|
| KubeAdapt         | 0.6.0   | Stable     | Core platform version |
| ├─ Agent          | 1.0.0   | Stable     | Cluster metrics collector |
| Prometheus        | 27.42.0 | Stable     | Metrics storage |
| OpenCost          | 2.4.0   | Stable     | Cost analysis |
| GPU Operator      | v25.10.0| Optional   | NVIDIA GPU support |

### Version Compatibility Matrix
| KubeAdapt Chart | Agent Version | Prometheus Version | OpenCost Version | GPU Operator Version |
|-----------------|---------------|-------------------|------------------|---------------------|
| 0.6.0          | 1.0.0         | 27.42.0           | 2.4.0            | v25.10.0           |

## Platform Support

### Supported Platforms

| Platform | Status | Kubernetes Versions | Tested | Notes |
|----------|--------|-------------------|--------|-------|
| Amazon EKS | ✓ Supported | 1.24 - 1.34 | ✓ Yes | Full support with IRSA |
| Azure AKS | ✓ Supported | 1.24 - 1.34 | ✓ Yes | Full support with Managed Identity |
| Google GKE | ✓ Supported | 1.24 - 1.34 | ✓ Yes | Full support with Workload Identity |
| Kind (Local) | ✓ Supported | 1.24 - 1.34 | ✓ Yes | Recommended for development |

### Platform-Specific Requirements

#### Amazon EKS
- **IRSA (IAM Roles for Service Accounts)**: Recommended for OpenCost integration
- **EBS CSI Driver**: Required if using Prometheus persistent volumes
- **Storage Classes**: gp2, gp3 supported

#### Azure AKS
- **Managed Identity**: Recommended for OpenCost integration
- **Azure Disk CSI**: Required if using Prometheus persistent volumes
- **Storage Classes**: managed-premium, managed-standard supported

#### Google GKE
- **Workload Identity**: Recommended for OpenCost integration
- **Compute Engine Persistent Disk CSI**: Required if using Prometheus persistent volumes
- **Storage Classes**: standard, standard-rwo, premium-rwo supported

#### Kind (Local Development)
- **Storage**: Uses local-path provisioner by default
- **Resource Requirements**: 4 CPU / 8GB RAM minimum
- **Limitations**: No cloud provider integrations (OpenCost will use list pricing)

## Feature Support Matrix

| Feature | EKS | AKS | GKE | Kind |
|---------|-----|-----|-----|------|
| Basic Metrics Collection | ✓ | ✓ | ✓ | ✓ |
| Cloud Cost Integration (OpenCost) | ✓ | ✓ | ✓ | Partial* |
| GPU Monitoring | ✓ | ✓ | ✓ | ✓** |
| Persistent Storage | ✓ | ✓ | ✓ | ✓ |
| Workload Identity | ✓ (IRSA) | ✓ (Managed ID) | ✓ (WI) | ✗ |
| Multi-Cluster Support | ✓ | ✓ | ✓ | ✓ |

For issues or questions, please visit:
- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues)
- [Documentation](https://kubeadapt.io/docs)
