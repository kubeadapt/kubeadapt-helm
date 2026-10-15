#!/usr/bin/env bash
# Validates the release metadata of every chart changed against a base ref:
# upgrade-metadata.yaml, RELEASE_NOTES.md, Chart.yaml annotations and the
# subchart pins of charts that depend on a chart in this repository.
#
# Runs in CI (lint-and-test.yml) and locally:
#
#   ./scripts/validate-release-metadata.sh
#   BASE_REF=origin/my-base ./scripts/validate-release-metadata.sh
#
# Needs full git history with tags, and mikefarah/yq v4.
set -euo pipefail

REPO_URL="https://github.com/kubeadapt/kubeadapt-helm"
BASE_REF="${BASE_REF:-origin/main}"
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

cd "$(cd "$(dirname "$0")/.." && pwd)"

errors=0
chart=""
fail() {
  echo "  ERROR: $*"
  errors=$((errors + 1))
}

# released_versions prints every released version of a chart, ascending.
released_versions() {
  git tag -l "$1-[0-9]*" | sed "s/^$1-//" | grep -E "$SEMVER_RE" | sort -t. -k1,1n -k2,2n -k3,3n || true
}

# image_tag prints the image tag a chart deploys by default.
image_tag() {
  case "$1" in
    kubeadapt) yq '.agent.image.tag' "charts/$1/values.yaml" ;;
    *) yq '.image.tag' "charts/$1/values.yaml" ;;
  esac
}

# edge_blocks succeeds when a blocked edge stops auto-upgrades from $3 to $2.
edge_blocks() {
  local f
  for f in blocked-edges/"$1"/*.yaml; do
    [ -f "$f" ] || continue
    [ "$(yq '.to' "$f")" = "$2" ] || continue
    if echo "$3" | grep -Eq "$(yq '.from' "$f")"; then
      return 0
    fi
  done
  return 1
}

check_upgrade_metadata() {
  local dir="charts/$chart" version meta channels prerelease
  meta="$dir/upgrade-metadata.yaml"
  version=$(yq '.version' "$dir/Chart.yaml")

  if [ ! -f "$meta" ]; then
    fail "missing $meta"
    return
  fi
  [ "$(yq '.chartVersion' "$meta")" = "$version" ] ||
    fail "upgrade-metadata chartVersion $(yq '.chartVersion' "$meta") does not match Chart.yaml version $version"

  if git rev-parse -q --verify "refs/tags/$chart-$version" >/dev/null; then
    fail "$chart-$version is already released; bump the chart version"
  fi

  channels=$(yq '.channels[]' "$meta" 2>/dev/null || true)
  [ -n "$channels" ] || fail "channels is empty"
  for c in $channels; do
    case "$c" in
      stable | fast) ;;
      *) fail "invalid channel '$c' (stable or fast)" ;;
    esac
  done
  prerelease=$(yq '.annotations."artifacthub.io/prerelease"' "$dir/Chart.yaml")
  # RELEASE-POLICY.md: a new minor or major lands on fast first; a later
  # patch promotes it to stable.
  if [ "${version##*.}" = "0" ] && echo "$channels" | grep -qx stable; then
    fail "$version is a new minor or major; release it fast-only and promote it with a patch release"
  fi
  if echo "$channels" | grep -qx stable; then
    [ "$prerelease" = "false" ] || fail "channels include stable, so artifacthub.io/prerelease must be \"false\" (is $prerelease)"
  else
    [ "$prerelease" = "true" ] || fail "a fast-only release must set artifacthub.io/prerelease: \"true\" (is $prerelease)"
  fi

  local expected_url="$REPO_URL/releases/tag/$chart-$version"
  [ "$(yq '.metadata.releaseNotes' "$meta")" = "$expected_url" ] ||
    fail "metadata.releaseNotes is $(yq '.metadata.releaseNotes' "$meta"); expected $expected_url"
}

check_release_notes() {
  local dir="charts/$chart" version notes
  version=$(yq '.version' "$dir/Chart.yaml")
  notes="$dir/RELEASE_NOTES.md"
  # chart-releaser publishes this file from the package as the GitHub
  # release body (.github/configs/cr.yaml), and ingestion-api serves that body.
  if [ ! -f "$notes" ]; then
    fail "missing $notes"
  elif ! grep -qx "## $version" "$notes"; then
    fail "$notes has no '## $version' section"
  fi
}

check_upgrade_from() {
  local dir="charts/$chart" version meta released latest first major from
  meta="$dir/upgrade-metadata.yaml"
  [ -f "$meta" ] || return 0
  version=$(yq '.version' "$dir/Chart.yaml")
  released=$(released_versions "$chart")
  latest=$(echo "$released" | tail -1)
  first=$(yq '.upgradeFrom[0]' "$meta")
  if [ -n "$latest" ] && [ "$first" != "$latest" ]; then
    fail "upgradeFrom[0] is '$first'; it must be the latest release, $latest"
  fi

  major=${version%%.*}
  for from in $(yq '.upgradeFrom[]' "$meta"); do
    if ! echo "$from" | grep -Eq "$SEMVER_RE"; then
      echo "  note: upgradeFrom '$from' is a pattern and is not checked"
      continue
    fi
    echo "$released" | grep -qx "$from" ||
      fail "upgradeFrom '$from' was never released (no $chart-$from tag)"
    if [ "${from%%.*}" != "$major" ] && ! edge_blocks "$chart" "$version" "$from"; then
      fail "upgradeFrom '$from' lets auto-upgrade cross a major version; drop it or add blocked-edges/$chart/$version-<name>.yaml"
    fi
  done
}

check_versions_and_images() {
  local dir="charts/$chart" app tag img
  app=$(yq '.appVersion' "$dir/Chart.yaml")
  tag=$(image_tag "$chart")
  [ "${app#v}" = "${tag#v}" ] || fail "appVersion '$app' does not match the default image tag '$tag'"
  for img in $(yq '.annotations."artifacthub.io/images" // ""' "$dir/Chart.yaml" | yq '.[].image' 2>/dev/null || true); do
    [ "${img##*:}" = "$tag" ] || fail "artifacthub.io/images lists $img, but the chart deploys tag $tag"
  done
}

check_changes_annotation() {
  local dir="charts/$chart" base="$1" old new carried
  git cat-file -e "$base:$dir/Chart.yaml" 2>/dev/null || return 0
  old=$(git show "$base:$dir/Chart.yaml" | yq '.annotations."artifacthub.io/changes" // ""' | yq '.[].description' 2>/dev/null | sort -u || true)
  new=$(yq '.annotations."artifacthub.io/changes" // ""' "$dir/Chart.yaml" | yq '.[].description' 2>/dev/null | sort -u || true)
  [ -n "$new" ] || {
    fail "artifacthub.io/changes is empty"
    return
  }
  carried=$(comm -12 <(echo "$old") <(echo "$new") | grep -c . || true)
  [ "$carried" -eq 0 ] ||
    fail "artifacthub.io/changes repeats $carried entry(ies) from the previous release; list only this release's changes"
}

# check_subchart_pins fails when a chart pins a local subchart at a version
# other than the one in this repository, which ships a stale subchart.
check_subchart_pins() {
  local parent="$1" dep pin repo local_version
  for dep in $(yq '.dependencies[].name' "charts/$parent/Chart.yaml" 2>/dev/null || true); do
    [ -f "charts/$dep/Chart.yaml" ] || continue
    pin=$(yq ".dependencies[] | select(.name == \"$dep\") | .version" "charts/$parent/Chart.yaml")
    repo=$(yq ".dependencies[] | select(.name == \"$dep\") | .repository" "charts/$parent/Chart.yaml")
    local_version=$(yq '.version' "charts/$dep/Chart.yaml")
    if [ "$pin" != "$local_version" ]; then
      fail "dependency $dep is pinned at $pin ($repo) but charts/$dep is $local_version"
    fi
  done
}

base=$(git merge-base "$BASE_REF" HEAD)
changed=$(git diff --name-only "$base" HEAD -- charts/ | cut -d/ -f2 | sort -u)
if [ -z "$changed" ]; then
  echo "No chart changed against $BASE_REF; nothing to validate."
  exit 0
fi

for chart in $changed; do
  [ -f "charts/$chart/Chart.yaml" ] || continue
  echo "=== $chart $(yq '.version' "charts/$chart/Chart.yaml")"
  check_upgrade_metadata
  check_release_notes
  check_upgrade_from
  check_versions_and_images
  check_changes_annotation "$base"
done

# A parent is checked when it, or any subchart it pins, changed.
for parent_dir in charts/*/; do
  parent=$(basename "$parent_dir")
  for dep in $(yq '.dependencies[].name' "charts/$parent/Chart.yaml" 2>/dev/null || true); do
    if echo "$changed" | grep -qx -e "$parent" -e "$dep"; then
      echo "=== $parent subchart pins"
      check_subchart_pins "$parent"
      break
    fi
  done
done

if [ "$errors" -gt 0 ]; then
  echo
  echo "$errors release metadata error(s). See docs/RELEASE-POLICY.md."
  exit 1
fi
echo
echo "Release metadata OK."
