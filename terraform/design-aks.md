# AKS design

Code lives in the `aks` and `aks-bootstrap` layers and is off by default (`enabled = false`). It plan-tests
cleanly with `-var enabled=true`. It is not deployed: no reason to pay for an idle cluster in a lab.

| Concern | Lab code | Production design |
|---|---|---|
| API server | public, restricted by `authorized_ip_ranges` | private cluster, reached from a private runner / jump host |
| Identity | Entra ID + Azure RBAC for Kubernetes, local accounts disabled | same; admin groups from Entra, break-glass process |
| Node pools | `system` (critical addons only) + `user`, zones 1-3, autoscaling | system pool 3 nodes, user pools per workload class, spot only for tolerant jobs |
| Networking | Azure CNI, Calico NetworkPolicy, own `aks` subnet with NSG | default-deny per namespace, controlled egress via firewall/NAT, ingress via App Gateway or ingress-nginx |
| Workload identity | OIDC issuer + workload identity; `aks-bootstrap` creates federated identities with Key Vault Secrets User | same, one identity per service, least privilege |
| Secrets | Key Vault CSI driver with rotation | same; no secrets in manifests, state or CI |
| Upgrades | auto-upgrade channel `patch`, node OS channel `NodeImage`, surge 33% | maintenance windows, PodDisruptionBudgets on every service, dev first then prd |
| Scaling | cluster autoscaler (HPA per workload) | requests/limits enforced by quota and LimitRange |
| Policy | Azure Policy add-on, Pod Security `restricted` on the namespace | image allowlist (ACR only), signed images |
| Observability | Container Insights to Log Analytics | Managed Prometheus + Grafana, SLO burn-rate alerts (see `docs/SRE.md`) |
| Delivery | manifests in `/k8s` | GitOps (Flux) pulls from Git; CI has no cluster credentials |

Sample manifests: namespace and quota, default-deny NetworkPolicy, RBAC binding, workload identity
ServiceAccount, PDB and HPA are in `/k8s`.
