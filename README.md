# azure-simple-lab

A small, cheap Azure lab that demonstrates the pattern I use in production:
**Terraform code → GitHub Actions (OIDC, plan, approval, apply) → real Azure resources.**

```
GitHub PR ─► fmt / validate / checkov ─► plan (dev, prd) ─► merge to main
                                                              │
                              apply dev ──► [approval] ──► apply prd
                                   │ OIDC federated credential, no stored secrets
                                   ▼
                               Azure subscription
```

## Layers

Each layer is its own Terraform stack with its own state file per environment, and layers
find each other by name through data sources (no cross-state coupling). Apply order top to bottom.

| # | Layer | What it owns | Deployed in lab |
|---|---|---|---|
| 1 | `bootstrap` | resource group, Log Analytics, storage, Key Vault, action group + alert | yes |
| 2 | `network` | VNet, NSGs, route table, subnets (runner / pep / aks), private DNS zones | yes |
| 3 | `runner` | private self-hosted CI runner VM | code only (`enabled = false`) |
| 4 | `aks` | private, Entra-integrated AKS (system + user pools, zones, autoscaling) | code only (`enabled = false`) |
| 5 | `aks-bootstrap` | federated workload identities + Key Vault RBAC for pods; GitOps handles `/k8s` | code only (`enabled = false`) |

```
terraform/<layer>/common/   the layer's code (variables, local.*.tf config, main.tf, outputs)
terraform/<layer>/dev|prd/  thin roots: env inputs, provider pin, backend (key = <layer>-<env>.tfstate)
.github/workflows/          terraform.yml (orchestration), layer.yml (reusable: one layer, one env)
scripts/bootstrap.sh        one-time: state storage, Entra app + federated creds, GitHub environments
k8s/  terraform/design-aks.md   in-cluster manifests and AKS design notes
docs/                       SRE, review findings, interview script
```

Reusable modules live in a separate repo (`anasmohana/terraform-modules`) and are
**pinned to a commit SHA**; bumping a module is a reviewed PR.

Pipeline: PR runs fmt/validate/checkov, then a plan for every layer x env. Merge to main applies
dev layer by layer, then waits for one approval (`prd-approval`), then applies prd layer by layer.
To turn on a code-only layer, flip `enabled = true` in its env root and merge.

## Cost

Deployed layers are a few cents/day per environment (Log Analytics capped at 0.5 GB/day,
LRS storage, no VMs, no cluster).

## Run it

```bash
az login
GITHUB_REPO=<owner>/azure-simple-lab ALERT_EMAIL=you@example.com ./scripts/bootstrap.sh
# then add MODULES_READ_TOKEN secret and required reviewers on the `prd` environment
```

Tear down: run `terraform destroy` per env (dev has purge protection off for this reason).
