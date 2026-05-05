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
