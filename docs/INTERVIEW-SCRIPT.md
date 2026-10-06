# 30-minute walkthrough

Opening line: "This is a lab I implemented myself to show the same patterns I use in production."

| Time | Topic | Show | Say |
|---|---|---|---|
| 0-5 | Architecture | README diagram + status table | five layers, state per layer per env, only dev deployed to keep cost low, prd is code with its own approval gate |
| 5-15 | GitHub Actions + Terraform | `azure-network` run: plan, approval, apply; `terraform-workflow-template.yml`; `terraform/network/common` | OIDC vs stored secrets, federated subject pinned to repo + environment, separate plan/apply identities, remote state with locking, settings-object modules pinned to a SHA, apply uses the reviewed plan after an explicit approval (issue comment; environment reviewers are the production answer but need a paid plan on private repos), concurrency per state, drift |
| 15-20 | Real Azure | portal: `lab-dev-rg` (AKS, Key Vault, storage, Log Analytics), `lab-dev-net-rg` | Terraform to Actions to real resources; cost control (log cap, one small node, destroyed after) |
| 20-25 | Kubernetes / GitOps / security / monitoring | the website URL, `terraform/aks/common/local.aks.tf`, the gitops repo, `docs/SRE.md` | small real cluster (1 node, Free tier) created by the pipeline; Flux installed by Terraform as an AKS extension so CI holds no cluster credentials; ingress-nginx + site delivered by Git; Entra RBAC, workload identity, default-deny NetworkPolicy, restricted pod security, PDB; production differences in `terraform/design-aks.md` |
| 25-30 | Consultant close | `docs/REVIEW-FINDINGS.md` | the three findings with severity, quick win and long-term fix; how I audit an environment; questions |

## Least-privilege demo (RBAC + workload identity)
1. Pipeline identity: Contributor cannot write role assignments; show the 403 from the first `aks-bootstrap` run (in the Actions history).
2. Fix: RBAC Administrator with a condition that allows assigning only Key Vault Secrets User (`scripts/bootstrap.sh`).
3. `aks-bootstrap` then creates a federated user-assigned identity for the `website` service account and grants it that
   one role on the Key Vault (verify in the portal: identity `lab-dev-website-wi`, role Key Vault Secrets User on the vault only).
   A pod using that service account can read secrets with no stored credential, and CI can never grant broader rights.
4. Proof it works end to end: the website pod (label `azure.workload.identity/use`, service account `website`) has an init
   container that swaps its projected token for an Entra token and reads the secret `website-banner`. The page shows the
   result (`/kv/status.json`). Secret value is a deliberately harmless demo string; the pod egress policy allows only DNS and HTTPS.
5. Vault stays deny-by-default: bootstrap adds only the AKS subnet (service endpoint) to the firewall (`allow_aks_subnet`).
   Be precise: the secret was seeded by hand (firewall blocks hosted runners; a self-hosted runner would let Terraform own it),
   and it is read at pod start, so rotation needs a restart (the CSI driver with rotation is the production answer).

## GitOps demo
Open a PR in the gitops repo, merge it, and watch the page change within about 3 minutes with no kubectl (tested: PR #1, "v2" banner).

## Be ready for
- **"Why not private endpoints / private AKS?"** Cost and demo risk (they need a private runner); the network layer already has the
  private DNS zones and the `runner` layer is the design. The cluster API is public but restricted to my IP.
- **"Why a public AKS API?"** Lab only, restricted by `authorized_ip_ranges`; production is private with a private runner.
- **"Where do secrets live?"** No Azure secrets in GitHub (OIDC); Key Vault with RBAC; pods use workload identity.
  The only secret is a read-only token for the private modules repo.
- **"What went wrong while building it?"** OIDC subject format (immutable IDs), a closed region, D-series VM quota of 0 (switched to B-series),
  module settings that `validate` cannot check, Contributor unable to assign roles, no approval environments on a free private repo,
  and Flux's Helm controller lacking permissions on an Azure-RBAC cluster. All fixed and listed in `docs/RUNBOOK.md`.
- **"Who wrote the modules?"** My own reusable Terraform modules, versioned in a separate repo.

## Backup material
Screenshots of one full plan, approval and apply run and of the portal, in case the live demo fails.
