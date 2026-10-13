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
