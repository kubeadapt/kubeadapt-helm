# KubeAdapt Versioning Strategy

## Overview

KubeAdapt follows semantic versioning for both its system components and Helm chart. This document outlines how versions are managed across different parts of the system.

## Version Components

### 1. System Version (appVersion)
- Represented by `appVersion` in Chart.yaml
- Reflects the version of the KubeAdapt system itself
- Manually managed to ensure controlled system version updates
- Independent from component versions to allow flexibility
- Format: MAJOR.MINOR.PATCH (e.g., 1.2.3)

### 2. Chart Version
- Represented by `version` in Chart.yaml
- Reflects changes to the Helm chart structure and dependencies
- Format: MAJOR.MINOR.PATCH (e.g., 1.2.3)

### Chart Version
Increments follow these rules:

1. MAJOR Version (X.y.z)
   - Breaking changes in chart structure
   - Incompatible API changes
   - Major version upgrades of critical dependencies

2. MINOR Version (x.Y.z)
   - Core component updates (agent/coreapi)
   - New features in chart (non-breaking)
   - Substantial dependency updates

3. PATCH Version (x.y.Z)
   - Bug fixes in chart
   - Documentation updates
   - Non-core dependency updates (Prometheus/OpenCost)

## Automated Version Management

### Renovate Bot Configuration

1. Core Components (agent/coreapi):
   ```json
   {
     "groupName": "kubeadapt-components",
     "matchPackagePatterns": [
       "ghcr.io/kubeadapt/agent",
       "ghcr.io/kubeadapt/coreapi"
     ],
     "postUpgradeTasks": {
       "commands": [
         "./scripts/renovate-bump-version.sh -c kubeadapt -d {{depName}} -v {{newVersion}}"
       ]
     }
   }
   ```
   - Groups agent and coreapi updates together
   - Automatically determines version bump type based on semver changes
   - Updates chart version only

2. Dependencies (Prometheus/OpenCost):
   ```json
   {
     "matchPackagePatterns": [
       "prometheus-community/prometheus",
       "opencost/opencost"
     ],
     "postUpgradeTasks": {
       "commands": [
         "./scripts/renovate-bump-version.sh -c kubeadapt -d {{depName}} -v {{newVersion}} -t patch"
       ]
     }
   }
   ```
   - Always bumps chart patch version
   - Doesn't affect appVersion

## Version Bump Logic

The `renovate-bump-version.sh` script implements smart version bumping:

1. For Core Components:
   - Checks both agent and coreapi current versions
   - Compares with new version using semver rules
   - Determines highest version change type (major > minor > patch)
   - Updates chart version accordingly

2. For Dependencies:
   - Always performs patch version bump
   - Updates changelog with dependency update

## Example Scenarios

1. Single Component Update:
   ```yaml
   # Initial state
   version: 1.0.0
   appVersion: "1.0.0"  # Manually managed

   # After agent update to 1.1.0
   version: 1.1.0      # Minor bump
   appVersion: "1.0.0" # Unchanged (manual update required)
   ```

2. Multiple Component Updates (Grouped):
   ```yaml
   # Initial state
   version: 1.0.0
   appVersion: "1.0.0"  # Manually managed

   # After grouped update:
   # - agent: 1.1.0 (minor)
   # - coreapi: 1.0.1 (patch)
   version: 1.1.0      # Minor bump (highest change type)
   appVersion: "1.0.0" # Unchanged (manual update required)
   ```

3. Dependency Update:
   ```yaml
   # Initial state
   version: 1.0.0
   appVersion: "1.0.0"  # Manually managed

   # After Prometheus update
   version: 1.0.1      # Patch bump
   appVersion: "1.0.0" # Unchanged
   ```

4. System Version Update:
   ```yaml
   # Initial state
   version: 1.0.0
   appVersion: "1.0.0"

   # After manual system version update
   version: 1.0.0      # Unchanged
   appVersion: "1.1.0" # Manually updated for system changes
   ```