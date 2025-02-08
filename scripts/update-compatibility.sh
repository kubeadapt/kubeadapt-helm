#!/bin/bash
set -euo pipefail

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --chart-version)
      CHART_VERSION="$2"
      shift 2
      ;;
    --app-version)
      APP_VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "${CHART_VERSION:-}" ] || [ -z "${APP_VERSION:-}" ]; then
  echo "Usage: $0 --chart-version <version> --app-version <version>"
  exit 1
fi

# Check if Chart version has changed
LAST_CHART_VERSION=$(git show HEAD:charts/kubeadapt/Chart.yaml | grep '^version:' | head -n 1 | awk '{print $2}' || echo "")

if [ "${LAST_CHART_VERSION}" = "${CHART_VERSION}" ]; then
  echo "No version change detected (${CHART_VERSION}). Skipping compatibility matrix update."
  exit 0
fi

# Get component versions from Chart.yaml
PROMETHEUS_VERSION=$(grep -A2 'name: prometheus' charts/kubeadapt/Chart.yaml | grep 'version:' | awk '{print $2}' | tr -d '"')
OPENCOST_VERSION=$(grep -A2 'name: opencost' charts/kubeadapt/Chart.yaml | grep 'version:' | awk '{print $2}' | tr -d '"')

# Create temporary file
TMP_FILE=$(mktemp)
trap 'rm -f ${TMP_FILE}' EXIT

# Update COMPATIBILITY.md
{
  # Keep header and description
  sed -n '1,/### Version Compatibility Matrix/p' COMPATIBILITY.md

  # Update version matrix
  cat << EOF
| KubeAdapt Version | Agent Version | Core API Version | Prometheus Version | OpenCost Version |
|-------------------|---------------|------------------|-------------------|------------------|
| ${APP_VERSION}    | ${APP_VERSION} | ${APP_VERSION}  | ${PROMETHEUS_VERSION} | ${OPENCOST_VERSION} |
EOF

  # Add historical entry if this is not the first release
  if ! grep -q "No releases yet" COMPATIBILITY.md; then
    echo -e "\n## Historical Compatibility"
    grep -A 100 "^## Historical Compatibility" COMPATIBILITY.md | tail -n +2
  else
    echo -e "\n## Historical Compatibility"
    echo "| Date | KubeAdapt | Agent | Core API | Prometheus | OpenCost |"
    echo "|------|-----------|--------|-----------|------------|-----------|"
    echo "| $(date +%Y-%m-%d) | ${APP_VERSION} | ${APP_VERSION} | ${APP_VERSION} | ${PROMETHEUS_VERSION} | ${OPENCOST_VERSION} |"
  fi
} > "${TMP_FILE}"

# Replace COMPATIBILITY.md with updated content
mv "${TMP_FILE}" COMPATIBILITY.md 