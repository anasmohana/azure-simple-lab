# Runbook

## One-time setup
1. `az login` with the account that owns the target subscription (Owner or equivalent). If you work with
   several tenants, use a separate profile: `AZURE_CONFIG_DIR=~/.azure-personal az login`.
2. `GITHUB_REPO=<owner>/azure-simple-lab ALERT_EMAIL=<email> ./scripts/bootstrap.sh`
   Creates: state resource group + storage account + `tfstate` container; Entra app `lab-github-terraform`
   with one federated credential per GitHub environment; Contributor on the subscription; GitHub
   environments (`dev`, `dev-plan`, `prd`, `prd-plan`, `dev-approval`, `prd-approval`) and variables.
   The federated subject uses GitHub's immutable IDs (`repo:<owner>@<id>/<repo>@<id>:environment:<env>`).
3. `gh secret set MODULES_READ_TOKEN` (fine-grained PAT, Contents: read-only, on the modules repo only).
4. Settings > Environments > `prd-approval`: add required reviewers. Protect `main`.

## Deploy a layer
Actions > `azure-<layer>` > Run workflow > environment. The run shows the plan in the job summary,
waits for approval (auto for dev), then applies that exact plan. Run layers in order.
If the plan has no changes the approval and apply jobs are skipped.

## Plan locally (read-only)
```bash
export AZURE_CONFIG_DIR=~/.azure-personal ARM_SUBSCRIPTION_ID=<id> ARM_TENANT_ID=<id> TF_VAR_alert_email=<email>
cd terraform/<layer>/dev
terraform init -reconfigure -backend-config="resource_group_name=lab-tfstate-rg" \
  -backend-config="storage_account_name=<state-sa>" -backend-config="use_oidc=false"
terraform plan -lock=false
```
Module `settings` objects are untyped: `terraform validate` passes even when a required key is missing,
so always run a real plan before pushing.

## Troubleshooting seen while building this
| Symptom | Cause | Fix |
|---|---|---|
| Run ends in `startup_failure` | caller workflow lacked `permissions: id-token: write` | declare permissions in each `azure-*.yml` |
| `AADSTS700213 no matching federated identity` | token subject uses immutable IDs, credential used names | use the ID-based subject (bootstrap.sh does) |
| `403 Write access to repository not granted` on module download | `MODULES_READ_TOKEN` scoped to wrong repo / missing Contents read | regenerate the PAT for the modules repo |
| `Unsupported attribute enable_monitor_diagnostic_setting` | module requires keys that `validate` cannot see | add the key; plan locally first |
| `RequestDisallowedByAzure ... location not accepting new customers` | region closed for the subscription | use another region (norwayeast) |
| AKS `dns_prefix` / `dns_prefix_private_cluster` conflict | module sets `dns_prefix` by default | use `dns_prefix` only |
| `-var enabled=true` rejected | root did not declare the variable | roots now declare `enabled` |

## Teardown
Reverse order: aks-bootstrap, aks, runner, network, bootstrap (`terraform destroy` in each `dev` root),
then the state group `lab-tfstate-rg` and the Entra app `lab-github-terraform` if you are done with the lab.
Key Vault in dev has purge protection off so it can be recreated; prd has it on.
