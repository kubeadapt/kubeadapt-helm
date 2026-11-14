# Kubeadapt Helm Charts

This repository contains the Helm charts for deploying Kubeadapt into Kubernetes clusters:

- **kubeadapt** - Main chart. Deploys the Kubeadapt agent (cluster metrics collection), with an optional auto-upgrade sidecar and the optional network monitor subchart.
- **kubeadapt-k8s-pulse** - The network monitor: an eBPF DaemonSet that measures each pod's network traffic and sends it to the agent. Usually installed through the main chart, but can be deployed on its own.

## Platform Support

The agent is a single Deployment that reads the Kubernetes API and the metrics API. It runs anywhere a normal pod runs, and by default it meets the Kubernetes **restricted** Pod Security Standard.

| Platform | Agent (`kubeadapt`) | Network monitor (`kubeadapt-k8s-pulse`) |
|----------|---------------------|----------------------------------------|
| Amazon EKS (EC2 nodes) | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Amazon EKS on Fargate | Supported | Not supported (Fargate runs no DaemonSets) |
| Azure AKS | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Standard | Supported, Kubernetes 1.24 - 1.35 | Supported |
| Google GKE Autopilot | Supported | Not supported (no host network or added capabilities) |
| Red Hat OpenShift / ROSA | Supported (see below) | Requires the `privileged` SCC |
| Self-managed (kubeadm, kops, Rancher, k3s, RKE2) | Supported, Kubernetes 1.24 - 1.35 | Supported |

The network monitor needs Linux kernel 5.10 or newer on every node it runs on, the node's network namespace and a small set of Linux capabilities. It is disabled by default. See [Network monitoring](#network-monitoring).

**Requirements:**
- Kubernetes 1.24+
- Helm 3.0+
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) installed in the cluster. Without it, cost appears but CPU and memory usage, efficiency and rightsizing stay empty. EKS and kind/k3d do not install it by default.

See [COMPATIBILITY.md](COMPATIBILITY.md) for pricing support per cloud and the feature matrix.

## Installation

Get a token from [app.kubeadapt.io](https://app.kubeadapt.io) under **Clusters > Add cluster**.

**Recommended: keep the token in a Secret.** The token then never appears on a command line, in shell history or in `helm get values`.

```bash
kubectl create namespace kubeadapt
kubectl create secret generic kubeadapt-agent-token \
  --namespace kubeadapt \
  --from-literal=token='<your-token>'

helm repo add kubeadapt https://kubeadapt.github.io/kubeadapt-helm
helm repo update

helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token
```

**Quick try:**

```bash
helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --create-namespace \
  --set agent.config.token='<your-token>'
```

### OpenShift

The restricted-v2 SCC assigns the user and group from the namespace's range, so drop the chart's fixed IDs:

```bash
helm install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token \
  --set agent.podSecurityContext.runAsUser=null \
  --set agent.podSecurityContext.runAsGroup=null \
  --set agent.podSecurityContext.fsGroup=null
```

### Network monitoring

The network monitor (`kubeadapt-k8s-pulse`) is off by default. To turn it on:

```bash
helm upgrade --install kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --set agent.config.existingSecret=kubeadapt-agent-token \
  --set kubeadapt-k8s-pulse.enabled=true
```

The agent then listens for the DaemonSet on port 9091 behind the `kubeadapt-agent-pulse` ClusterIP Service, and accepts traffic records only from a sender that presents a shared token. The chart creates that token in the `kubeadapt-pulse-token` Secret on first install and keeps it on every upgrade. To use your own, create a Secret with the token under the key `token` and set `global.pulse.existingSecret` to its name. Do this as well when you deploy with a tool that renders the chart without cluster access, such as Argo CD; otherwise each render creates a new token. To rotate the token, change the Secret: both pods read it again while running.

What the DaemonSet needs on each node:

- Linux kernel 5.10 or newer
- the node's network namespace (`hostNetwork`)
- the Linux capabilities `BPF`, `PERFMON` and `NET_ADMIN`, plus `SYS_RESOURCE` on kernels older than 5.11 and `SYS_PTRACE` for the container runtime inventory; every other capability is dropped, privilege escalation is off and the root filesystem is read-only
- read-only access to the node's `/proc`, cgroup tree, CNI configuration (`/etc/cni/net.d`) and Istio ztunnel directory (`/var/run/ztunnel`), and write access to the BPF filesystem (`/sys/fs/bpf`)
- read-only Kubernetes API access: list and watch pods, get nodes, list CiliumEnvoyConfigs

The [kubeadapt-k8s-pulse chart README](charts/kubeadapt-k8s-pulse/README.md#what-the-pod-asks-of-the-node) lists each of these with the pod field and the reason. The host network, host paths and added capabilities place the pod outside the baseline Pod Security Standard, so its namespace must allow the privileged level, and a policy engine needs an exception for it: [examples/network-monitor](examples/network-monitor) has the namespace label, a Kyverno PolicyException and Gatekeeper constraints, each limited to what the pod uses. Where a node's security policy blocks the reduced capability set, set `kubeadapt-k8s-pulse.seLinuxOptions`, or run it privileged with `kubeadapt-k8s-pulse.privileged=true`.

Where it runs and how it rolls out:

- One pod on every Linux node, tainted pools included. Nodes that cannot run a DaemonSet pod (AWS Fargate, virtual-kubelet) get none. Narrow it with `kubeadapt-k8s-pulse.tolerations` and `kubeadapt-k8s-pulse.nodeRequirements`.
- It has no priority class by default and never evicts a workload to get onto a node. On a node with no room for its requests (100m CPU, 256Mi) the pod waits, and that node is not measured until it starts. `kubeadapt-k8s-pulse.priorityClass.create=true` keeps ordinary workloads from pushing it out, still without evicting anything; `kubeadapt-k8s-pulse.priorityClassName=system-node-critical` guarantees a place on every node at the price of evicting lower-priority pods on full ones.
- A later change reaches 25% of the nodes at a time (`kubeadapt-k8s-pulse.updateStrategy`), so a rollout takes minutes on any cluster size.
- Images can come from your own registry: `agent.image.repository`, `agent.autoUpgrade.image.repository`, `agent.autoUpgrade.jobImage`, `kubeadapt-k8s-pulse.image.repository`, with `global.imagePullSecrets` for credentials.
- In a namespace that denies ingress by default, `agent.networkPolicy.enabled=true` with `agent.networkPolicy.nodeCIDRs` admits the DaemonSet to the agent's listener. Its connections come from node addresses, so a pod selector cannot match them. On Cilium, node addresses are not matched by an `ipBlock`; allow the `host` and `remote-node` entities to port 9091 of the agent with a CiliumNetworkPolicy instead.

After the install, Helm prints the commands that show whether every node has a ready pod and, when one has not, where the reason is: admission denials in the DaemonSet's events, scheduling and image pulls in the pod's events, node security policy in the pod's log. A policy engine that checks workload objects, as Kyverno does by default, rejects the DaemonSet itself: the install then fails with the engine's message, which lists the rules to except. The chart README's [Troubleshooting](charts/kubeadapt-k8s-pulse/README.md#troubleshooting) section has the full table.

## Upgrading

```bash
helm repo update
helm upgrade kubeadapt kubeadapt/kubeadapt \
  --namespace kubeadapt \
  --reset-then-reuse-values
```

`--reset-then-reuse-values` (Helm 3.14 or newer) keeps the settings you made and takes everything else from the new chart. With an older Helm, pass your settings again with `-f` or `--set`.

Do not use `--reuse-values` to move to a new chart version. It also keeps the previous version's defaults, image tags included, so the release would keep running the old images under new templates. With the network monitor off the chart still renders that way and says so in its notes; with `kubeadapt-k8s-pulse.enabled=true` it stops and asks for `--reset-then-reuse-values`, because the network monitor only works with the images and settings of the same release.

With the network monitor on, give `--wait` a timeout that covers the DaemonSet's rollout (`--timeout 15m`), and on Helm 4 use `--wait=legacy`: the default there waits for a ready pod on every node, which one full node can hold up.

### Upgrade Jobs left by releases before 1.0.8

The auto-upgrade sidecar of chart releases before 1.0.8 created `kubeadapt-upgrade-*` Jobs under a service account that does not exist, so they never started and are still in the namespace. They do not affect the upgrade, and this chart creates no account of that name. Remove them:

```bash
kubectl -n kubeadapt get jobs \
  -o jsonpath='{range .items[?(@.spec.template.spec.serviceAccountName=="kubeadapt-k8s-upgrader")]}{.metadata.name}{"\n"}{end}' \
  | xargs -r kubectl -n kubeadapt delete job
```

## Uninstalling

```bash
helm uninstall kubeadapt --namespace kubeadapt
```

This removes the agent Deployment, its Services, ServiceAccounts, the chart-created token Secrets, Roles, ClusterRoles and their bindings, and the network monitor DaemonSet with its NetworkPolicy, PriorityClass and ResourceQuota where those were enabled. It leaves behind:

- the `kubeadapt` namespace (Helm does not delete namespaces): `kubectl delete namespace kubeadapt`
- a token Secret you created yourself for `existingSecret`
- auto-upgrade Jobs that are still running; finished Jobs delete themselves after their TTL
- on nodes that did not have them, the empty directories `/etc/cni/net.d` and `/var/run/ztunnel`, which the network monitor creates to mount

Nothing is installed outside the release namespace except the cluster-scoped RBAC objects listed above.

Then delete the cluster on the **Clusters** page in Kubeadapt, so its token stops working and it no longer shows as disconnected.

## Configuration

See [charts/kubeadapt/values.yaml](./charts/kubeadapt/values.yaml) for all configuration options.

Full documentation: [kubeadapt.io/docs/v1/configuration/overview](https://kubeadapt.io/docs/v1/configuration/overview/)

## Chart Signing & Verification

All Helm charts are GPG-signed. Signing key details:

- **Key ID:** 948AD9EDA6BD626E
- **Fingerprint:** 3C8109B607AD3E119B7033D8948AD9EDA6BD626E

See [SECURITY.md](SECURITY.md) for verification instructions and how to report vulnerabilities.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

Apache License 2.0. See [LICENSE](LICENSE).
