# 30-minute walkthrough

Opening line: "This is a lab I implemented myself to show the same patterns I use in production."

| Time | Topic | Show | Say |
|---|---|---|---|
| 0-5 | Architecture | README diagram + status table | five layers, state per layer per env, only dev deployed to keep cost low, prd is code with its own approval gate |
| 5-15 | GitHub Actions + Terraform | `azure-network` run: plan, approval, apply; `terraform-workflow-template.yml`; `terraform/network/common` | OIDC vs stored secrets, federated subject pinned to repo + environment, separate plan/apply identities, remote state with locking, settings-object modules pinned to a SHA, apply uses the reviewed plan, concurrency per state, drift |
| 15-20 | Real Azure | portal: `lab-dev-rg`, `lab-dev-net-rg` | Terraform to Actions to real resources; cost control (log cap, no VMs) |
| 20-25 | Kubernetes / security / monitoring | `terraform/aks/common/local.aks.tf`, `k8s/`, `docs/SRE.md` | "Not running: no reason to pay for an idle cluster. This is the design I would deploy." Entra RBAC, workload identity, NetworkPolicy, PDB/HPA, upgrades, SLO burn-rate alerts, backup/DR |
| 25-30 | Consultant close | `docs/REVIEW-FINDINGS.md` | the three findings with severity, quick win and long-term fix; how I audit an environment; questions |

## Be ready for
- **"Why not private endpoints / a running AKS in the lab?"** Cost and demo risk; the network layer, private DNS
  and the aks/runner layers show the design and I plan-tested them (`enabled=true` gives 3 resources each).
- **"Why a public AKS API?"** Lab only, restricted by `authorized_ip_ranges`; production is private with a private runner.
- **"Where do secrets live?"** No Azure secrets in GitHub (OIDC); Key Vault with RBAC; pods use workload identity.
  The only secret is a read-only token for the private modules repo.
- **"What went wrong while building it?"** Subject format for OIDC (immutable IDs), a closed region, module
  settings missing keys that validate cannot see, and the `dns_prefix` conflict. All fixed and listed in `docs/RUNBOOK.md`.
- **"Who wrote the modules?"** My own reusable Terraform modules, versioned in a separate repo.

## Backup material
Screenshots of one full plan, approval and apply run and of the portal, in case the live demo fails.
