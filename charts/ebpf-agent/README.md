# ebpf-agent

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.1.1](https://img.shields.io/badge/AppVersion-0.1.1-informational?style=flat-square)

High-performance eBPF-based network metrics agent for Kubernetes

## Overview

The eBPF agent runs as a DaemonSet on each Kubernetes node, capturing network packets at the Traffic Control (TC) layer to track pod-to-pod traffic. It exports raw IP-based connection metrics to Prometheus.

### Key Features

- **Pod-Level Traffic Tracking**: Monitors network traffic between pods using TC eBPF hooks
- **Protocol Support**: TCP and UDP traffic with separate tracking
- **IPv4 and IPv6 Support**: Full dual-stack support on kernel 5.10+
- **Egress-Only Tracking**: Same-node and cross-node across pods
- **Multi-Interface Deduplication**: Prevents counting same packet across interface paths
- **Overflow Protection**: Ringbuffer captures flows when map reaches capacity

## Prerequisites

- **Kubernetes**: 1.24+
- **Linux Kernel**: 5.10+ (full IPv4+IPv6 dual-stack support)
- **Helm**: 3.0.0+

## Get Repo Info

```console
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update
```

Or use OCI registry:

```console
helm pull oci://ghcr.io/kubeadapt/kubeadapt-helm/ebpf-agent --version 0.1.1
```

## Installing the Chart

To install the chart with the release name `kubeadapt-ebpf-agent`:

```console
helm install kubeadapt-ebpf-agent kubeadapt/ebpf-agent -n kubeadapt --create-namespace
```

Or via OCI:

```console
helm install kubeadapt-ebpf-agent oci://ghcr.io/kubeadapt/kubeadapt-helm/ebpf-agent -n kubeadapt --create-namespace
```

> **Note:** Using `kubeadapt-ebpf-agent` as release name ensures the service name matches Prometheus scrape configurations.

## Uninstalling the Chart

To uninstall/delete the deployment:

```console
helm delete kubeadapt-ebpf-agent -n kubeadapt
```

## Security Requirements

The eBPF agent requires privileged access:

```yaml
securityContext:
  privileged: true
  capabilities:
    add:
      - SYS_ADMIN    # Load/attach eBPF programs
      - SYS_RESOURCE # Lock memory for BPF maps
      - NET_ADMIN    # Network namespace operations
```

Additionally requires:
- `hostNetwork: true` - Access host network namespace
- `hostPID: true` - Track processes for connection attribution

## Exported Metrics

### Pod-Level Traffic Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kubeadapt_connection_traffic_bytes_total` | Counter | Cumulative egress bytes (use `rate()` for throughput) |
| `kubeadapt_connection_traffic_packets_total` | Counter | Cumulative egress packets |
| `kubeadapt_active_connections` | Gauge | Current active connections |

### Internal Monitoring Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kubeadapt_bpf_load_status` | Gauge | BPF program load status (1=loaded, 0=failed) |
| `kubeadapt_bpf_load_attempts_total` | Counter | Total BPF load attempts |
| `kubeadapt_bpf_load_duration_seconds` | Gauge | BPF program load duration |
| `kubeadapt_bpf_map_utilization_percent` | Gauge | BPF map utilization (0-100%) |
| `kubeadapt_overflow_flows_total` | Counter | Flows sent to overflow ringbuffer |
| `kubeadapt_ip_pairs_batch_size` | Gauge | Number of IP pairs in current batch |
| `kubeadapt_ebpf_collection_duration_seconds` | Histogram | Map collection cycle duration |
| `kubeadapt_collector_errors_total` | Counter | Collection errors by type |
| `kubeadapt_connection_tracking_info` | Gauge | Connection tracking configuration info |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| config.collectionInterval | string | `"25s"` |  |
| config.connectionTracking | bool | `true` |  |
| config.dumpBPFMaps | bool | `false` |  |
| config.enableProfiling | bool | `false` |  |
| config.logFormat | string | `"json"` |  |
| config.logLevel | string | `"info"` |  |
| config.metricsPort | int | `9090` |  |
| config.netnsFilterMode | string | `"default"` |  |
| config.profilingPort | int | `6060` |  |
| enabled | bool | `true` |  |
| env | list | `[]` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"public.ecr.aws/w3l5x6r6/kubeadapt/app/kubeadapt-ebpf-agent"` |  |
| image.tag | string | `"v0.1.1"` |  |
| nodeSelector | object | `{}` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"384Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations[0].effect | string | `"NoSchedule"` |  |
| tolerations[0].key | string | `"node-role.kubernetes.io/master"` |  |
| tolerations[1].effect | string | `"NoSchedule"` |  |
| tolerations[1].key | string | `"node-role.kubernetes.io/control-plane"` |  |
| tolerations[2].effect | string | `"NoSchedule"` |  |
| tolerations[2].key | string | `"node.kubernetes.io/unschedulable"` |  |
| tolerations[2].operator | string | `"Exists"` |  |
| tolerations[3].effect | string | `"NoExecute"` |  |
| tolerations[3].key | string | `"node.kubernetes.io/not-ready"` |  |
| tolerations[3].operator | string | `"Exists"` |  |
| tolerations[3].tolerationSeconds | int | `300` |  |
| tolerations[4].effect | string | `"NoExecute"` |  |
| tolerations[4].key | string | `"node.kubernetes.io/unreachable"` |  |
| tolerations[4].operator | string | `"Exists"` |  |
| tolerations[4].tolerationSeconds | int | `300` |  |
| tolerations[5].effect | string | `"NoSchedule"` |  |
| tolerations[5].key | string | `"node.kubernetes.io/disk-pressure"` |  |
| tolerations[5].operator | string | `"Exists"` |  |
| tolerations[6].effect | string | `"NoSchedule"` |  |
| tolerations[6].key | string | `"node.kubernetes.io/memory-pressure"` |  |
| tolerations[6].operator | string | `"Exists"` |  |
| tolerations[7].effect | string | `"NoSchedule"` |  |
| tolerations[7].key | string | `"node.kubernetes.io/pid-pressure"` |  |
| tolerations[7].operator | string | `"Exists"` |  |
| tolerations[8].effect | string | `"NoSchedule"` |  |
| tolerations[8].key | string | `"karpenter.sh/disrupted"` |  |
| tolerations[8].operator | string | `"Exists"` |  |
| tolerations[9].effect | string | `"NoSchedule"` |  |
| tolerations[9].key | string | `"workload"` |  |
| tolerations[9].operator | string | `"Exists"` |  |
| topologySpreadConstraints | list | `[]` |  |

## Troubleshooting

### Agent Won't Start

```bash
# Check kernel version (needs 5.10+)
uname -r

# Verify BPF filesystem mounted
ls /sys/fs/bpf
```

### No Metrics Appearing

On the **worker node** (via SSH):
```bash
sudo bpftool prog list | grep tc_
sudo bpftool map list | grep connection_flows
```

Via **kubectl**:
```bash
kubectl logs -n kubeadapt -l app.kubernetes.io/name=ebpf-agent --tail=50
kubectl port-forward -n kubeadapt daemonset/kubeadapt-ebpf-agent 9090:9090
curl http://localhost:9090/metrics | grep kubeadapt
```
