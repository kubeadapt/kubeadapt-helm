#!/bin/bash
while getopts c:d:v:t:a: opt; do
  case ${opt} in
    c) chart=${OPTARG} ;;
    d) dependency_name=${OPTARG} ;;
    v) new_version=${OPTARG} ;;
    t) type=${OPTARG} ;;
    a) all_dependencies=${OPTARG} ;;  # Optional: all deps in format "name:version\nname:version"
    *)
      echo 'Usage:' >&2
      echo '-c: chart       Related Helm chart name' >&2
      echo '-d: dependency  Name of the updated dependency (primary)' >&2
      echo '-v: version     New version of the updated dependency (primary)' >&2
      echo '-t: type        Type of version bump (major/minor/patch)' >&2
      echo '-a: all_deps    All updated dependencies (optional, format: name:version\\nname:version)' >&2
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

# For core components (agent), determine version bump type based on semver change
if [[ "${dependency_name}" =~ "agent" ]]; then
  # Get current version from values.yaml
  agent_version=$(grep "tag:" "charts/${chart}/values.yaml" | grep "agent" | awk '{print $2}')

  # Determine the version change type
  highest_type="patch"

  for current_version in "${agent_version}"; do
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

# Update chart version (compatible with both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version:.*/version: ${major}.${minor}.${patch}/g" "${chart_yaml_path}"
else
  sed -i "s/^version:.*/version: ${major}.${minor}.${patch}/g" "${chart_yaml_path}"
fi

# Update changelog entry (only the artifacthub.io/changes block)
# This uses awk to replace only the changes block while preserving other annotations
# If all_dependencies is provided, use that; otherwise use single dependency
if [ -n "${all_dependencies}" ]; then
  # Multiple dependencies - create changelog entries for all
  CHANGELOG_ENTRIES=$(echo "$all_dependencies" | while IFS=: read -r dep ver; do
    [ -n "$dep" ] && echo "    - kind: changed"
    [ -n "$dep" ] && echo "      description: Update $dep to $ver"
  done)

  awk -v entries="$CHANGELOG_ENTRIES" '
    BEGIN { in_changes=0; skip=0 }
    /^  artifacthub.io\/changes: \|/ {
      print
      print entries
      in_changes=1
      skip=1
      next
    }
    /^  artifacthub.io\// && in_changes {
      in_changes=0
      skip=0
    }
    !skip || /^  artifacthub.io\// {
      if (/^  artifacthub.io\//) in_changes=0
      if (!in_changes || /^  artifacthub.io\//) {
        print
        skip=0
      }
    }
  ' "${chart_yaml_path}" > "${chart_yaml_path}.tmp" && mv "${chart_yaml_path}.tmp" "${chart_yaml_path}"
else
  # Single dependency
  awk -v dep="${dependency_name}" -v ver="${new_version}" '
    BEGIN { in_changes=0; skip=0 }
    /^  artifacthub.io\/changes: \|/ {
      print
      print "    - kind: changed"
      print "      description: Update " dep " to " ver
      in_changes=1
      skip=1
      next
    }
    /^  artifacthub.io\// && in_changes {
      in_changes=0
      skip=0
    }
    !skip || /^  artifacthub.io\// {
      if (/^  artifacthub.io\//) in_changes=0
      if (!in_changes || /^  artifacthub.io\//) {
        print
        skip=0
      }
    }
  ' "${chart_yaml_path}" > "${chart_yaml_path}.tmp" && mv "${chart_yaml_path}.tmp" "${chart_yaml_path}"
fi

cat "${chart_yaml_path}"
