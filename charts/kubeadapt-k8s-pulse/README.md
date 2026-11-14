# kubeadapt-k8s-pulse

![Version: 1.0.2](https://img.shields.io/badge/Version-1.0.2-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 3.0.1](https://img.shields.io/badge/AppVersion-3.0.1-informational?style=flat-square)

High-performance eBPF-based network metrics agent for Kubernetes

## Overview

The network monitor runs as a DaemonSet on every node. Its eBPF programs count each pod's traffic at the host side of the pod's network interface, and it sends one batch per node per minute to the Kubeadapt agent, which reports it as network cost.

### Key Features

- **Per-pod traffic**: sent and received bytes and packets for each pod, attached with TCX on kernel 6.6 and newer and with classic tc on older kernels
- **IPv4 and IPv6**: dual-stack accounting on kernel 5.10 and newer
- **Pod and node identity**: each node's pods are resolved through the Kubernetes API
- **Delivery to the agent**: batches the agent has not acknowledged are kept and retried
- **Overflow handling**: flows the kernel table has no room for are carried by a ring buffer instead of being lost
- **Prometheus metrics** and health endpoints on every node

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
helm pull oci://ghcr.io/kubeadapt/kubeadapt-helm/kubeadapt-k8s-pulse --version 1.0.2
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

Installed on its own, the DaemonSet serves only its Prometheus metrics. To report network cost, install it through the `kubeadapt` chart with `kubeadapt-k8s-pulse.enabled=true`, which also turns on the agent's listener and gives both sides a shared token. To send to an agent installed separately, set `config.export.enabled=true`, `config.export.agentEndpoint` and `config.export.tokenSecret` (a Secret with the agent's token under the key `token`).

## Uninstalling the Chart

To uninstall/delete the deployment:

```console
helm delete kubeadapt-k8s-pulse -n kubeadapt
```

## What the Pod Asks of the Node

Everything the DaemonSet's pod uses beyond an ordinary pod, and why. A platform team can write a policy exception from this table; [examples/network-monitor](../../examples/network-monitor) has one each for Pod Security Admission, Kyverno and Gatekeeper.

| What | In the pod spec | Why | Can it go? |
|------|-----------------|-----|------------|
| Node's network namespace | `hostNetwork: true` | The programs attach to the host side of every pod's network interface and follow interfaces as pods come and go. Both exist only in the node's network namespace. | No |
| A port of the node | container port `9090` (`config.metricsPort`) | Health probes and Prometheus metrics. A port of the node only because the pod uses the node's network. Open on every node address, without authentication. | The number can be changed |
| Node's PID and IPC namespaces | not used | | |
| Privileged container | `privileged: false`, `allowPrivilegeEscalation: false` | | `privileged: true` is a fallback for nodes whose security policy blocks the capability set |
| Root user | `runAsUser: 0` | The BPF filesystem and the cgroup tree are owned by root. | No |
| Capability `BPF` | `capabilities.add` | Create BPF maps and load the programs. | No |
| Capability `PERFMON` | `capabilities.add` | The kernel verifier accepts the programs only with it. | No |
| Capability `NET_ADMIN` | `capabilities.add` | Attach to pod network interfaces, follow interface changes, read connection tracking. | No |
| Capability `SYS_RESOURCE` | `capabilities.add` | Raise the locked-memory limit for BPF maps. | Yes, on kernel 5.11 and newer |
| Capability `SYS_PTRACE` | `capabilities.add` | Read other containers' executables for the runtime inventory. | Yes, with `EBPF_FINGERPRINT_ENABLED=false` in `env` |
| Every other capability | `capabilities.drop: [ALL]` | | |
| Root filesystem | `readOnlyRootFilesystem: true` | Writes go to an `emptyDir` at `/tmp`. | |
| Host path `/proc` | read-only, at `/host/proc` | The node's processes, for the container runtime inventory. | No |
| Host path `/sys/fs/bpf` | writable, propagation `HostToContainer`, created if missing | The pinned flow table that survives a restart, the lock that keeps one instance per node, and on Cilium its connection tracking maps. | No |
| Host path `/sys/fs/cgroup` | read-only | Find pod cgroups, attach the cgroup programs, read the container's own memory use. | No |
| Host path `/etc/cni/net.d` | read-only, at `/host/etc/cni/net.d`, created if missing | Identify the CNI and the encapsulation overhead it adds to each packet. | No |
| Host path `/var/run/ztunnel` | read-only, at `/host/var/run/ztunnel`, created if missing | Detect an Istio ambient mesh by its socket. | No |
| Seccomp profile | unset (`seccompProfile`) | The runtime's default profile must allow `bpf` and `perf_event_open` before it can be set. | |
| SELinux label | unset (`seLinuxOptions`) | Set it where the node's policy denies the default container label these operations. | |
| Kubernetes API | ClusterRole: `list`, `watch` pods; `get` nodes; `list` `ciliumenvoyconfigs.cilium.io` (`rbac.create`) | Pod identity for each node's traffic, the node's UID and zone, Envoy detection on Cilium. | Traffic is then reported without pod and node identity |
| Agent token | Secret volume, read-only | The token the agent checks on every batch. | Only with export off |

Against the Pod Security Standards, the host network, the host paths, the node port and the added capabilities are outside **baseline**; root and the unset seccomp profile are in addition outside **restricted**. The namespace must therefore allow the privileged level.

## Scheduling and Rollout

- **Which nodes.** One pod per Linux node. The default `tolerations` tolerate every taint, so dedicated and tainted pools are measured too; replace the list to narrow it. `nodeRequirements` keeps the DaemonSet off nodes where its pod can never start (AWS Fargate, virtual-kubelet, other operating systems): no pod is created for them, so none stays Pending. It is applied on top of `nodeSelector` and `affinity`.
- **Priority.** No priority class by default, so the scheduler never evicts a workload for the network monitor. On a node with less than the pod's requests free, the pod waits and that node is not measured until room appears. `priorityClass.create=true` gives it a class of its own with `preemptionPolicy: Never`: still no eviction of other pods, ordinary workloads cannot push it out, and after a restart it gets its place back before pods that were waiting. Use it on a busy cluster that runs near full. `priorityClassName=system-node-critical` guarantees a place on every node by evicting lower-priority pods on full nodes.
- **Rollout.** A change reaches `updateStrategy.rollingUpdate.maxUnavailable` of the nodes at a time, `25%` by default: four waves of about a minute, on any number of nodes. A pod that fails to become ready counts against that share, so a bad release stops there. A restart leaves a short gap in that node's measurements and does not touch pod traffic. `maxSurge` cannot be used, because the pod uses the node's network and only one instance per node attaches.
- **`helm upgrade --wait`.** Helm 3 waits until every node has the new pod and all but `maxUnavailable` of them are ready. Helm 4 waits until every pod is ready, so one pod waiting on a full node holds it until the timeout; pass `--wait=legacy` for the Helm 3 rule, or leave `--wait` out when turning the network monitor on for the first time.

## Private Registries

Set `image.repository` to your copy of the image and, where the registry needs credentials, `imagePullSecrets` (or `global.imagePullSecrets` in the `kubeadapt` chart, which also covers the agent and the upgrade Job). The pull policy is `IfNotPresent`: release tags are not moved, and a pull on every pod start on every node runs into registry rate limits on a large cluster.

## Exported Metrics

### Traffic

| Metric | Type | Description |
|--------|------|-------------|
| `kubeadapt_connection_traffic_bytes_total` | Counter | Bytes the node's pods sent, by protocol (use `rate()` for throughput) |
| `kubeadapt_connection_traffic_packets_total` | Counter | Packets the node's pods sent, by protocol |
| `kubeadapt_overflow_bytes_drained_total` | Counter | Bytes carried by the overflow ring buffer, by protocol; add to the bytes above for the total |

### Health

| Metric | Type | Description |
|--------|------|-------------|
| `kubeadapt_bpf_load_status` | Gauge | 1 when the BPF programs loaded |
| `kubeadapt_attach_mode` | Gauge | Attach mode in use (TCX or classic tc) |
| `kubeadapt_veth_coverage_ratio` | Gauge | Share of pod interfaces pulse is attached to |
| `kubeadapt_bpf_map_utilization_percent` | Gauge | Fill level of the kernel flow table |
| `kubeadapt_pod_resolver_synced` | Gauge | 1 when pod identity is available |
| `kubeadapt_duplicate_pulse_instance` | Gauge | 1 when another instance already runs on the node |
| `kubeadapt_lost_events_total` | Counter | Observations that did not reach a batch, by site |
| `kubeadapt_pulse_retry_buffer_batches` | Gauge | Batches waiting for the agent |
| `kubeadapt_pulse_export_acked_batches_total` | Counter | Batches the agent acknowledged |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| capabilities[0] | string | `"BPF"` |  |
| capabilities[1] | string | `"PERFMON"` |  |
| capabilities[2] | string | `"NET_ADMIN"` |  |
| capabilities[3] | string | `"SYS_RESOURCE"` |  |
| capabilities[4] | string | `"SYS_PTRACE"` |  |
| config.connectionTracking | bool | `true` |  |
| config.enableProfiling | bool | `false` |  |
| config.export.agentEndpoint | string | `""` |  |
| config.export.enabled | bool | `false` |  |
| config.export.tokenSecret | string | `""` |  |
| config.logFormat | string | `"json"` |  |
| config.logLevel | string | `"info"` |  |
| config.metricsPort | int | `9090` |  |
| config.profilingPort | int | `6060` |  |
| dnsPolicy | string | `"ClusterFirstWithHostNet"` |  |
| enabled | bool | `true` |  |
| env[0].name | string | `"EBPF_RETRY_BUFFER_SIZE"` |  |
| env[0].value | string | `"120"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-pulse"` |  |
| image.tag | string | `"v3.0.1"` |  |
| imagePullSecrets | list | `[]` |  |
| nodeRequirements[0].key | string | `"kubernetes.io/os"` |  |
| nodeRequirements[0].operator | string | `"In"` |  |
| nodeRequirements[0].values[0] | string | `"linux"` |  |
| nodeRequirements[1].key | string | `"eks.amazonaws.com/compute-type"` |  |
| nodeRequirements[1].operator | string | `"NotIn"` |  |
| nodeRequirements[1].values[0] | string | `"fargate"` |  |
| nodeRequirements[2].key | string | `"type"` |  |
| nodeRequirements[2].operator | string | `"NotIn"` |  |
| nodeRequirements[2].values[0] | string | `"virtual-kubelet"` |  |
| nodeSelector | object | `{}` |  |
| priorityClass.create | bool | `false` |  |
| priorityClass.name | string | `""` |  |
| priorityClass.value | int | `1000000` |  |
| priorityClassName | string | `""` |  |
| privileged | bool | `false` |  |
| rbac.create | bool | `true` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"384Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| seLinuxOptions | object | `{}` |  |
| seccompProfile | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| terminationGracePeriodSeconds | int | `45` |  |
| tolerations[0].operator | string | `"Exists"` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.rollingUpdate.maxUnavailable | string | `"25%"` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |

## Troubleshooting

`<ds>` is the DaemonSet's name: `kubectl -n <namespace> get daemonset -l app.kubernetes.io/component=kubeadapt-k8s-pulse`.

```bash
kubectl -n <namespace> get daemonset <ds>
```

`READY` should reach `DESIRED`: the number of nodes the DaemonSet targets. `CURRENT` is the number of pods that exist.

### `helm install` or `helm upgrade` Fails With `admission webhook ... denied the request`

A policy engine that also checks workload objects has rejected the DaemonSet itself, so nothing was deployed. Kyverno does this by default; its message lists every policy and rule the pod template fails:

```
Error: INSTALLATION FAILED: admission webhook "validate.kyverno.svc-fail" denied the request:
resource DaemonSet/<namespace>/<ds> was blocked due to the following policies
disallow-host-namespaces:
  autogen-host-namespaces: ...
```

Apply an exception for the listed rules ([examples/network-monitor/kyverno-policy-exception.yaml](../../examples/network-monitor/kyverno-policy-exception.yaml)) and run the command again.

### `CURRENT` Is Lower Than `DESIRED`: Pods Are Not Created

The DaemonSet exists, and an admission controller has denied its pods: Pod Security Admission, Gatekeeper, Kyverno or a vendor's webhook. The DaemonSet's events carry its answer, with the policy and the field:

```bash
kubectl -n <namespace> get events --sort-by=.lastTimestamp \
  --field-selector involvedObject.kind=DaemonSet,involvedObject.name=<ds>
```

| The event says | Cause | What to do |
|----------------|-------|------------|
| `violates PodSecurity "baseline:latest"` or `"restricted:latest"` | The namespace enforces a Pod Security level | Label the namespace `pod-security.kubernetes.io/enforce=privileged` |
| `admission webhook "validate.kyverno.svc-fail" denied the request` followed by policy and rule names | A Kyverno policy that checks pods only | Apply a PolicyException for the listed rules |
| `admission webhook "validation.gatekeeper.sh" denied the request: [<constraint>]` | A Gatekeeper constraint | Exclude the namespace from the listed constraints |
| another webhook's name | A vendor admission controller | Add an exclusion for the namespace or the image in that product |
| `exceeded quota` or `no PriorityClass with name` | `priorityClassName` names a class the namespace may not use, or one that does not exist | Leave it empty, or use `priorityClass.create=true` |

[examples/network-monitor](../../examples/network-monitor) has the namespace label, the Kyverno exception and the Gatekeeper constraints.

### `READY` Is Lower Than `CURRENT`: Pods Exist and Are Not Ready

```bash
kubectl -n <namespace> get pods -l app.kubernetes.io/component=kubeadapt-k8s-pulse -o wide --no-headers | awk '$2 != "1/1"'
kubectl -n <namespace> describe pod <pod>
kubectl -n <namespace> logs <pod> --tail=50
```

| The pod is | And shows | Cause | What to do |
|------------|-----------|-------|------------|
| `Pending` | event `Insufficient cpu` or `Insufficient memory` | The node has less than the pod's requests free, and the pod does not preempt | It starts when room appears. For a guaranteed place, see Priority above |
| `Pending` | event `node(s) had untolerated taint` | `tolerations` was narrowed | Add the taint, or leave the pool out with `nodeRequirements` |
| `ImagePullBackOff`, `ErrImagePull` | the registry's answer in the events (`toomanyrequests`, `unauthorized`, `no match for platform`) | Rate limit, missing credentials, or an image without the node's architecture in a private copy | `image.repository`, `imagePullSecrets`; copy all platforms of the image |
| `CreateContainerError`, `RunContainerError` | a host path or security option in the message | The node or its runtime refuses a mount or an option | Compare with the table under "What the Pod Asks of the Node" |
| `Running`, not ready | log: `permission denied` or `operation not permitted` while loading or attaching the programs | A node security policy (SELinux, AppArmor, seccomp) denies the BPF operations. On an SELinux node the node's audit log has a matching `avc: denied` line | `seLinuxOptions`, `seccompProfile`, or `privileged: true` |
| `Running`, not ready | log: the metrics port cannot be bound | Another process on the node holds the port | `config.metricsPort` |
| `Running`, ready at first, then not | log: sends to the agent fail | Nothing is acknowledged for three export windows (three minutes): the agent is down, its listener is off, the token differs, or a NetworkPolicy blocks node addresses | Check the agent pod and the `<name>-agent-pulse` Service's endpoint; see `agent.networkPolicy` in the `kubeadapt` chart |
| `CrashLoopBackOff` | log of the previous run: `kubectl logs <pod> --previous` | Kernel older than 5.10 | See Prerequisites |

### `DESIRED` Is Lower Than Expected: Nodes Without a Pod

```bash
comm -23 \
  <(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort) \
  <(kubectl -n <namespace> get pods -l app.kubernetes.io/component=kubeadapt-k8s-pulse -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort)
kubectl get node <node> -o jsonpath='{.spec.taints}{"\n"}{.metadata.labels}{"\n"}'
```

A node is left out by `nodeRequirements` (operating system, AWS Fargate, virtual-kubelet), by `nodeSelector` or `affinity`, or by a taint that `tolerations` does not cover.

### Checking the Programs

On the **worker node**:

```bash
sudo bpftool prog list | grep tc_
sudo bpftool map list | grep connection_flows
```

Through **kubectl**:

```bash
kubectl -n <namespace> port-forward <pod> 9090:9090
curl -s http://localhost:9090/metrics | grep kubeadapt
```
