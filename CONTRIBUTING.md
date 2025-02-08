# Contributing to KubeAdapt Helm Chart

This repository contains the Helm chart for deploying KubeAdapt, a commercial Kubernetes resource optimization platform. The chart is maintained by the KubeAdapt team and this guide outlines how users can report issues, suggest improvements, and interact with the project.

## Issue Reporting

We encourage users to report:
* Chart deployment issues
* Configuration problems
* Documentation improvements
* Dependency version updates

For product-related features or bugs, please contact authors@kubeadapt.io.

## Pull Request Guidelines

While the chart is primarily maintained by the KubeAdapt team, we review pull requests for:
* Documentation improvements
* Dependency version updates
* Bug fixes in chart templates
* Value configurations

### Pull Request Title Format

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with these scopes:
- `chart`: Chart template changes
- `docs`: Documentation updates
- `deps`: Dependency updates
- `ci`: CI/CD changes

Examples:
- `fix(chart): Correct indentation in deployment template`
- `docs(chart): Update installation instructions`
- `chore(deps): Update Prometheus to 27.3.0`

## Documentation

The documentation for each chart is generated with [helm-docs](https://github.com/norwoodj/helm-docs). This way we can ensure that values are consistent with the chart documentation.


Documentation changes should be made directly to the relevant markdown files. Ensure all documentation is clear, concise, and accurately reflects the current chart functionality.

## Versioning

Charts follow [semver](https://semver.org/):
* Major (x.0.0): Breaking changes
* Minor (0.x.0): New features (backwards compatible)
* Patch (0.0.x): Bug fixes (backwards compatible)

### Component Versions

The chart includes:
- Kubeadapt Agent (closed-source)
- Kubeadapt Core API (closed-source)
- Prometheus (required/open-source)
- OpenCost (required/open-source)

Core component versions are managed exclusively by the Kubeadapt team. Only dependency version updates can be suggested through issues or pull requests.


### Artifact Hub Annotations

We use [Artifact Hub annotations](https://artifacthub.io/docs/topics/annotations/helm/) for enhanced metadata and changelogs.

#### Changelog Example

```yaml
name: kubeadapt
version: 0.1.0
annotations:
  artifacthub.io/changes: |
    - kind: added
      description: Initial release
    - kind: changed
      description: Updated Prometheus to 27.3.0
    - kind: fixed
      description: Fixed agent configuration
```

## Testing

Before reporting issues, please test with both minimal and full configurations:
```shell
# Test with default values
helm install kubeadapt ./charts/kubeadapt --dry-run

# Test with all components
helm install kubeadapt ./charts/kubeadapt \
  --set prometheus.enabled=true \
  --set opencost.enabled=true \
  --dry-run
```

### Chart Linting

We use Helm's [Chart Testing](https://github.com/helm/chart-testing) tool in CI. Configuration is in [ct-lint.yaml](./.github/configs/ct-lint.yaml).

Run linting locally:
```shell
./scripts/lint.sh
```

## Support Channels

* Chart Issues: GitHub Issues
* Product Support: authors@kubeadapt.io
* Security Issues: authors@kubeadapt.io

## Publishing

Chart releases are managed exclusively by the Kubeadapt team. All accepted changes will be included in future releases at the team's discretion. 