# GPG Key Rotation & Backup Guide

## Current Key Information

- Key ID: 948AD9EDA6BD626E
- Fingerprint: 3C8109B607AD3E119B7033D8948AD9EDA6BD626E
- Validity: 10 years (expires: 2035)
- Email: authors@kubeadapt.io

## Backup Process

For security reasons, the detailed backup process for private keys is documented in our internal wiki. Only authorized maintainers should perform key backup and rotation procedures.

Public key is maintained in the repository at `kubeadapt-helm/gpg/pgp_keys.asc`

## Emergency Recovery Process

If the private key needs to be rotated (lost/compromised):

1. Contact repository maintainers immediately at authors@kubeadapt.io
2. Repository maintainers will:
   - Generate new signing key following internal security procedures
   - Update repository with new public key information
   - Keep old public key for verifying existing releases
   - Create security advisory for key transition

