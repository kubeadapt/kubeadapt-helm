## 1.2.0

- Every install gets a `<name>-agent-rotated-token` Secret, created empty, where the agent stores a replacement token, and a `<name>-agent-token` Role and RoleBinding with `get` and `update` on that Secret only. Upgrades render back whatever is in it, so neither `helm upgrade` nor an auto-upgrade replaces the agent's token; `helm uninstall` deletes it. The agent never writes the token Secret (`<name>-agent` or `agent.config.existingSecret`), so External Secrets Operator, Sealed Secrets or a GitOps sync can own that one.
- Both token Secrets are also mounted as files in the agent and auto-upgrade containers, at `/var/run/secrets/kubeadapt/token/token` and `/var/run/secrets/kubeadapt/rotated-token/token`, so a new token is visible without a restart. `KUBEADAPT_AGENT_TOKEN` stays in the environment for agent and upgrader releases that read only that.
- **SecureOps opt-in**, off by default: `secureops.enabled`. It is a permission you grant. With it false, the chart installs the same objects as 1.0.8. Turn it on with `helm upgrade kubeadapt kubeadapt/kubeadapt -n kubeadapt --reuse-values --set secureops.enabled=true`; a release installed from an earlier chart version needs `--reset-then-reuse-values` instead of `--reuse-values`.
- It grants the agent `get` on Secrets in every namespace, used only for the image pull secrets your workloads reference (no `list` or `watch` outside the release namespace); `list` on Roles, ClusterRoles, RoleBindings, ClusterRoleBindings, Gateways and HTTPRoutes; and `create` and `delete` on Secrets in the release namespace, for the copy of a pull secret one scan Job uses, owned by that Job. The rules live in `<name>-agent-secureops` (ClusterRole, Role and their bindings).
- It creates the scanner service account `<name>-secureops-scanner`, with no Kubernetes API token. `secureops.scanner.cloudIdentity` adds an IRSA role ARN, a GKE Workload Identity service account or an AKS Workload Identity client ID, for private registries that nodes reach with their own cloud identity. EKS Pod Identity is configured in EKS, not in the chart.
- It creates `<name>-secureops-scan`, a PriorityClass at -10 with `preemptionPolicy: Never`. Set `secureops.priorityClass.create=false` and `secureops.priorityClass.name` to use an existing class.
- `secureops.scanner` sets the scan Job: image pinned by digest, 200m CPU / 256Mi requested, 768Mi limit, a 4Gi scratch volume, 2 Jobs at once (1 to 8), a 15 minute deadline, tolerations and nodeSelector.
- It creates `<name>-secureops-scan`, a NetworkPolicy on scan Job pods: no ingress; egress only to DNS (53 and 5353), port 443 on any host, the port of `agent.config.backendUrl` when it is not 443, the EKS Pod Identity Agent, and the GKE metadata server with GKE Workload Identity. `secureops.scanner.networkPolicy.extraEgress` adds rules; `secureops.scanner.networkPolicy.enabled=false` turns it off for network plugins that do not enforce NetworkPolicies.
- `global.imagePullSecrets` adds pull secrets for Kubeadapt's own images to the agent's service account and the scanner's.
- With `agent.autoUpgrade.enabled`, the upgrader holds the same cluster-wide rules, because Kubernetes only lets it update the agent's SecureOps binding if it holds them, and manages the PriorityClass by name.

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
