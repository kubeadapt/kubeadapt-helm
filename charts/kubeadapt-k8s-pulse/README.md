# kubeadapt-k8s-pulse

![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 3.0.1](https://img.shields.io/badge/AppVersion-3.0.1-informational?style=flat-square)

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
helm pull oci://ghcr.io/kubeadapt/kubeadapt-helm/kubeadapt-k8s-pulse --version 1.1.0
```

## Installing the Chart

To install the chart with the release name `kubeadapt-k8s-pulse`:

```console
helm install kubeadapt-k8s-pulse kubeadapt/kubeadapt-k8s-pulse -n kubeadapt --create-namespace
```

Or via OCI:

```console
helm install kubeadapt-k8s-pulse oci://ghcr.io/kubeadapt/kubeadapt-helm/kubeadapt-k8s-pulse -n kubeadapt --create-namespace
```

> **Note:** Using `kubeadapt-k8s-pulse` as release name ensures the service name matches Prometheus scrape configurations.

## Uninstalling the Chart

To uninstall/delete the deployment:

```console
helm delete kubeadapt-k8s-pulse -n kubeadapt
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

## Flow Export to the Kubeadapt Agent

Installed by the `kubeadapt` chart (`kubeadapt-k8s-pulse.enabled=true`), pulse sends its flows to that chart's agent Service with no extra settings:

- the endpoint is `<name>-agent.<namespace>.svc:9091`;
- every push carries a bearer token, read from a file mounted from the Secret the `kubeadapt` chart generates, so it never appears in the pod spec.

**The channel is plaintext gRPC.** The token authenticates pulse to the agent, but it travels unencrypted inside the cluster network, and so do the flow batches (pod IPs, DNS names, HTTP routes). Anything that can observe node traffic can read both.

Installed on its own, export is off until `config.export.agentEndpoint` is set. `config.export.tokenSecret` names a Secret with the token under the key `token`; without it pulse sends no token.

The DaemonSet runs with `hostNetwork`, so `dnsPolicy` defaults to `ClusterFirstWithHostNet`: without it the pod cannot resolve cluster Service names.

Export needs a pulse image that sends the token over plaintext gRPC, which is a release cut from pulse main after the TLS client was removed. The default `image.tag` (v3.0.1) does not export; v3.1.0 refuses to send a token without TLS.

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
| config.export.agentEndpoint | string | `""` |  |
| config.export.tokenSecret | string | `""` |  |
| config.logFormat | string | `"json"` |  |
| config.logLevel | string | `"info"` |  |
| config.metricsPort | int | `9090` |  |
| config.profilingPort | int | `6060` |  |
| dnsPolicy | string | `"ClusterFirstWithHostNet"` |  |
| enabled | bool | `true` |  |
| env[0].name | string | `"EBPF_RETRY_BUFFER_SIZE"` |  |
| env[0].value | string | `"120"` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-pulse"` |  |
| image.tag | string | `"v3.0.1"` |  |
| nodeSelector | object | `{}` |  |
| rbac.create | bool | `true` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"384Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
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
kubectl logs -n kubeadapt -l app.kubernetes.io/name=kubeadapt-k8s-pulse --tail=50
kubectl port-forward -n kubeadapt daemonset/kubeadapt-k8s-pulse 9090:9090
curl http://localhost:9090/metrics | grep kubeadapt
```
