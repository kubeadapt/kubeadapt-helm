#!/usr/bin/env bash
# Validates every blocked-edge file. ingestion-api reads blocked-edges/ live
# from main, so a malformed edge takes effect as soon as it merges.
#
# Runs in CI (lint-and-test.yml) and locally: ./scripts/validate-blocked-edges.sh
# Needs git tags (an edge must target a released version) and mikefarah/yq v4.
set -euo pipefail

SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'
PLATFORMS_RE='^(eks|aks|gke|openshift|on-premise)$'

cd "$(cd "$(dirname "$0")/.." && pwd)"

errors=0
fail() {
  echo "  ERROR: $*"
  errors=$((errors + 1))
}
warn() { echo "  warning: $*"; }

redirects=$(mktemp)
trap 'rm -f "$redirects"' EXIT

for file in blocked-edges/*/*.yaml; do
  [ -f "$file" ] || continue
  chart=$(basename "$(dirname "$file")")
  echo "=== $file"

  if ! yq '.' "$file" >/dev/null 2>&1; then
    fail "invalid YAML"
    continue
  fi
  for field in to from name message; do
    yq -e ".$field" "$file" >/dev/null 2>&1 || fail "missing '$field'"
  done

  to=$(yq '.to' "$file")
  if ! echo "$to" | grep -Eq "$SEMVER_RE"; then
    fail "'to' must be an exact version, got '$to'"
  elif ! git rev-parse -q --verify "refs/tags/$chart-$to" >/dev/null; then
    fail "'to' $to was never released (no $chart-$to tag)"
  fi

  from=$(yq '.from' "$file")
  set +e
  echo "0.0.0" | grep -Eq "$from"
  [ $? -eq 2 ] && fail "'from' is not a valid regex: $from"
  set -e

  for rule_type in $(yq '.matchingRules[].type' "$file" 2>/dev/null || true); do
    case "$rule_type" in
      Always | Platform | PromQL) ;;
      *) warn "unknown matchingRules type '$rule_type' (Always, Platform, PromQL)" ;;
    esac
  done
  if yq -e '.matchingRules[] | select(.type == "Platform")' "$file" >/dev/null 2>&1; then
    platforms=$(yq '.matchingRules[] | select(.type == "Platform") | .platforms[]' "$file" 2>/dev/null || true)
    [ -n "$platforms" ] || fail "a Platform matchingRule needs a 'platforms' list"
    for p in $platforms; do
      echo "$p" | grep -Eq "$PLATFORMS_RE" || warn "unknown platform '$p'"
    done
  fi

  redirect=$(yq '.redirect_to // ""' "$file")
  if [ -n "$redirect" ]; then
    if ! echo "$redirect" | grep -Eq "$SEMVER_RE"; then
      fail "'redirect_to' must be an exact version, got '$redirect'"
    elif ! git rev-parse -q --verify "refs/tags/$chart-$redirect" >/dev/null; then
      fail "'redirect_to' $redirect was never released (no $chart-$redirect tag)"
    fi
    echo "$chart $to $redirect" >>"$redirects"
  fi

  yq -e '.url' "$file" >/dev/null 2>&1 || warn "no 'url' (recommended)"
  case "$(basename "$file" .yaml)" in
    "$to"-*) ;;
    *) warn "file name should start with '$to-'" ;;
  esac
done

# A redirect chain must terminate: follow every chain and fail on a revisit.
while read -r chart start _; do
  visited="|$start|"
  current=$start
  while next=$(awk -v c="$chart" -v t="$current" '$1 == c && $2 == t { print $3; exit }' "$redirects") && [ -n "$next" ]; do
    case "$visited" in
      *"|$next|"*)
        echo "=== redirect chains"
        fail "$chart redirect cycle: ${visited//|/ } -> $next"
        break
        ;;
    esac
    visited="$visited$next|"
    current=$next
  done
done <"$redirects"

if [ "$errors" -gt 0 ]; then
  echo
  echo "$errors blocked-edge error(s). See blocked-edges/README.md."
  exit 1
fi
echo
echo "Blocked edges OK."
