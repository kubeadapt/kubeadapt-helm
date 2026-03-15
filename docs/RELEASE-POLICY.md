# Release Policy — kubeadapt Helm Charts

This document describes how releases are cut, promoted, and blocked for the kubeadapt Helm chart.

---

## Channels

Two channels exist: `fast` and `stable`.

**`fast`**
New releases land here first. Higher update frequency. Intended for clusters comfortable with early updates and willing to catch issues before they reach production-grade rollout.

**`stable`**
Production-recommended. A release reaches `stable` by cutting a new patch version that includes `stable` in its `channels` list in `upgrade-metadata.yaml`. There's no automatic promotion — it's a deliberate decision.

Clusters configure their channel via `agent.autoUpgrade.channel` in `values.yaml`. Default is `stable`.

---

## Promotion Flow

Promotion from `fast` to `stable` follows a patch release approach:

1. **Cut a new minor** (e.g., `0.19.0`) with `channels: [fast]` in `upgrade-metadata.yaml` and `artifacthub.io/prerelease: "true"` in `Chart.yaml`.
2. **Validate on fast** — let it run on real clusters, watch metrics, confirm no regressions.
3. **Cut a patch release** (e.g., `0.19.1`) with `channels: [stable, fast]` and `artifacthub.io/prerelease: "false"` to promote to stable.

This is a manual decision. No tooling promotes releases automatically.

---

## upgradeFrom Policy

Each release declares which versions can upgrade to it via the `upgradeFrom` field in `upgrade-metadata.yaml`.

Rules of thumb:
- Always include the immediately previous version.
- Typically cover the last 2-3 versions for smooth rollout across clusters that may have missed an intermediate release.
- The exact list is a per-release judgment call. Err on the side of more coverage rather than less.

Example:
```yaml
upgradeFrom:
  - "0.18.1"
  - "0.18.0"
  - "0.17.0"
```

Versions not listed in `upgradeFrom` won't receive an upgrade offer from the auto-upgrade system.

---

## Blocked Edges

A blocked edge prevents the upgrader from offering a specific upgrade path, even if the target version is in the cluster's channel.

**When to block:**
- Critical bugs discovered post-release
- Security issues in a specific version
- Known bad upgrade paths (e.g., wrong default values, data migration issues)

**Format:** YAML file in `blocked-edges/kubeadapt/` with these fields:

```yaml
to: "0.18.0"
from: "0\\.17\\..*|0\\.16\\..*"
name: Short-Descriptive-Name
message: |
  Explain what's wrong and what the user should do instead.
matchingRules:
  - type: Always
redirect_to: "0.18.1"   # optional — suggest a safe target
```

- `to`: the version being blocked (exact semver)
- `from`: regex matching source versions affected
- `redirect_to`: optional safe alternative to offer instead

CI validates blocked edge files automatically on every PR that touches them.

---

## Release Checklist

Follow these steps when cutting a release:

1. **Update `Chart.yaml`**
   - Bump `version` to the new semver
   - Set `artifacthub.io/prerelease: "true"` for fast-only, `"false"` for stable

2. **Update `upgrade-metadata.yaml`**
   - Set `chartVersion` to match `Chart.yaml` version exactly
   - Set `upgradeFrom` list (see policy above)
   - Set `channels: [fast]` or `channels: [stable, fast]`

3. **Open a PR**
   CI runs `validate-upgrade-metadata.yaml` which checks:
   - `chartVersion` matches `Chart.yaml` version
   - `channels` contains only `stable` or `fast`
   - `artifacthub.io/prerelease` is consistent with channel (`true` for fast-only, `false` for stable)
   - Required fields (`chartVersion`, `upgradeFrom`, `channels`) are present

4. **Merge to main**
   `publish.yml` runs: packages the chart, pushes to GHCR, creates a GitHub Release, and sets the prerelease flag via `gh release edit`.

5. **Verify on GitHub**
   Confirm the release appears with the correct badge: "Pre-release" for fast-only, "Latest" for stable.
