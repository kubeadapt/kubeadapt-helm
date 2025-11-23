# kubeadapt

![Version: 0.8.0](https://img.shields.io/badge/Version-0.8.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for Kubeadapt

## Prerequisites

- Kubernetes 1.24+
- Helm 3.0.0+

## Get Repo Info

```console
helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update
```

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release kubeadapt/kubeadapt
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://helm.ngc.nvidia.com/nvidia | gpu-operator | v25.10.0 |
| https://opencost.github.io/opencost-helm-chart | opencost | 2.4.0 |
| https://prometheus-community.github.io/helm-charts | prometheus | 27.46.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.config.backendApiEndpoint | string | `""` |  |
| agent.config.collectionInterval | string | `"60s"` |  |
| agent.config.compressionEnabled | bool | `true` |  |
| agent.config.compressionLevel | int | `3` |  |
| agent.config.e2eMode | bool | `false` |  |
| agent.config.goMaxProcs | int | `2` |  |
| agent.config.goMemLimit | string | `"256MiB"` |  |
| agent.config.gpuEnabled | bool | `false` |  |
| agent.config.logLevel | string | `"info"` |  |
| agent.config.metricsPort | int | `8080` |  |
| agent.config.networkCostEnabled | bool | `false` |  |
| agent.config.prometheusTimeout | string | `"30s"` |  |
| agent.config.prometheusUrl | string | `"http://kubeadapt-prometheus-server.kubeadapt.svc:80"` |  |
| agent.config.queryConcurrency | int | `10` |  |
| agent.config.token | string | `""` |  |
| agent.config.writeJsonDebug | bool | `false` |  |
| agent.enabled | bool | `false` |  |
| agent.env | list | `[]` |  |
| agent.image.pullPolicy | string | `"IfNotPresent"` |  |
| agent.image.repository | string | `"public.ecr.aws/w3l5x6r6/kubeadapt/app/kubeadapt-agent"` |  |
| agent.image.tag | string | `"a2c889f"` |  |
| agent.rbac.create | bool | `true` |  |
| agent.resources.limits.cpu | string | `"500m"` |  |
| agent.resources.limits.memory | string | `"256Mi"` |  |
| agent.resources.requests.cpu | string | `"100m"` |  |
| agent.resources.requests.memory | string | `"128Mi"` |  |
| agent.service.port | int | `8080` |  |
| agent.service.protocol | string | `"TCP"` |  |
| agent.service.type | string | `"ClusterIP"` |  |
| agent.serviceAccount.annotations | object | `{}` |  |
| agent.serviceAccount.create | bool | `true` |  |
| agent.serviceAccount.name | string | `""` |  |
| global.fullnameOverride | string | `""` |  |
| global.name | string | `"kubeadapt"` |  |
| global.nameOverride | string | `""` |  |
| gpu-operator.dcgmExporter.enabled | bool | `true` |  |
| gpu-operator.dcgmExporter.image | string | `"dcgm-exporter"` |  |
| gpu-operator.dcgmExporter.imagePullPolicy | string | `"IfNotPresent"` |  |
| gpu-operator.dcgmExporter.imagePullSecrets[0] | string | `"nvcr-cred"` |  |
| gpu-operator.dcgmExporter.repository | string | `"nvcr.io/nvidia/k8s"` |  |
| gpu-operator.dcgmExporter.resources.limits.cpu | string | `"250m"` |  |
| gpu-operator.dcgmExporter.resources.limits.memory | string | `"512Mi"` |  |
| gpu-operator.dcgmExporter.resources.requests.cpu | string | `"50m"` |  |
| gpu-operator.dcgmExporter.resources.requests.memory | string | `"128Mi"` |  |
| gpu-operator.dcgmExporter.serviceMonitor.additionalLabels.prometheus | string | `"kube-prometheus"` |  |
| gpu-operator.dcgmExporter.serviceMonitor.enabled | bool | `true` |  |
| gpu-operator.dcgmExporter.serviceMonitor.interval | string | `"30s"` |  |
| gpu-operator.dcgmExporter.version | string | `"4.3.1-4.4.0-ubuntu22.04"` |  |
| gpu-operator.devicePlugin.enabled | bool | `true` |  |
| gpu-operator.devicePlugin.image | string | `"k8s-device-plugin"` |  |
| gpu-operator.devicePlugin.imagePullSecrets[0] | string | `"nvcr-cred"` |  |
| gpu-operator.devicePlugin.repository | string | `"nvcr.io/nvidia"` |  |
| gpu-operator.devicePlugin.version | string | `"v0.17.3"` |  |
| gpu-operator.driver.enabled | bool | `true` |  |
| gpu-operator.driver.image | string | `"driver"` |  |
| gpu-operator.driver.imagePullSecrets[0] | string | `"nvcr-cred"` |  |
| gpu-operator.driver.repository | string | `"nvcr.io/nvidia"` |  |
| gpu-operator.driver.version | string | `"580.65.06"` |  |
| gpu-operator.enabled | bool | `false` |  |
| gpu-operator.gfd.enabled | bool | `true` |  |
| gpu-operator.gfd.image | string | `"gpu-feature-discovery"` |  |
| gpu-operator.gfd.imagePullSecrets | list | `[]` |  |
| gpu-operator.gfd.repository | string | `"docker.io/nvidia"` |  |
| gpu-operator.gfd.version | string | `"v0.6.0"` |  |
| gpu-operator.migManager.enabled | bool | `false` |  |
| gpu-operator.operator.cleanupCRD | bool | `false` |  |
| gpu-operator.operator.defaultRuntime | string | `"containerd"` |  |
| gpu-operator.operator.imagePullSecrets[0] | string | `"nvcr-cred"` |  |
| gpu-operator.operator.upgradeCRD | bool | `true` |  |
| gpu-operator.toolkit.enabled | bool | `true` |  |
| gpu-operator.toolkit.image | string | `"container-toolkit"` |  |
| gpu-operator.toolkit.imagePullSecrets[0] | string | `"nvcr-cred"` |  |
| gpu-operator.toolkit.repository | string | `"nvcr.io/nvidia/k8s"` |  |
| opencost.cloudIntegrationSecret | string | `""` |  |
| opencost.extraVolumes | list | `[]` |  |
| opencost.opencost.annotations."prometheus.io/path" | string | `"/metrics"` |  |
| opencost.opencost.annotations."prometheus.io/port" | string | `"9003"` |  |
| opencost.opencost.annotations."prometheus.io/scrape" | string | `"true"` |  |
| opencost.opencost.carbonCost.enabled | bool | `false` | Enable carbon cost exposed in the API |
| opencost.opencost.cloudCost.enabled | bool | `true` |  |
| opencost.opencost.cloudCost.refreshRateHours | int | `6` |  |
| opencost.opencost.cloudCost.runWindowDays | int | `3` |  |
| opencost.opencost.customPricing.costModel.CPU | string | `"0.031611"` |  |
| opencost.opencost.customPricing.costModel.GPU | string | `"0.95"` |  |
| opencost.opencost.customPricing.costModel.RAM | string | `"0.004237"` |  |
| opencost.opencost.customPricing.costModel.description | string | `"Default prices based on GCP us-central1"` |  |
| opencost.opencost.customPricing.costModel.internetNetworkEgress | string | `"0.12"` |  |
| opencost.opencost.customPricing.costModel.regionNetworkEgress | string | `"0.01"` |  |
| opencost.opencost.customPricing.costModel.spotCPU | string | `"0.006655"` |  |
| opencost.opencost.customPricing.costModel.spotRAM | string | `"0.000892"` |  |
| opencost.opencost.customPricing.costModel.storage | string | `"0.00005479452"` |  |
| opencost.opencost.customPricing.costModel.zoneNetworkEgress | string | `"0.01"` |  |
| opencost.opencost.customPricing.enabled | bool | `false` |  |
| opencost.opencost.dataRetention.dailyResolutionDays | int | `15` |  |
| opencost.opencost.exporter.aws.access_key_id | string | `""` |  |
| opencost.opencost.exporter.aws.secret_access_key | string | `""` |  |
| opencost.opencost.exporter.cloudProviderApiKey | string | `""` |  |
| opencost.opencost.exporter.defaultClusterId | string | `"default"` |  |
| opencost.opencost.exporter.extraEnv | object | `{}` |  |
| opencost.opencost.exporter.extraVolumeMounts | list | `[]` |  |
| opencost.opencost.exporter.resources.limits.cpu | string | `"999m"` |  |
| opencost.opencost.exporter.resources.limits.memory | string | `"1Gi"` |  |
| opencost.opencost.exporter.resources.requests.cpu | string | `"10m"` |  |
| opencost.opencost.exporter.resources.requests.memory | string | `"55Mi"` |  |
| opencost.opencost.prometheus.external.enabled | bool | `false` |  |
| opencost.opencost.prometheus.external.url | string | `""` |  |
| opencost.opencost.prometheus.internal.enabled | bool | `true` |  |
| opencost.opencost.prometheus.internal.namespaceName | string | `"kubeadapt"` |  |
| opencost.opencost.prometheus.internal.port | int | `80` |  |
| opencost.opencost.prometheus.internal.serviceName | string | `"kubeadapt-prometheus-server"` |  |
| opencost.opencost.ui.enabled | bool | `false` |  |
| opencost.rbac.enabled | bool | `true` |  |
| opencost.restartJob.enabled | bool | `true` |  |
| opencost.serviceAccount.annotations | object | `{}` |  |
| opencost.serviceAccount.automountServiceAccountToken | bool | `true` |  |
| opencost.serviceAccount.create | bool | `true` |  |
| opencost.serviceAccount.name | string | `""` |  |
| prometheus.alertmanager.enabled | bool | `false` |  |
| prometheus.enabled | bool | `true` |  |
| prometheus.extraScrapeConfigs | string | `"# Node-Exporter (Chart-deployed, controlled discovery with 15s interval)\n# CRITICAL: Explicit config required to guarantee 15s interval for rate([1m])\n# Auto-discovery alone uses chart defaults (typically 1m) which breaks rate() queries\n- job_name: \"node-exporter\"\n  scrape_interval: 15s      # ← GUARANTEED 15s for rate([1m]) compatibility (requires 4+ data points)\n  kubernetes_sd_configs:\n    - role: endpoints\n      namespaces:\n        names:\n          - kubeadapt      # ← Chart deploys node-exporter here\n  relabel_configs:\n    # Keep only prometheus-node-exporter service endpoints\n    - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_name]\n      regex: prometheus-node-exporter\n      action: keep\n    # Keep only the metrics port\n    - source_labels: [__meta_kubernetes_endpoint_port_name]\n      regex: metrics\n      action: keep\n    # Add node label from endpoint address\n    - source_labels: [__meta_kubernetes_endpoint_address_target_name]\n      target_label: node\n  metric_relabel_configs:\n    # Filter: Keep only required node metrics (7 metrics total)\n    - source_labels: [__name__]\n      action: keep\n      regex: ^(node_cpu_seconds_total|node_memory_MemTotal_bytes|node_memory_MemAvailable_bytes|node_filesystem_size_bytes|node_filesystem_avail_bytes|node_disk_io_time_seconds_total|node_disk_io_now)$\n\n# ============================================================\n# KubeAdapt Agent Internal Metrics\n# ============================================================\n# Scrapes agent's own observability metrics for monitoring performance,\n# errors, and operational health.\n- job_name: \"kubeadapt-agent\"\n  kubernetes_sd_configs:\n    - role: service\n      namespaces:\n        names:\n          - kubeadapt\n  relabel_configs:\n    # Keep only services with agent component label\n    - source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_component]\n      regex: agent\n      action: keep\n    # Keep only the metrics port\n    - source_labels: [__meta_kubernetes_endpoint_port_name]\n      regex: metrics\n      action: keep\n    # Add agent pod name as label\n    - source_labels: [__meta_kubernetes_pod_name]\n      target_label: agent_pod\n  metric_relabel_configs:\n    # Filter: Keep only agent internal metrics (11 metrics total)\n    # Collection metrics (4): collection_duration, collection_total, data_points, collection_errors\n    # Prometheus query metrics (3): query_duration, query_errors, queries_total\n    # Backend metrics (2): backend_post_duration, backend_post_errors\n    # Compression metrics (2): compression_ratio, compression_duration\n    - source_labels: [__name__]\n      action: keep\n      regex: ^(kubeadapt_agent_collection_duration_seconds|kubeadapt_agent_collection_total|kubeadapt_agent_data_points_total|kubeadapt_agent_collection_errors_total|kubeadapt_agent_prometheus_query_duration_seconds|kubeadapt_agent_prometheus_query_errors_total|kubeadapt_agent_prometheus_queries_total|kubeadapt_agent_backend_post_duration_seconds|kubeadapt_agent_backend_post_errors_total|kubeadapt_agent_compression_ratio|kubeadapt_agent_compression_duration_seconds)$\n\n# ============================================================\n# DCGM Exporter for GPU Metrics (Optional - Requires GPU Operator)\n# ============================================================\n# Uncomment this section ONLY if gpu-operator.enabled=true\n# IMPORTANT: This requires NVIDIA GPU Operator to be deployed.\n# Without GPU operator, this scrape job will show \"no endpoints found\".\n#\n# ⚠️  MIG MODE LIMITATION:\n# DCGM Exporter in Kubernetes mode does NOT support container-level\n# GPU utilization mapping when MIG (Multi-Instance GPU) is enabled.\n# For MIG environments, we have eBPF-based agent that works as daemonset\n# and expose the gpu utilization metrics per MIG profile\n# ============================================================\n#\n# - job_name: \"dcgm-exporter\"\n#   kubernetes_sd_configs:\n#     - role: pod\n#       namespaces:\n#         names:\n#           - kubeadapt\n#   relabel_configs:\n#     - source_labels: [__meta_kubernetes_pod_label_app]\n#       action: keep\n#       regex: dcgm-exporter\n#     - source_labels: [__meta_kubernetes_pod_container_port_name]\n#       action: keep\n#       regex: metrics\n#   metric_relabel_configs:\n#     - source_labels: [__name__]\n#       action: keep\n#       regex: ^(DCGM_FI_DEV_GPU_UTIL|DCGM_FI_DEV_FB_USED)$\n\n# ============================================================\n# eBPF Network Cost Tracking (Optional - Requires eBPF Agent)\n# ============================================================\n# Uncomment this section to enable pod-to-pod network traffic monitoring\n#\n# REQUIREMENTS:\n# - Linux kernel >= 5.8 (required for TC eBPF support)\n# - eBPF agent deployed as DaemonSet (see ebpf-agent chart)\n#\n# WHAT IT TRACKS:\n# - Pod-to-pod network traffic (bytes and packets)\n# - Protocol-level metrics (TCP/UDP)\n#\n# METRICS EXPOSED:\n# - kubeadapt_connection_traffic_bytes_total: Cumulative bytes between pod IPs\n# - kubeadapt_connection_traffic_packets_total: Cumulative packets between pod IPs\n# - Labels: src_ip, dst_ip, protocol, daemonset_pod_uid, daemonset_node_name\n#\n# Backend enriches raw IP metrics with K8s metadata (pod names, namespaces, services)\n# and calculates network costs based on corresponding cloud provider pricing\n# ============================================================\n#\n# - job_name: \"kubeadapt-ebpf-agent\"\n#   kubernetes_sd_configs:\n#     - role: pod\n#       namespaces:\n#         names:\n#           - kubeadapt\n#   relabel_configs:\n#     # Keep only eBPF agent pods\n#     - source_labels: [__meta_kubernetes_pod_label_app]\n#       action: keep\n#       regex: kubeadapt-ebpf-agent\n#     # Keep only the metrics port\n#     - source_labels: [__meta_kubernetes_pod_container_port_name]\n#       action: keep\n#       regex: metrics\n#     # Add node label from pod's node\n#     - source_labels: [__meta_kubernetes_pod_node_name]\n#       target_label: node\n#   metric_relabel_configs:\n#     # Filter: Keep network traffic AND internal observability metrics\n#     # Network traffic (2 metrics):\n#     #   - kubeadapt_connection_traffic_bytes_total\n#     #   - kubeadapt_connection_traffic_packets_total\n#     # Internal observability (10 metrics):\n#     #   - kubeadapt_bpf_load_status (BPF load success/failure)\n#     #   - kubeadapt_bpf_load_attempts_total (BPF load attempts)\n#     #   - kubeadapt_bpf_load_duration_seconds (BPF load time)\n#     #   - kubeadapt_active_connections (active connection count)\n#     #   - kubeadapt_connection_tracking_info (tracking metadata)\n#     #   - kubeadapt_bpf_map_utilization_percent (map usage %)\n#     #   - kubeadapt_overflow_flows_total (overflow events)\n#     #   - kubeadapt_ip_pairs_batch_size (batch size)\n#     #   - kubeadapt_ebpf_collection_duration_seconds (collection time histogram)\n#     #   - kubeadapt_collector_errors_total (error counter)\n#     - source_labels: [__name__]\n#       action: keep\n#       regex: ^(kubeadapt_connection_traffic_bytes_total|kubeadapt_connection_traffic_packets_total|kubeadapt_bpf_load_status|kubeadapt_bpf_load_attempts_total|kubeadapt_bpf_load_duration_seconds|kubeadapt_active_connections|kubeadapt_connection_tracking_info|kubeadapt_bpf_map_utilization_percent|kubeadapt_overflow_flows_total|kubeadapt_ip_pairs_batch_size|kubeadapt_ebpf_collection_duration_seconds|kubeadapt_collector_errors_total)$\n"` |  |
| prometheus.kube-state-metrics | object | `{"enabled":true,"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"}}` | Kube State Metrics Configuration |
| prometheus.prometheus-node-exporter | object | `{"enabled":true}` | Node Exporter Configuration: If you already have node-exporter running in your cluster (e.g., from kube-prometheus-stack), keep prometheus-node-exporter.enabled as false. Because we can read node exporter metrics from existing up and running prometheus node exporters. If you don't have any existing node-exporter, set prometheus-node-exporter.enabled to true. |
| prometheus.server.fullnameOverride | string | `"kubeadapt-prometheus-server"` |  |
| prometheus.server.persistentVolume.enabled | bool | `false` |  |
| prometheus.server.persistentVolume.size | string | `"20Gi"` |  |
| prometheus.server.retention | string | `"30m"` |  |
| prometheus.server.service.servicePort | int | `80` |  |
| prometheus.server.service.type | string | `"ClusterIP"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[0].job_name | string | `"prometheus"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[0].metric_relabel_configs[0].action | string | `"keep"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[0].metric_relabel_configs[0].regex | string | `"^(prometheus_.*|up|time)$"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[0].metric_relabel_configs[0].source_labels[0] | string | `"__name__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[0].static_configs[0].targets[0] | string | `"localhost:9090"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].honor_labels | bool | `true` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].job_name | string | `"kube-state-metrics"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].kubernetes_sd_configs[0].namespaces.names[0] | string | `"kubeadapt"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].kubernetes_sd_configs[0].role | string | `"service"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].metric_relabel_configs[0].action | string | `"keep"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].metric_relabel_configs[0].regex | string | `"^(kube_pod_info|kube_deployment_created|kube_namespace_labels|kube_node_info|kube_persistentvolume_info|kube_pod_container_info|kube_node_status_capacity_cpu_cores|kube_node_status_capacity_memory_bytes|kube_node_status_allocatable|kube_node_labels|kube_node_status_condition|kube_pod_container_resource_requests|kube_pod_owner|kube_pod_container_status_running|kube_replicaset_owner|kube_pod_container_resource_limits|kube_pod_container_status_waiting|kube_pod_container_status_terminated|kube_pod_container_status_terminated_reason|kube_pod_container_status_restarts_total|kube_pod_status_phase|kube_deployment_status_replicas|kube_deployment_status_replicas_ready|kube_deployment_spec_replicas|kube_horizontalpodautoscaler_info|kube_pod_spec_volumes_persistentvolumeclaims_info|kube_statefulset_metadata_generation|kube_statefulset_status_replicas|kube_statefulset_status_replicas_ready|kube_statefulset_replicas|kube_daemonset_metadata_generation|kube_daemonset_status_number_ready|kube_daemonset_status_desired_number_scheduled|kube_daemonset_status_current_number_scheduled|kube_job_owner|kube_job_status_succeeded|kube_job_status_failed|kube_job_status_active|kube_job_spec_completions|kube_job_complete_time|kube_cronjob_spec_suspend|kube_persistentvolume_capacity_bytes|kube_pod_container_status_waiting_reason|kube_replicaset_status_ready_replicas|kube_replicaset_spec_replicas|kube_replicaset_created|kube_pod_container_state_started)$"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].metric_relabel_configs[0].source_labels[0] | string | `"__name__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].action | string | `"keep"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].regex | string | `"kube-state-metrics"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_service_label_app_kubernetes_io_name"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[1].action | string | `"labelmap"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[1].regex | string | `"__meta_kubernetes_service_label_(.+)"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].job_name | string | `"kubernetes-nodes-cadvisor"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].kubernetes_sd_configs[0].role | string | `"node"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].metric_relabel_configs[0].action | string | `"keep"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].metric_relabel_configs[0].regex | string | `"^(container_cpu_usage_seconds_total|container_cpu_cfs_periods_total|container_cpu_cfs_throttled_periods_total|container_cpu_cfs_throttled_seconds_total|container_memory_working_set_bytes|container_network_receive_bytes_total|container_network_transmit_bytes_total|machine_cpu_cores|container_fs_reads_total|container_fs_writes_total|container_fs_reads_bytes_total|container_fs_writes_bytes_total)$"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].metric_relabel_configs[0].source_labels[0] | string | `"__name__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[0].replacement | string | `"kubernetes.default.svc:443"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[0].target_label | string | `"__address__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].regex | string | `"(.+)"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].replacement | string | `"/api/v1/nodes/$1/proxy/metrics/cadvisor"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_node_name"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].target_label | string | `"__metrics_path__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].scheme | string | `"https"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].scrape_interval | string | `"15s"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[2].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].honor_labels | bool | `true` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].job_name | string | `"opencost"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].action | string | `"keep"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].regex | string | `"^(kubecost_cluster_info|node_cpu_hourly_cost|node_ram_hourly_cost|node_gpu_hourly_cost|pv_hourly_cost|kube_node_labels|kubecost_cluster_management_cost|kube_persistentvolumeclaim_info|kubecost_node_is_spot|kube_persistentvolumeclaim_resource_requests_storage_bytes)$"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].source_labels[0] | string | `"__name__"` |  |
| prometheus.serverFiles."prometheus.yml".scrape_configs[3].static_configs[0].targets[0] | string | `"kubeadapt-opencost.kubeadapt.svc:9003"` |  |