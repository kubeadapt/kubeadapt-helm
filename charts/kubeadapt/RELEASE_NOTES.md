## 1.1.0

Fast channel only. A patch release promotes it to stable.

**Network telemetry**

- `kubeadapt-k8s-pulse.enabled=true` now connects the network agent to the agent. The agent listens on `global.pulseChannel.port` (9091, published on its Service) and rejects any push without a bearer token. The chart generates the token into `<name>-pulse-token` and reuses it on every upgrade; the network agent reads it from a mounted file.
- **The channel is plaintext gRPC.** The token authenticates the network agent, but it travels unencrypted inside the cluster network, and so do the flow batches.
- **Images:** the agent moves to `kubeadapt-k8s-agent:v3.2.0` and the network agent to `kubeadapt-k8s-pulse:v3.2.0`. Both are required: pulse v3.1.0 refuses to send the token without TLS, and agent v3.0.1 has no flow listener.
- If you render the chart without cluster access (`helm template`, Argo CD), create that Secret yourself (key `token`) and set `global.pulseChannel.existingSecret`: such a render cannot see the generated Secret and would replace the token each time.
- Both agents read the token only at startup. After you change the token, restart the agent Deployment and the network agent DaemonSet.
- `agent.networkPolicy.pulseFrom` adds a NetworkPolicy that limits port 9091 to the sources you list. It has no default, because pulse runs with `hostNetwork` and whether a podSelector matches it depends on the network plugin (see `values.yaml`).
- The agent ClusterRole grants `endpointslices` list/watch, which the agent needs since v3.1.0.
- The `kubeadapt-k8s-pulse` 1.1.0 subchart is packaged from this repository, so every release ships the pulse chart of the same commit. It sets the network agent's memory-limit variable from its container limit, and mounts the node's CNI configuration (`kubeadapt-k8s-pulse.cniConfigDir`, default `/etc/cni/net.d`) read-only so encapsulation overhead is measured on overlay datapaths.

**Kubelet stats**

- The agent reads kubelet stats, the only source of per-pod network bytes, straight from each kubelet with `nodes/stats` `get`, and falls back per node to the API server's node proxy where a kubelet cannot be used directly (its serving certificate does not chain to the cluster CA, or port 10250 is unreachable).
- `agent.rbac.kubeletProxyFallback` (default `true`) grants the `nodes/proxy` `get` that fallback needs. That grant is exec-capable: the kubelet authorises exec, attach and port-forward as `nodes/proxy`, and a WebSocket upgrade is a GET. Set it to `false` when every kubelet serving certificate is signed by the cluster CA and the agent can reach port 10250 on every node.

**Security**

- The upgrader loses `escalate`. It could rewrite its own ClusterRole to `*` and become cluster-admin. It now writes only RBAC whose permissions it already holds.
- The namespaced Role with `secrets` get/list, ConfigMap writes and Job create was bound to the agent's service account even with auto-upgrade off. It now exists only with `agent.autoUpgrade.enabled`, as `<name>-upgrader-sidecar`, trimmed to what the upgrader sidecar calls.
- Unused ClusterRole grants are removed: `replicationcontrollers`, `networkpolicies`, Karpenter `nodeclaims`, `watch` on `metrics.k8s.io`.

**Shutdown**

- `terminationGracePeriodSeconds` is 120 (`agent.terminationGracePeriodSeconds`) whether or not the spool is on. With the spool off it was the Kubernetes default of 30s, shorter than the agent's 100s shutdown drain.

**Upgrading**

- Auto-upgrade applies 1.1.0 when the network agent is disabled (the default). With `kubeadapt-k8s-pulse.enabled=true`, 1.1.0 adds a ClusterRole that the 1.0.x upgrader cannot read, so the upgrade Job fails before changing anything: run `helm upgrade` by hand once.
- From 1.1.0 on, a release that adds a permission to the agent or upgrader ClusterRole also needs a manual `helm upgrade`, because the upgrader can no longer grant itself rights it does not hold.
- Auto-upgrade no longer offers 1.1.0 to 0.17.x or 0.18.x installs. Upgrade those by hand, following the 1.0.0 notes.

## 1.0.8

- The agent pod meets the Kubernetes **restricted** Pod Security Standard by default: non-root (UID/GID 65532, the image's own user), RuntimeDefault seccomp, no privilege escalation, all capabilities dropped, read-only root filesystem. The agent writes only to its emptyDir volumes (the spool/state directory and a new 64Mi `/tmp`). Configure with `agent.podSecurityContext`, `agent.securityContext` and `agent.autoUpgrade.securityContext`.
- **OpenShift:** the restricted-v2 SCC assigns UIDs from the namespace range. Install with `--set agent.podSecurityContext.runAsUser=null --set agent.podSecurityContext.runAsGroup=null --set agent.podSecurityContext.fsGroup=null`.
- No longer marked as a pre-release; `appVersion` reports the deployed agent release (`v3.0.1`).
- The auto-upgrade sidecar moves to `kubeadapt-k8s-upgrader:v3.0.2`: its upgrade Job now meets the restricted standard too and runs under the chart's upgrader service account (earlier releases referenced a service account the chart does not create, so upgrade Jobs could not start).
- Documentation: one compatibility matrix, uninstall notes, and `existingSecret` as the recommended way to provide the agent token.

## 1.0.7

- Grant the agent ClusterRole `get` on `nodes/proxy` and `nodes/stats` so the agent can read the kubelet Summary API. It is the only source of per-pod network byte counters: `metrics.k8s.io` carries CPU and memory only, so without this rule `network_rx_bytes` and `network_tx_bytes` are always zero. `nodes/proxy` serves the `api_proxy` transport and `nodes/stats` the direct kubelet transport. The verb is `get` alone.

Images: `kubeadapt-k8s-agent:v3.0.1`, `kubeadapt-k8s-upgrader:v3.0.1`, `kubeadapt-k8s-pulse:v3.0.1` (subchart 1.0.1).

## 1.0.6

There is no 1.0.5 release. The version was claimed by a pull request that closed without merging.

- Add chart-side plumbing for an agent write-ahead spool for network telemetry: an emptyDir volume at `agent.spool.mountPath` (default `/var/lib/kubeadapt`), bounded by `agent.spool.sizeLimit` (2Gi) and `agent.spool.maxBytes` (1 GiB), the matching `KUBEADAPT_SPOOL_DIR` and `KUBEADAPT_SPOOL_MAX_BYTES` variables, and a 120s termination grace period. Agent images that predate spool support ignore these settings. No PersistentVolume is created. Set `agent.spool.enabled=false` to opt out.
- Set `GOMEMLIMIT` on the agent container from its own memory limit via the Downward API, so the Go runtime collects before the container limit instead of being OOMKilled.
- The bundled `kubeadapt-k8s-pulse` subchart stays at 1.0.1. Pulse chart 1.0.2 (`EBPF_RETRY_BUFFER_SIZE=120`), published in the same change, is not bundled by this release.

Images: `kubeadapt-k8s-agent:v3.0.1`, `kubeadapt-k8s-upgrader:v3.0.1`, `kubeadapt-k8s-pulse:v3.0.1` (subchart 1.0.1).

## 1.0.4

- Raise the agent resource limits to 2000m CPU / 16Gi memory (from 1000m / 1Gi). The agent is one Deployment per cluster, so its memory scales with total cluster size; the 1Gi limit bound at roughly 1000 nodes. A limit is a ceiling, not a reservation, so smaller clusters do not consume the headroom. Requests are unchanged at 100m / 256Mi. See the sizing table in `values.yaml`.

Images: `kubeadapt-k8s-agent:v3.0.1`, `kubeadapt-k8s-upgrader:v3.0.1`, `kubeadapt-k8s-pulse:v3.0.1` (subchart 1.0.1).

## 1.0.3

- Bundle `kubeadapt-k8s-pulse` chart 1.0.1: the pulse DaemonSet memory request rises to 256Mi (from 128Mi). Limits are unchanged at 500m / 384Mi.

Images: `kubeadapt-k8s-agent:v3.0.1`, `kubeadapt-k8s-upgrader:v3.0.1`, `kubeadapt-k8s-pulse:v3.0.1` (subchart 1.0.1).

## 1.0.2

- Raise the agent memory request to 256Mi (from 128Mi). The agent measured 141Mi on a 3-node, 208-pod cluster, above the old request. Limits are unchanged at 1000m / 1Gi.
- The bundled `kubeadapt-k8s-pulse` subchart stays at 1.0.0. Pulse chart 1.0.1, published in the same change, is picked up in kubeadapt 1.0.3.
- Chart-testing values now point at the current agent image (`public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-agent:v3.0.1`) instead of the pre-rebrand registry alias.

Images: `kubeadapt-k8s-agent:v3.0.1`, `kubeadapt-k8s-upgrader:v3.0.1`, `kubeadapt-k8s-pulse:v3.0.1` (subchart 1.0.0).

## 1.0.1

- Fix install failure when deploying the chart into a non-default namespace alongside an existing install. Cluster-scoped resources (`ClusterRole`, `ClusterRoleBinding`) for the agent and upgrader are now suffixed with the release namespace when it differs from the chart's default namespace (`kubeadapt`), so multiple installs across namespaces no longer collide on cluster-wide resource names.
- Existing installs in the `kubeadapt` namespace are unaffected — resource names are preserved and `helm upgrade` performs no renames.

## 1.0.0

**BREAKING CHANGES — manual upgrade required from 0.18.x.**

- **Image registry alias migrated.** The previous registry will become unavailable.
- **Image binaries renamed:**
  - `kubeadapt-agent` → `kubeadapt-k8s-agent`
  - `kubeadapt-upgrader` → `kubeadapt-k8s-upgrader`
- **Subchart renamed:** `ebpf-agent` → `kubeadapt-k8s-pulse`. If you were overriding subchart values under the `ebpf-agent:` key in your `values.yaml`, **rename it to `kubeadapt-k8s-pulse:`** before upgrading. Otherwise, your overrides will be silently ignored and defaults will apply.
- Bumped images:
  - `kubeadapt-k8s-agent:v3.0.1`
  - `kubeadapt-k8s-upgrader:v3.0.1`
  - `kubeadapt-k8s-pulse:v3.0.1` (was `ebpf-agent:v0.2.0`)

Auto-upgrade from 0.18.x is blocked. Customers must run `helm upgrade` manually after reviewing values overrides.

## 0.18.6

- Support `existingSecret` for agent token (skip chart-managed Secret when set)
- Fix missing liveness and readiness probes on agent container
