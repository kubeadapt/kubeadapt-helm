#!/bin/bash
while getopts c:d:v:t: opt; do
  case ${opt} in
    c) chart=${OPTARG} ;;
    d) dependency_name=${OPTARG} ;;
    v) new_version=${OPTARG} ;;
    t) type=${OPTARG} ;;
    *)
      echo 'Usage:' >&2
      echo '-c: chart       Related Helm chart name' >&2
      echo '-d: dependency  Name of the updated dependency' >&2
      echo '-v: version     New version of the updated dependency' >&2
      echo '-t: type        Type of version bump (major/minor/patch)' >&2
      exit 1
  esac
done

if [ -z "${dependency_name}" ] || [ -z "${new_version}" ] || [ -z "${chart}" ] ; then
  echo 'Missing relevant CLI flag(s).' >&2
  exit 1
fi

chart_yaml_path="charts/${chart}/Chart.yaml"
# Split dependency by '/' and only use last element
# This way we can drop prefixes like "kubeadapt/..." , "prometheus-community/..." , "opencost/..."
dependency_name="${dependency_name##*/}"

# For core components (agent/coreapi), determine version bump type based on semver change
if [[ "${dependency_name}" =~ "agent" ]] || [[ "${dependency_name}" =~ "coreapi" ]]; then
  # Get current versions from values.yaml
  agent_version=$(grep "tag:" "charts/${chart}/values.yaml" | grep "agent" | awk '{print $2}')
  coreapi_version=$(grep "tag:" "charts/${chart}/values.yaml" | grep "coreapi" | awk '{print $2}')
  
  # Determine the highest version change type among components
  highest_type="patch"
  
  for current_version in "${agent_version}" "${coreapi_version}"; do
    # Extract major.minor.patch
    current_major=$(echo "${current_version}" | cut -d. -f1)
    current_minor=$(echo "${current_version}" | cut -d. -f2)
    current_patch=$(echo "${current_version}" | cut -d. -f3)
    
    new_major=$(echo "${new_version}" | cut -d. -f1)
    new_minor=$(echo "${new_version}" | cut -d. -f2)
    new_patch=$(echo "${new_version}" | cut -d. -f3)
    
    # Determine bump type based on version change
    if [ "${new_major}" -gt "${current_major}" ]; then
      highest_type="major"
      break
    elif [ "${new_minor}" -gt "${current_minor}" ] && [ "${highest_type}" != "major" ]; then
      highest_type="minor"
    elif [ "${new_patch}" -gt "${current_patch}" ] && [ "${highest_type}" == "patch" ]; then
      highest_type="patch"
    fi
  done
  
  type="${highest_type}"
fi

# Get current chart version
version=$(grep '^version:' "${chart_yaml_path}" | awk '{print $2}')
major=$(echo "${version}" | cut -d. -f1)
minor=$(echo "${version}" | cut -d. -f2)
patch=$(echo "${version}" | cut -d. -f3)

# Bump version according to type
case ${type} in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

# Update chart version
sed -i "s/^version:.*/version: ${major}.${minor}.${patch}/g" "${chart_yaml_path}"

# Add a changelog entry
sed -i -e '/^  artifacthub.io\/changes: |/,$ d' "${chart_yaml_path}"
{
  echo "  artifacthub.io/changes: |"
  echo "    - kind: changed"
  echo "      description: Update ${dependency_name} to ${new_version}"
} >> "${chart_yaml_path}"
cat "${chart_yaml_path}"
