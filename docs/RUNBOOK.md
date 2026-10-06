# Runbook

## One-time setup
1. `az login` with the account that owns the target subscription (Owner or equivalent). If you work with
   several tenants, use a separate profile: `AZURE_CONFIG_DIR=~/.azure-personal az login`.
2. `GITHUB_REPO=<owner>/azure-simple-lab ALERT_EMAIL=<email> ./scripts/bootstrap.sh`
   Creates: state resource group + storage account + `tfstate` container; Entra app `lab-github-terraform`
   with one federated credential per GitHub environment; Contributor on the subscription; GitHub
   environments (`dev`, `dev-plan`, `prd`, `prd-plan`) and variables.
   The federated subject uses GitHub's immutable IDs (`repo:<owner>@<id>/<repo>@<id>:environment:<env>`).
3. `gh secret set MODULES_READ_TOKEN` (fine-grained PAT, Contents: read-only, on the modules repo only).
4. Protect `main`. Approval needs no setup: each apply opens an issue and waits for the repo owner to comment `approve`.

## Deploy a layer
Actions > `azure-<layer>` > Run workflow > environment. The run shows the plan in the job summary,
waits for you to comment `approve` on the approval issue it opens (both dev and prd), then applies that exact plan. Run layers in order.
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
| Environment reviewers cannot be set (422 "billing plan") | required reviewers need a paid plan on private repos | issue-based approval action in the template |
| Run ends in `startup_failure` | caller workflow lacked `permissions: id-token: write` | declare permissions in each `azure-*.yml` |
| `AADSTS700213 no matching federated identity` | token subject uses immutable IDs, credential used names | use the ID-based subject (bootstrap.sh does) |
| `403 Write access to repository not granted` on module download | `MODULES_READ_TOKEN` scoped to wrong repo / missing Contents read | regenerate the PAT for the modules repo |
| `Unsupported attribute enable_monitor_diagnostic_setting` | module requires keys that `validate` cannot see | add the key; plan locally first |
| `RequestDisallowedByAzure ... location not accepting new customers` | region closed for the subscription | use another region (norwayeast) |
| AKS `dns_prefix` / `dns_prefix_private_cluster` conflict | module sets `dns_prefix` by default | use `dns_prefix` only |
| `AuthorizationFailed ... roleAssignments/write` in aks-bootstrap | Contributor cannot create role assignments | conditional RBAC Administrator (Key Vault Secrets User only), see bootstrap.sh |
| Website init container stuck / `/kv/status.json` is 404 | secret `website-banner` missing, or vault firewall lacks the AKS subnet | apply bootstrap with `allow_aks_subnet = true` (after network), then seed the secret: temporary IP rule + `Key Vault Secrets Officer` for yourself, `az keyvault secret set`, remove the IP rule |
| Flux HelmRelease: `secrets is forbidden ... Azure does not have opinion` | on Azure-RBAC clusters the Helm controller identity `<ns>:flux-applier` has no Kubernetes permissions | RoleBinding to `admin` in the chart namespace (gitops repo `rbac.yaml`) |
| Flux HelmRelease: `attempting to grant RBAC permissions not currently held` | a chart creates Roles/ClusterRoles with rights the applier lacks | `escalate`+`bind` limited by `resourceNames` to the chart's own roles; rendered with `helm template` to find them |
| Flux stuck, release `Stalled` / health check runs 10 min | failed release has nothing to roll back to; retry waits for the interval | shorter `interval`, `upgrade.remediation.strategy: uninstall`; a spec change in Git triggers a retry |
| Ingress IP gives HTTP 000 / timeout | AKS subnet NSG denied internet 80/443 | allow rule for 80/443 in the network layer |
| VM size has quota 0 (`Standard_D*`) | new subscription only has B-series quota | `Standard_B2ms` for the lab cluster (`az vm list-usage -l <region>`) |
| `-var enabled=true` rejected | root did not declare the variable | roots now declare `enabled` |

## Demo cluster lifecycle
The AKS cluster costs about $2-3/day. Create it with the `azure-aks` then `azure-aks-bootstrap` workflows (the aks root
defaults to `enabled = true` in dev; set the `AKS_AUTHORIZED_IPS` environment variable to your public IP as a JSON list,
for example `["203.0.113.7/32"]`). Destroy it after the demo (`terraform destroy` in `aks-bootstrap/dev`, then `aks/dev`).
The public IP of the site is the `kubernetes-*` public IP in the `MC_lab-dev-rg_lab-dev-aks_*` resource group.

## Teardown
Reverse order: aks-bootstrap, aks, runner, network, bootstrap (`terraform destroy` in each `dev` root),
then the state group `lab-tfstate-rg` and the Entra app `lab-github-terraform` if you are done with the lab.
Key Vault in dev has purge protection off so it can be recreated; prd has it on.
