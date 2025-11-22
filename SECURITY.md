# Security Policy

## Supported Versions and Upstream Reporting

Each Helm chart currently supports the designated application version in the Chart.yaml. There is a chance a security issue you've discovered may not be with the Helm chart but with the upstream application. Please visit that application's Security policy document to find out how to report the security issue.

* [Security Policy for Prometheus](https://github.com/prometheus/prometheus/blob/main/SECURITY.md)
* [Security Policy for OpenCost](https://github.com/opencost/opencost/blob/develop/SECURITY.md)

## Reporting a Vulnerability

We take the security of Kubeadapt and its ecosystem seriously. If you believe you have found a security vulnerability, please report it by opening a security advisory:

1. Go to the Security tab of this repository
2. Click on "Report a vulnerability"
3. Fill out the form with a detailed description of the vulnerability

Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.

A repository owner/maintainer will respond as fast as possible to coordinate confirmation of issue and remediation.

## Chart Signing and Verification

All Helm charts in this repository are signed using GPG. The signing key details are:

```
Key ID: 948AD9EDA6BD626E
Fingerprint: 3C8109B607AD3E119B7033D8948AD9EDA6BD626E
```

### Public Key
```
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=mNmv
-----END PGP PUBLIC KEY BLOCK-----
```

### Verifying Chart Signatures

To verify the signature of a chart, follow these steps:

1. Import the public key:
   ```bash
   curl -fsSL https://kubeadapt.github.io/kubeadapt-helm/pgp_keys.asc | gpg --import
   ```

2. Verify a chart:
   ```bash
   helm verify path/to/chart.tgz
   ```

We have enabled the ability to privately report security issues through the 
Security tab above.

[Here are the details](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability#privately-reporting-a-security-vulnerability) on how to report a security vulnerability.

### Chart Security

When using Kubeadapt Helm charts, we recommend following these security best practices:

1. Always verify chart signatures before installation
2. Use specific versions rather than floating tags
3. Review the values.yaml and understand the security implications of each setting
4. Follow the principle of least privilege when configuring RBAC
5. Keep your Helm and Kubernetes versions up to date

## Security Measures

Our security measures include:

1. Automated vulnerability scanning of dependencies
2. Regular security updates
3. Signed releases with GPG
4. Mandatory code review process
5. Automated testing and validation

## Contact

For security concerns that don't fit the vulnerability reporting process, you can contact us at authors@kubeadapt.io.