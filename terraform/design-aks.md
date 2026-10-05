# AKS design (not deployed)

Code lives in the `aks` and `aks-bootstrap` layers (`enabled = false`). Not provisioned: no reason to pay for a running cluster in a lab. This is the shape I'd deploy
via the shared `aks` module, in the `aks` subnet of the platform VNet.

| Concern | Decision |
|---|---|
| Cluster | Private API server, Azure CNI Overlay, Entra ID auth + Azure RBAC for Kubernetes, local accounts disabled |
| Node pools | `system` (3 nodes, zones 1-3, tainted CriticalAddonsOnly) + `user` pool autoscaled 3-12, zones 1-3 |
| Identity | OIDC issuer + Workload Identity; pods use federated user-assigned managed identities, never secrets |
| Secrets | Key Vault via CSI driver (RBAC auth), secrets never in manifests/state |
| Network | NetworkPolicy default-deny per namespace, egress via firewall/NAT, ingress via App Gateway for Containers or ingress-nginx |
| Upgrades | Auto-upgrade channel `patch`, node image `NodeImage`, maintenance window, PDBs on every service; dev first, then prd |
| Scaling | HPA on pods, cluster autoscaler on nodes, resource requests mandatory (ResourceQuota/LimitRange) |
| Policy | Azure Policy add-on / Pod Security `restricted`, image allowlist (ACR only) |
| Observability | Managed Prometheus + Managed Grafana, Container Insights logs to Log Analytics (see docs/SRE.md) |
| Delivery | GitOps (Flux) pulling `k8s/`; CI never has kubectl credentials |

Sample manifests for namespaces, NetworkPolicy, workload identity, PDB/HPA and RBAC are in `/k8s`.
