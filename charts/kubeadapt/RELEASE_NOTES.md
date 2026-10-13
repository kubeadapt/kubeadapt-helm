## 1.1.0

**Security**

- The agent no longer holds `nodes/proxy` `get`. That grant is exec-capable: the kubelet authorises exec, attach and port-forward as `nodes/proxy`, and a WebSocket upgrade is a GET, so a leaked agent token could run commands in every pod on every node. The agent reads kubelet stats straight from each kubelet with `nodes/stats` `get`, verifying the kubelet's serving certificate against the cluster CA. On a cluster whose kubelets self-sign (serverTLSBootstrap off), set `agent.rbac.kubeletProxyFallback=true` to let the agent fall back to the API server proxy; that brings the exec-capable grant back.
- The upgrader loses `escalate`. It could rewrite its own ClusterRole to `*` and become cluster-admin. It now writes only RBAC whose permissions it already holds.
- The namespaced Role with `secrets` get/list, ConfigMap writes and Job create was bound to the agent's service account even with auto-upgrade off. It now exists only with `agent.autoUpgrade.enabled`, as `<name>-upgrader-sidecar`, trimmed to what the upgrader sidecar calls.
- Unused ClusterRole grants are removed: `replicationcontrollers`, `networkpolicies`, Karpenter `nodeclaims`, `watch` on `metrics.k8s.io`.

**Network telemetry**

- `kubeadapt-k8s-pulse.enabled=true` now connects the network agent to the agent. The agent listens on `global.pulseChannel.port` (9091, published on its Service) and rejects any push without a bearer token. The chart generates the token into `<name>-pulse-token` and reuses it on every upgrade; the network agent reads it from a mounted file.
- **The channel is plaintext gRPC.** The token authenticates the network agent, but it travels unencrypted inside the cluster network, and so do the flow batches.
- If you render the chart without cluster access (`helm template`, Argo CD), create that Secret yourself (key `token`) and set `global.pulseChannel.existingSecret`: such a render cannot see the generated Secret and would replace the token each time.
- `agent.networkPolicy.pulseFrom` adds a NetworkPolicy that limits port 9091 to the sources you list. It has no default, because pulse runs with `hostNetwork` and whether a podSelector matches it depends on the network plugin (see `values.yaml`).
- **Images:** the agent must be a release with the pulse token check. The network agent must be a release cut from pulse main after the TLS client was removed: released v3.1.0 refuses to send a token without TLS, and v3.0.1, which the chart still pins, does not export at all. Until that release exists and is pinned, enabling the network agent delivers nothing.
- The agent ClusterRole grants `endpointslices` list/watch, which the agent needs since v3.1.0.

**Shutdown**

- `terminationGracePeriodSeconds` is 120 (`agent.terminationGracePeriodSeconds`) whether or not the spool is on. With the spool off it was the Kubernetes default of 30s, shorter than the agent's 100s shutdown drain.

**Upgrading**

- Auto-upgrade applies 1.1.0 when the network agent is disabled (the default). With `kubeadapt-k8s-pulse.enabled=true`, 1.1.0 adds a ClusterRole that the 1.0.x upgrader cannot read, so the upgrade Job fails and rolls back: run `helm upgrade` by hand once.
- From 1.1.0 on, a release that adds a permission to the agent or upgrader ClusterRole also needs a manual `helm upgrade`, because the upgrader can no longer grant itself rights it does not hold.

## 1.0.8

- The agent pod meets the Kubernetes **restricted** Pod Security Standard by default: non-root (UID/GID 65532, the image's own user), RuntimeDefault seccomp, no privilege escalation, all capabilities dropped, read-only root filesystem. The agent writes only to its emptyDir volumes (the spool/state directory and a new 64Mi `/tmp`). Configure with `agent.podSecurityContext`, `agent.securityContext` and `agent.autoUpgrade.securityContext`.
- **OpenShift:** the restricted-v2 SCC assigns UIDs from the namespace range. Install with `--set agent.podSecurityContext.runAsUser=null --set agent.podSecurityContext.runAsGroup=null --set agent.podSecurityContext.fsGroup=null`.
- No longer marked as a pre-release; `appVersion` reports the deployed agent release (`v3.0.1`).
- The auto-upgrade sidecar moves to `kubeadapt-k8s-upgrader:v3.0.2`: its upgrade Job now meets the restricted standard too and runs under the chart's upgrader service account (earlier releases referenced a service account the chart does not create, so upgrade Jobs could not start).
- Documentation: one compatibility matrix, uninstall notes, and `existingSecret` as the recommended way to provide the agent token.

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
