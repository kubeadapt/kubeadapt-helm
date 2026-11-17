#!/usr/bin/env bash
# Checks, before a chart is released, the two things a release can get wrong
# without any test noticing. Each check applies when this tree would release
# the chart in question, that is when its version has no release tag yet;
# until then it passes with a note.
#
# 1. The network monitor image (kubeadapt-k8s-pulse chart).
#    The default image.tag must be a release at or above the chart's
#    kubeadapt.io/minimum-image-version annotation. Older images replace the
#    tc filter of the node's CNI or network policy agent. The templates refuse
#    such a tag at install time; this keeps a chart whose own default they
#    refuse from being released.
#
# 2. The network monitor chart inside the kubeadapt chart.
#    The kubeadapt chart is packaged with the kubeadapt-k8s-pulse chart
#    downloaded from the registry at the version under `dependencies`, not
#    with the one in this tree. So the dependency must name the version of
#    charts/kubeadapt-k8s-pulse, that version must be published, and the
#    published package must have the same content. Otherwise the release
#    carries an older network monitor chart than the templates beside it.
#
# Needs helm and a clone with tags. Usage: check-release.sh [repository root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PARENT="$ROOT/charts/kubeadapt"
SUB_NAME="kubeadapt-k8s-pulse"
SUB="$ROOT/charts/$SUB_NAME"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILED=0

# field <chart dir> <name>: a top-level field of its Chart.yaml.
field() { helm show chart "$1" | awk -v k="$2:" '/^[a-zA-Z]/ && $1 == k { print $2; exit }' | tr -d "\"'"; }
# annotation <chart dir> <name>
annotation() { helm show chart "$1" | awk -v k="$2:" '/^annotations:/ { a = 1; next } a && /^[^ ]/ { a = 0 } a && $1 == k { print $2; exit }' | tr -d "\"'"; }
# dependency <field>: a field of the kubeadapt-k8s-pulse entry under dependencies.
dependency() {
  helm show chart "$PARENT" | awk -v name="$SUB_NAME" -v k="$1:" '
    /^dependencies:/ { deps = 1; next }
    deps && /^[^ -]/ { deps = 0 }
    !deps { next }
    /^- / { if (found) exit; delete entry; found = 0 }
    { line = $0; sub(/^[- ] /, "", line); split(line, kv, ": "); entry[kv[1] ":"] = kv[2]
      if (kv[1] == "name" && kv[2] == name) found = 1 }
    END { if (found) print entry[k] }' | tr -d "\"'"
}
released() { git -C "$ROOT" rev-parse -q --verify "refs/tags/$1" >/dev/null; }
fail() { echo "FAIL  $*" >&2; FAILED=1; }

parent_version="$(field "$PARENT" version)"
sub_version="$(field "$SUB" version)"
pin="$(dependency version)"
repository="$(dependency repository)"
minimum="$(annotation "$SUB" kubeadapt.io/minimum-image-version)"
default_tag="$(helm show values "$SUB" | awk '/^image:/ { i = 1; next } i && /^[^ #]/ { i = 0 } i && $1 == "tag:" { print $2; exit }' | tr -d "\"'")"
if [ -z "$parent_version" ] || [ -z "$sub_version" ] || [ -z "$pin" ] || [ -z "$repository" ] || [ -z "$minimum" ] || [ -z "$default_tag" ]; then
  echo "FAIL  could not read the versions, the minimum image version or the default image tag from the charts" >&2
  exit 1
fi

check_image() {
  echo "$SUB_NAME $sub_version: default image tag $default_tag, minimum image version $minimum"
  if released "$SUB_NAME-$sub_version"; then
    echo "ok    $SUB_NAME $sub_version is already released, so this tree releases no $SUB_NAME chart."
    echo "      The image check applies once its version is raised."
    return
  fi
  if ! echo "$default_tag" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+$'; then
    fail "the default image.tag of $SUB_NAME is \"$default_tag\". A released chart must default to a release tag."
    return
  fi
  # The chart's own templates do the comparison: it must render with its defaults.
  if ! helm template check "$SUB" >/dev/null 2>"$WORK/image.log"; then
    sed 's/^/      /' "$WORK/image.log" | cut -c1-400 >&2
    fail "$SUB_NAME $sub_version does not render with its own defaults.
      Its default image.tag is $default_tag and the minimum image version is $minimum:
      set image.tag in charts/$SUB_NAME/values.yaml (and in ci/default-values.yaml) to the release this chart is for."
    return
  fi
  echo "ok    the default image of $SUB_NAME $sub_version passes the chart's own check."
}

check_dependency() {
  echo "kubeadapt $parent_version depends on $SUB_NAME $pin; this repository has $SUB_NAME $sub_version"
  if released "kubeadapt-$parent_version"; then
    echo "ok    kubeadapt $parent_version is already released, so this tree releases no kubeadapt chart."
    echo "      The dependency check applies once its version is raised."
    return
  fi
  if [ "$pin" != "$sub_version" ]; then
    fail "kubeadapt $parent_version would be packaged with $SUB_NAME $pin, but this repository has $SUB_NAME $sub_version.
      Set the dependency version in charts/kubeadapt/Chart.yaml to $sub_version."
    return
  fi
  mkdir "$WORK/published" "$WORK/local"
  if ! helm pull "$repository/$SUB_NAME" --version "$pin" --untar --untardir "$WORK/published" >"$WORK/pull.log" 2>&1; then
    # Only the registry's own "no such version" answer counts as unpublished;
    # anything else (network, credentials) is an error of this check.
    if grep -Fq -e ":$pin: not found" -e "version \"$pin\" not found in" "$WORK/pull.log"; then
      fail "$SUB_NAME $pin is not published at $repository.
      Release it first: merge the $SUB_NAME change with its new version on its own, wait for the release,
      then raise the kubeadapt chart version. Both in one merge cannot be packaged."
    else
      sed 's/^/      /' "$WORK/pull.log" >&2
      fail "could not download $SUB_NAME $pin from $repository"
    fi
    return
  fi
  # Package the local chart the same way, so that both sides went through helm.
  helm package "$SUB" --destination "$WORK" >/dev/null
  tar -xzf "$WORK/$SUB_NAME-$sub_version.tgz" -C "$WORK/local"
  if ! diff -r "$WORK/published/$SUB_NAME" "$WORK/local/$SUB_NAME" >"$WORK/diff.log"; then
    grep -E '^(diff|Only in)' "$WORK/diff.log" | sed "s#$WORK/##g; s/^/      /" >&2
    fail "the published $SUB_NAME $pin differs from charts/$SUB_NAME in this repository.
      A released version is never replaced: give charts/$SUB_NAME a new version, release it,
      then name that version in charts/kubeadapt/Chart.yaml."
    return
  fi
  echo "ok    the published $SUB_NAME $pin is the chart in this repository."
}

check_image
check_dependency
exit "$FAILED"
