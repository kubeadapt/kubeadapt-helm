# Blocked Edges

This directory contains YAML files that define blocked upgrade paths. When a problematic version is discovered, a blocked-edge file is added via PR to prevent clusters from upgrading to that version.

## Directory Structure

```
blocked-edges/
├── kubeadapt/           # Blocked edges for kubeadapt chart
│   └── {version}-{issue-name}.yaml
├── kubeadapt-k8s-pulse/ # Blocked edges for kubeadapt-k8s-pulse chart
│   └── {version}-{issue-name}.yaml
└── README.md
```

## File Format

```yaml
# Required fields
to: "0.16.0"                    # Target version that is blocked
from: "0\\.15\\..*"             # Regex: versions blocked from upgrading
name: EKS-IRSA-Authentication-Bug
message: |
  Description of the issue and workaround.

# Optional fields
url: https://github.com/kubeadapt/kubeadapt-helm/issues/123

matchingRules:
  - type: Always               # Affects all clusters
  # OR
  - type: Platform
    platforms: [eks]           # Only affects specific platforms

redirect_to: "0.16.1"          # Redirect to fixed version
```

## Example: Platform-Specific Block

```yaml
# blocked-edges/kubeadapt/0.16.0-eks-irsa-issue.yaml

to: "0.16.0"
from: "0\\.15\\..*"
name: EKS-IRSA-Authentication-Bug
url: https://github.com/kubeadapt/kubeadapt-helm/issues/123
message: |
  IRSA authentication fails on EKS clusters due to a race condition
  in the IAM role assumption. This affects clusters using IRSA for
  AWS service authentication.

  Workaround: Use 0.16.1 instead which contains the fix.

matchingRules:
  - type: Platform
    platforms: [eks]

redirect_to: "0.16.1"
```

## Adding a Blocked Edge

1. Create a new YAML file in the appropriate chart directory
2. Use naming convention: `{version}-{short-issue-name}.yaml`
3. Fill in required fields (to, from, name, message)
4. Add optional fields as needed
5. Submit PR for review

## Validation

All blocked-edge files are validated on every pull request by `scripts/validate-blocked-edges.sh` (the `blocked-edges` job, part of the required `gate` check):
- YAML syntax check
- Required fields validation
- Regex validation for `from` field
- `to` and `redirect_to` must be exact versions that were released (a `<chart>-<version>` tag exists)
- `redirect_to` chains must terminate (no cycles)

ingestion-api reads this directory live from `main`, so a merged edge takes effect without a chart release. An edge blocks exactly one `to` version: to block a source range from several releases, add one file per target version.
