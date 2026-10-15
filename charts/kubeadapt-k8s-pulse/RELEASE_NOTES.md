## 1.1.0

Fast channel only. A patch release promotes it to stable.

- **Flow export to the Kubeadapt agent.** Installed by the `kubeadapt` chart, pulse sends its flows to that chart's agent Service and presents a bearer token read from a file mounted from the Secret the `kubeadapt` chart generates. Installed on its own, export stays off until `config.export.agentEndpoint` is set; `config.export.tokenSecret` names a Secret with the token under the key `token`.
- **The channel is plaintext gRPC.** The token authenticates pulse to the agent, but it travels unencrypted inside the cluster network, and so do the flow batches. Pulse reads the token only at startup: after you change it, restart the DaemonSet.
- **Image:** `kubeadapt-k8s-pulse:v3.2.0`. It is the first release that sends the token without TLS (v3.1.0 refuses to, v3.0.1 does not export), and it retries `RESOURCE_EXHAUSTED`, so `EBPF_RETRY_BUFFER_SIZE=120` from 1.0.2 now takes effect.
- **RBAC:** a read-only ClusterRole and ClusterRoleBinding (`rbac.create`): pods list/watch for the node-scoped pod identity informer, nodes get for the pod's own Node, and `cilium.io` `ciliumenvoyconfigs` list for the L7 detector. Before this the ServiceAccount had nothing bound, the pod informer never synced and flows carried no pod identity.
- `dnsPolicy` defaults to `ClusterFirstWithHostNet`. With `hostNetwork` and no `dnsPolicy`, the pod used the node's resolver and could not resolve cluster Service names, including the agent endpoint.
- `KUBEADAPT_MEMORY_LIMIT_BYTES` is set from the container's memory limit. It is pulse's primary memory-limit source: with the host cgroup filesystem mounted, pulse cannot find its own `memory.max`.
- The node's CNI configuration (`cniConfigDir`, default `/etc/cni/net.d`) is mounted read-only at `/host/etc/cni/net.d`. Without it pulse could not measure the overlay's encapsulation overhead, and `bytes_wire` understated overlay datapaths.
- Removed `EBPF_COLLECTION_INTERVAL`, `POD_NAME`, `POD_NAMESPACE` and the `config.collectionInterval` value. No pulse code reads them.

## 1.0.2

- Set `EBPF_RETRY_BUFFER_SIZE=120` in the default `env`, raising the export retry buffer to 120 sub-batches from pulse's built-in 60. The pinned image `v3.0.1` does not read this variable, so the setting is inert on this chart version. It takes effect once the chart pins a pulse release that reads the variable and retries `RESOURCE_EXHAUSTED`.
- Resource requests and limits are unchanged.

Image: `kubeadapt-k8s-pulse:v3.0.1`. Not bundled by any `kubeadapt` release up to 1.0.8, which bundle pulse chart 1.0.1.

## 1.0.1

- Raise the pulse DaemonSet memory request to 256Mi (from 128Mi). Pulse measured 129–155Mi across 3 pods, above the old request. Limits are unchanged at 500m / 384Mi.

Image: `kubeadapt-k8s-pulse:v3.0.1`. Bundled by the `kubeadapt` chart from 1.0.3.

## 1.0.0

**BREAKING CHANGES:** the chart is renamed from `ebpf-agent` to `kubeadapt-k8s-pulse`.

- Chart name `ebpf-agent` is now `kubeadapt-k8s-pulse`, at chart version 1.0.0 (was 0.2.1).
- Image `public.ecr.aws/w3l5x6r6/kubeadapt/app/kubeadapt-ebpf-agent:v0.2.0` is now `public.ecr.aws/k2x0t8t6/kubeadapt/app/kubeadapt-k8s-pulse:v3.0.1`, on a new registry alias.
- Template helpers, the container name and the component label change from `ebpf-agent` to `kubeadapt-k8s-pulse`.
- Source moves to https://github.com/kubeadapt/kubeadapt-k8s-pulse.
- Installed through the `kubeadapt` chart, values move from the `ebpf-agent:` key to `kubeadapt-k8s-pulse:` (kubeadapt 1.0.0).
