# AKS design

Code lives in the `aks` and `aks-bootstrap` layers. In `dev` it is deployed in a deliberately small form
(one `Standard_B2ms` node, Free tier, ~$2-3/day, destroyed after the demo). `prd` is code only.

| Concern | Lab code | Production design |
|---|---|---|
| API server | public, restricted by `authorized_ip_ranges` | private cluster, reached from a private runner / jump host |
| Identity | Entra ID + Azure RBAC for Kubernetes, local accounts disabled | same; admin groups from Entra, break-glass process |
| Node pools | one default pool (workloads share it), autoscaling 1-2, no zones | system pool 3 nodes, user pools per workload class, spot only for tolerant jobs |
| Networking | Azure CNI, Calico NetworkPolicy, own `aks` subnet with NSG | default-deny per namespace, controlled egress via firewall/NAT, ingress via App Gateway or ingress-nginx |
| Workload identity | OIDC issuer + workload identity; `aks-bootstrap` creates federated identities with Key Vault Secrets User; the website pod uses it to read a Key Vault secret (vault firewall allows only the AKS subnet) | same, one identity per service, least privilege |
| Secrets | Key Vault CSI driver with rotation | same; no secrets in manifests, state or CI |
| Upgrades | auto-upgrade channel `patch`, node OS channel `NodeImage`, surge 33% | maintenance windows, PodDisruptionBudgets on every service, dev first then prd |
| Scaling | cluster autoscaler (HPA per workload) | requests/limits enforced by quota and LimitRange |
| Policy | Pod Security `restricted` on the website namespace; Azure Policy add-on off (memory) | image allowlist (ACR only), signed images |
| Observability | Container Insights to Log Analytics | Managed Prometheus + Grafana, SLO burn-rate alerts (see `docs/SRE.md`) |
| Delivery | Flux (AKS extension, installed by Terraform) syncs the public `azure-simple-lab-gitops` repo | GitOps (Flux) pulls from Git; CI has no cluster credentials |

Deployed from the gitops repo: ingress-nginx (Helm, public load balancer) and a small static website with a
default-deny NetworkPolicy, restricted pod security, resource limits and a PodDisruptionBudget. The production
column is what I would add on top: private API, zones, a user pool, quotas/LimitRange, HPA, image policy.
