#!/usr/bin/env bash
# Renders the charts the way an upgrade does and checks the output. Needs helm
# and a clone with tags. Run it before pushing a template or values change.
#
# `helm upgrade --reuse-values` gives the new templates the values of the
# release being upgraded: the old chart's defaults plus the user's overrides,
# with nothing from the new values.yaml. The "old values" cases reproduce that
# by rendering each chart with its values.yaml replaced by the one of every
# 1.x release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/out.yaml"
FAILED=0

# stage <dir>: a copy of both charts, the network monitor vendored into the
# kubeadapt chart so that the local templates are rendered, not a published one.
stage() {
  mkdir -p "$1"
  cp -R "$ROOT/charts/kubeadapt" "$1/kubeadapt"
  cp -R "$ROOT/charts/kubeadapt-k8s-pulse" "$1/kubeadapt-k8s-pulse"
  rm -rf "$1/kubeadapt/charts"
  mkdir -p "$1/kubeadapt/charts"
  cp -R "$ROOT/charts/kubeadapt-k8s-pulse" "$1/kubeadapt/charts/kubeadapt-k8s-pulse"
}

# render <name> <chart dir> [helm args]: must render; output goes to $OUT.
render() {
  local name="$1" chart="$2"
  shift 2
  if helm template kubeadapt "$chart" --namespace kubeadapt-system "$@" >"$OUT" 2>"$WORK/err"; then
    echo "ok    $name"
  else
    echo "FAIL  $name"
    sed 's/^/        /' "$WORK/err"
    FAILED=1
    : >"$OUT"
  fi
}

# refused <name> <chart dir> [helm args]: must stop with the message that
# names the way out, never with a template error.
refused() {
  local name="$1" chart="$2"
  shift 2
  if helm template kubeadapt "$chart" --namespace kubeadapt-system "$@" >/dev/null 2>"$WORK/err"; then
    echo "FAIL  $name: rendered"
    FAILED=1
  elif grep -q -- '--reset-then-reuse-values' "$WORK/err"; then
    echo "ok    $name: refused, points to --reset-then-reuse-values"
  else
    echo "FAIL  $name"
    sed 's/^/        /' "$WORK/err"
    FAILED=1
  fi
}

# has / hasnt <what> <pattern>: check the last rendered output.
has() { grep -Eq -- "$2" "$OUT" || { echo "FAIL    expected: $1"; FAILED=1; }; }
hasnt() { ! grep -Eq -- "$2" "$OUT" || { echo "FAIL    not expected: $1"; FAILED=1; }; }

stage "$WORK/new"
NEW="$WORK/new/kubeadapt"
ON=(--set kubeadapt-k8s-pulse.enabled=true)

echo "== this chart's own values"
render "defaults" "$NEW"
hasnt "a DaemonSet while the network monitor is off" '^kind: DaemonSet'
hasnt "a NetworkPolicy by default" '^kind: NetworkPolicy'

render "network monitor on" "$NEW" "${ON[@]}"
has "AWS Fargate nodes excluded" 'key: eks.amazonaws.com/compute-type'
has "virtual-kubelet nodes excluded" 'virtual-kubelet'
has "Linux nodes only" 'key: kubernetes.io/os'
has "every taint tolerated" 'operator: Exists'
hasnt "a priority class by default" 'priorityClassName|^kind: (PriorityClass|ResourceQuota)'
has "maxUnavailable as a percentage" 'maxUnavailable: 25%'
hasnt "maxUnavailable: 1" 'maxUnavailable: 1$'
has "IfNotPresent for the network monitor" 'imagePullPolicy: IfNotPresent'
hasnt "an Always pull policy" 'imagePullPolicy: Always'
hasnt "a NetworkPolicy by default" '^kind: NetworkPolicy'

render "own affinity keeps the node requirements" "$NEW" "${ON[@]}" \
  --set 'kubeadapt-k8s-pulse.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=pool' \
  --set 'kubeadapt-k8s-pulse.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=Exists'
has "the user's expression" 'key: pool'
has "AWS Fargate nodes still excluded" 'key: eks.amazonaws.com/compute-type'

render "chart-owned priority class" "$NEW" "${ON[@]}" \
  --set kubeadapt-k8s-pulse.priorityClass.create=true --set agent.autoUpgrade.enabled=true
has "a PriorityClass" '^kind: PriorityClass'
has "that never preempts" '^preemptionPolicy: Never'
has "used by the pods" 'priorityClassName: kubeadapt-kubeadapt-k8s-pulse-kubeadapt-system'
has "manageable by the upgrader" 'priorityclasses'

render "system priority class keeps its quota" "$NEW" "${ON[@]}" \
  --set kubeadapt-k8s-pulse.priorityClassName=system-node-critical
has "a ResourceQuota" '^kind: ResourceQuota'

render "private registry and SELinux" "$NEW" "${ON[@]}" --set agent.autoUpgrade.enabled=true \
  --set 'global.imagePullSecrets[0].name=regcred' \
  --set kubeadapt-k8s-pulse.seLinuxOptions.type=spc_t \
  --set kubeadapt-k8s-pulse.config.metricsPort=19090
[ "$(grep -c -- '- name: regcred' "$OUT")" = 3 ] || { echo "FAIL    expected: the pull secret on the agent, the network monitor and the upgrader account"; FAILED=1; }
has "the SELinux type" 'type: spc_t'
has "the moved node port" 'containerPort: 19090'
hasnt "the default node port" '[: "]9090"?$'

render "network policy" "$NEW" "${ON[@]}" --set agent.networkPolicy.enabled=true \
  --set 'agent.networkPolicy.nodeCIDRs[0]=10.0.0.0/16'
has "a NetworkPolicy" '^kind: NetworkPolicy'
has "the node range" 'cidr: "10.0.0.0/16"'
if helm template kubeadapt "$NEW" "${ON[@]}" --set agent.networkPolicy.enabled=true >/dev/null 2>"$WORK/err"; then
  echo "FAIL  network policy without node ranges must not render"
  FAILED=1
elif grep -q 'nodeCIDRs' "$WORK/err"; then
  echo "ok    network policy without node ranges is refused"
else
  echo "FAIL  network policy without node ranges"
  sed 's/^/        /' "$WORK/err"
  FAILED=1
fi

# Upgrade Jobs of upgrader v3.0.1 wait for a service account of this name. A
# chart that created it would start every one of them.
render "auto-upgrade" "$NEW" "${ON[@]}" --set agent.autoUpgrade.enabled=true
hasnt "an object named kubeadapt-k8s-upgrader" 'name: kubeadapt-k8s-upgrader$'

echo "== values of earlier releases (helm upgrade --reuse-values)"
tags="$(git -C "$ROOT" tag -l 'kubeadapt-1.*' | sort -V)"
[ -n "$tags" ] || { echo "FAIL  no kubeadapt-1.* tags found: fetch tags first"; exit 1; }
for tag in $tags; do
  old="$WORK/$tag"
  stage "$old"
  git -C "$ROOT" show "$tag:charts/kubeadapt/values.yaml" >"$old/kubeadapt/values.yaml"
  render "$tag" "$old/kubeadapt"
  render "$tag, auto-upgrade on" "$old/kubeadapt" --set agent.autoUpgrade.enabled=true
  # The old defaults (image tags, tolerations, no connection to the agent)
  # cannot run the network monitor.
  refused "$tag, network monitor turned on" "$old/kubeadapt" "${ON[@]}"
  git -C "$ROOT" show "$tag:charts/kubeadapt-k8s-pulse/values.yaml" \
    >"$old/kubeadapt/charts/kubeadapt-k8s-pulse/values.yaml"
  refused "$tag, network monitor was already on" "$old/kubeadapt" "${ON[@]}"
done

for tag in $(git -C "$ROOT" tag -l 'kubeadapt-k8s-pulse-1.*' | sort -V); do
  old="$WORK/$tag"
  stage "$old"
  git -C "$ROOT" show "$tag:charts/kubeadapt-k8s-pulse/values.yaml" >"$old/kubeadapt-k8s-pulse/values.yaml"
  refused "$tag on its own" "$old/kubeadapt-k8s-pulse"
done

if [ "$FAILED" -ne 0 ]; then
  echo "render tests failed"
  exit 1
fi
echo "render tests passed"
