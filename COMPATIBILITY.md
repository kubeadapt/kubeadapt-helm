# Kubeadapt Compatibility Matrix

> **Note**: This repository is a monorepo containing multiple Helm charts. For specific component versions and dependencies, please refer to each chart's README.md in the `charts/` directory.

## Platform Support

### Supported Platforms

| Platform                 | Kubernetes Versions | Agent (`kubeadapt`) | Network monitor (`kubeadapt-k8s-pulse`) | Notes                                                                 |
| ------------------------ | ------------------- | ------------------- | -------------------------------------- | --------------------------------------------------------------------- |
| Amazon EKS (EC2 nodes)   | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with IRSA                                                |
| Amazon EKS on Fargate    | 1.24 - 1.35         | ✓                   | -                                      | Fargate runs no DaemonSets; in a mixed cluster the EC2 nodes are covered |
| Azure AKS                | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with Managed Identity                                    |
| Google GKE Standard      | 1.24 - 1.35         | ✓                   | ✓                                      | Full support with Workload Identity                                   |
| Google GKE Autopilot     | 1.24 - 1.35         | ✓                   | -                                      | Autopilot does not allow host network or added capabilities          |
| Red Hat OpenShift / ROSA | 1.24 - 1.35         | ✓                   | Privileged SCC required                | Unset the agent's fixed UID/GID (see README)                          |
| On-Premise               | 1.24 - 1.35         | ✓                   | ✓                                      | kubeadm, kops, Rancher, k3s, RKE2                                     |

**Agent:** one Deployment, restricted Pod Security Standard by default (non-root, read-only root filesystem, no capabilities). Needs [metrics-server](https://github.com/kubernetes-sigs/metrics-server) for CPU and memory usage.

**Network monitor:** a DaemonSet on every Linux node without taints (`kubeadapt-k8s-pulse.tolerations` adds tainted pools), except AWS Fargate and virtual-kubelet nodes. It has no priority class by default and does not evict workloads; on a node without room its pod waits. Disabled by default. It needs:

- Linux kernel 5.10 or newer
- the node's network namespace (`hostNetwork`), not its PID namespace
- a privileged container with a read-only root filesystem. With `kubeadapt-k8s-pulse.privileged=false`: the Linux capabilities `BPF`, `PERFMON` and `NET_ADMIN`; `SYS_RESOURCE` on kernels older than 5.11 (it can be removed on newer kernels); `SYS_PTRACE` for the container runtime inventory (it can be removed when the inventory is off); every other capability dropped and no privilege escalation.
- the node's `/proc`, cgroup tree and `/etc/cni/net.d` read-only, and `/sys/fs/bpf` writable; `/var/run/ztunnel` read-only when `kubeadapt-k8s-pulse.istioAmbient.enabled` is set
- read-only RBAC: list and watch pods, get nodes, list `ciliumenvoyconfigs.cilium.io`
- a namespace that allows the privileged Pod Security level

Where a platform does not allow privileged containers, set `kubeadapt-k8s-pulse.privileged=false`; where an SELinux or AppArmor policy then denies the BPF operations to the reduced capability set, set `kubeadapt-k8s-pulse.seLinuxOptions`. Exceptions for Pod Security Admission, Kyverno and Gatekeeper are in [examples/network-monitor](examples/network-monitor).

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

Network cost monitoring needs the network monitor, so it is not available on EKS Fargate or GKE Autopilot.

For issues or questions, please visit:

- [GitHub Issues](https://github.com/kubeadapt/kubeadapt-helm/issues)
- [Documentation](https://kubeadapt.io/docs)
