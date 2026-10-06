# azure-simple-lab

A small, low-cost Azure lab that demonstrates the delivery pattern I use in production:

**Terraform in layers → GitHub Actions (OIDC, plan, approval, apply) → real Azure resources.**

```
PR ──► fmt / validate / checkov
manual dispatch per layer ──► plan ──► approval (issue comment) ──► apply that exact plan
                                  │ GitHub OIDC federated credential, no stored Azure secrets
                                  ▼
                            Azure subscription
```

## Status

| Layer | What it owns | `dev` | `prd` |
|---|---|---|---|
| 1 `bootstrap` | resource group, Log Analytics, storage, Key Vault, action group + availability alert | **deployed** | code only |
| 2 `network` | VNet, 2 NSGs, route table, 3 subnets (runner / pep / aks), private DNS zones | **deployed** | code only |
| 3 `runner` | private self-hosted CI runner VM | code only (`enabled=false`) | code only |
| 4 `aks` | Entra-integrated AKS, system + user pools, 3 zones, autoscaling | code only (`enabled=false`) | code only |
| 5 `aks-bootstrap` | federated workload identities + Key Vault RBAC for pods | code only (`enabled=false`) | code only |

Only `dev` is deployed, to keep the lab cheap. `prd` has the same code with different inputs
(address space, GRS storage, purge protection, larger AKS minimums) and goes through the same approval gate.
Code-only layers still plan cleanly (`No changes`), and `aks` / `runner` were plan-tested with
`enabled=true` (3 resources each) without applying.

Region: `norwayeast` (westeurope was not accepting new customers on the subscription).

## Repository layout

```
terraform/<layer>/common/    the layer's code: variables, local.*.tf config, main.tf, outputs
terraform/<layer>/dev|prd/   thin roots: env inputs, provider pin, backend (state key <layer>-<env>.tfstate)
.github/workflows/
  azure-<layer>.yml          manual dispatch per layer (choose dev | prd)
  terraform-workflow-template.yml   reusable: plan -> approval -> apply
  terraform-checks.yml       PR gate: fmt, validate every root, checkov (report-only)
scripts/bootstrap.sh         one-time: state storage, Entra app + federated credentials, GitHub environments
k8s/                         in-cluster manifests (namespace, NetworkPolicy, RBAC, workload identity, PDB/HPA)
docs/                        runbook, SRE, review findings, interview script
terraform/design-aks.md      AKS design decisions
```

## How it fits together

- **Layers, not one big stack.** Each layer has its own state file per environment. Layers find each
  other by resource name through data sources, not by reading each other's state, so each can be
  planned and applied independently. Apply order: bootstrap, network, runner, aks, aks-bootstrap.
- **Modules** come from a separate, private repo (`anasmohana/terraform-modules`) and are pinned to a
  commit SHA. Bumping a module is a reviewed change. Resources are described with settings objects
  (`local.*.tf`), so adding a subnet or storage account is a data change, not new code.
- **Authentication:** GitHub issues a short-lived OIDC token per job. Azure trusts only the exact
  repo + environment subject (`<env>-plan` for plans, `<env>` for applies), so a plan token cannot be
  replayed as an apply. No client secrets exist. The only secret is a read-only token for the module repo.
- **Approval:** after the plan, the pipeline opens a GitHub issue linking the run (the plan is in the job summary) and waits for the repo owner to comment `approve` or `deny`. Nothing is applied until then. GitHub's built-in environment reviewers need a paid plan on private repos, so the lab uses a SHA-pinned approval action; with a paid plan you would use environment reviewers instead.
  Apply uses the saved plan file and the plan job's provider lock file, so it applies exactly what was reviewed.
- **State:** Azure Storage, versioned with soft delete, Entra auth only (no keys), blob-lease locking,
  one state file per layer per environment. Concurrency groups prevent two applies on one state.

## Security posture in the lab (and what I would change for production)

In the lab: default-deny NSGs, storage with no shared keys / no public blobs / TLS 1.2 / versioning,
Key Vault with RBAC and diagnostics to Log Analytics, deny-by-default firewalls, OIDC, pinned
provider and module versions, Log Analytics daily cap.

Deliberately not done: private endpoints, Azure Firewall, private AKS API. They would need a private
runner and extra cost. See `docs/REVIEW-FINDINGS.md` for what I would do in production.

## Run it

Prerequisites: an Azure subscription you own, `az`, `gh`, Terraform. Full steps in `docs/RUNBOOK.md`.

```bash
az login
GITHUB_REPO=<owner>/azure-simple-lab ALERT_EMAIL=you@example.com ./scripts/bootstrap.sh
gh secret set MODULES_READ_TOKEN --repo <owner>/azure-simple-lab   # read-only token for the modules repo
# protect main; each apply waits for you to comment "approve" on the approval issue
# then: Actions -> azure-bootstrap -> Run workflow -> dev, then azure-network, ...
```

To turn on a code-only layer, run its workflow with `plan_vars` (for example `-var enabled=true`;
AKS also takes `-var 'authorized_ip_ranges=["<your-ip>/32"]'`, the runner `-var admin_ssh_public_key=...`).

## Cost

Deployed layers cost cents per day: Log Analytics is capped at 0.5 GB/day, storage is LRS in dev,
and there are no VMs or clusters running. Tear down with `terraform destroy` per layer in reverse order
(or delete `lab-dev-net-rg` and `lab-dev-rg`).
