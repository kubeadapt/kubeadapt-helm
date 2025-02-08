# Chart Signature Verification Guide

## Public Key
The KubeAdapt Helm charts are signed using GPG with the following key:

- Key ID: 948AD9EDA6BD626E
- Fingerprint: 3C8109B607AD3E119B7033D8948AD9EDA6BD626E

## Importing the Public Key


### Method 1: Direct from repository
```bash
curl -fsSL https://kubeadapt.github.io/kubeadapt-helm/pgp_keys.asc | gpg --import
```

### Method 2: From Artifact Hub (after registration)
```bash
curl -fsSL https://artifacthub.io/packages/helm/kubeadapt/kubeadapt/pgp_keys | gpg --import
```

### Verifying Charts
1. Download the chart:
   ```bash
   helm pull kubeadapt/kubeadapt --version <version>
   ```

2. Verify the signature:
   ```bash
   helm verify kubeadapt-<version>.tgz
   ```

#### Troubleshooting
- If verification fails, ensure:
  1. Public key is imported correctly
  2. Chart hasn't been tampered with
  3. Using correct version of chart
  4. If chart is old, check if it was signed with previous key