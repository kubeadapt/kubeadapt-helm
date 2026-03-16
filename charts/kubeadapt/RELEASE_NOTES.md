## 0.18.5

- Bump upgrader v0.1.3 to v0.1.4
- Add blocked edge for 0.18.4 (`--reuse-values` overrides new chart defaults)

**kubeadapt-upgrader v0.1.4**

- Replace `--reuse-values` with `--reset-then-reuse-values` in helm upgrade job
- Drain stale ticker ticks after long-running upgrades to prevent burst retries
