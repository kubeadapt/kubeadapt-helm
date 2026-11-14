#!/usr/bin/env bash
# Checks that a release of the kubeadapt chart would carry the network monitor
# chart that is in this repository.
#
# The kubeadapt chart is packaged with the kubeadapt-k8s-pulse chart inside it.
# Packaging does not take charts/kubeadapt-k8s-pulse from this tree: it
# downloads the version named under `dependencies` in charts/kubeadapt/Chart.yaml
# from the registry. A stale version there, or a kubeadapt-k8s-pulse chart that
# was changed without a new version, releases a kubeadapt chart whose network
# monitor is an older one than the templates beside it describe.
#
# The check applies when this tree would release the kubeadapt chart, that is
# when its version has no release tag yet. It then requires that
#   1. the dependency names the version of charts/kubeadapt-k8s-pulse,
#   2. that version is published, and
#   3. the published package has the same content as charts/kubeadapt-k8s-pulse.
#
# Needs helm and a clone with tags. Usage: check-subchart-pin.sh [repository root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PARENT="$ROOT/charts/kubeadapt"
SUB_NAME="kubeadapt-k8s-pulse"
SUB="$ROOT/charts/$SUB_NAME"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# field <chart dir> <name>: a top-level field of its Chart.yaml.
field() { helm show chart "$1" | awk -v k="$2:" '/^[a-zA-Z]/ && $1 == k { print $2; exit }' | tr -d "\"'"; }
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
fail() { echo "FAIL  $*" >&2; exit 1; }

parent_version="$(field "$PARENT" version)"
sub_version="$(field "$SUB" version)"
pin="$(dependency version)"
repository="$(dependency repository)"
[ -n "$parent_version" ] && [ -n "$sub_version" ] && [ -n "$pin" ] && [ -n "$repository" ] ||
  fail "could not read the versions from the two Chart.yaml files"

echo "kubeadapt $parent_version depends on $SUB_NAME $pin; this repository has $SUB_NAME $sub_version"

if git -C "$ROOT" rev-parse -q --verify "refs/tags/kubeadapt-$parent_version" >/dev/null; then
  echo "ok    kubeadapt $parent_version is already released, so this tree releases no kubeadapt chart."
  echo "      The check runs in full once the kubeadapt chart version is raised."
  exit 0
fi

[ "$pin" = "$sub_version" ] || fail "kubeadapt $parent_version would be packaged with $SUB_NAME $pin, but this repository has $SUB_NAME $sub_version.
      Set the dependency version in charts/kubeadapt/Chart.yaml to $sub_version."

mkdir "$WORK/published" "$WORK/local"
if ! helm pull "$repository/$SUB_NAME" --version "$pin" --untar --untardir "$WORK/published" >"$WORK/pull.log" 2>&1; then
  # Only the registry's own "no such version" answer counts as unpublished;
  # anything else (network, credentials) is an error of this check.
  if grep -Fq -e ":$pin: not found" -e "version \"$pin\" not found in" "$WORK/pull.log"; then
    fail "$SUB_NAME $pin is not published at $repository.
      Release it first: merge the $SUB_NAME change with its new version on its own, wait for the release,
      then raise the kubeadapt chart version. Both in one merge cannot be packaged."
  fi
  sed 's/^/      /' "$WORK/pull.log" >&2
  fail "could not download $SUB_NAME $pin from $repository"
fi

# Package the local chart the same way, so that both sides went through helm.
helm package "$SUB" --destination "$WORK" >/dev/null
tar -xzf "$WORK/$SUB_NAME-$sub_version.tgz" -C "$WORK/local"
if ! diff -r "$WORK/published/$SUB_NAME" "$WORK/local/$SUB_NAME" >"$WORK/diff.log"; then
  grep -E '^(diff|Only in)' "$WORK/diff.log" | sed "s#$WORK/##g; s/^/      /" >&2
  fail "the published $SUB_NAME $pin differs from charts/$SUB_NAME in this repository.
      A released version is never replaced: give charts/$SUB_NAME a new version, release it,
      then name that version in charts/kubeadapt/Chart.yaml."
fi
echo "ok    the published $SUB_NAME $pin is the chart in this repository."
