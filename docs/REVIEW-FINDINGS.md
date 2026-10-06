# If I were reviewing this as a production environment

Three findings in the format I use for client reports: severity, risk, remediation, quick win, longer-term fix.

## 1. Data services still reachable over public endpoints: **High**
- **What:** Storage and Key Vault use firewalls (default deny, bypass AzureServices) and Entra-only auth, but
  public network access is enabled. The network layer already creates private DNS zones and subnets; no private endpoints exist.
- **Risk:** any stolen identity or misconfigured firewall rule exposes data directly from the internet.
- **Quick win:** keep default deny, remove broad bypasses, add alerts on firewall rule changes.
- **Longer term:** private endpoints + private DNS, `public_network_access_enabled = false`, and a private CI runner
  (the `runner` layer) so pipelines can still reach them.

## 2. Pipeline identity is over-privileged: **High**
- **What:** one pipeline identity has Contributor on the whole subscription and is used for both environments. It also has RBAC Administrator limited by a condition to one role (Key Vault Secrets User), which is the right pattern but should be scoped to resource groups.
- **Risk:** a compromised workflow or approver can change anything in the subscription; dev and prd share a blast radius.
- **Quick win:** scope the role to the lab resource groups, require CODEOWNERS review on `terraform/` and `.github/`,
  make checkov blocking instead of report-only.
- **Longer term:** separate identities and subscriptions per environment, custom roles per layer
  (network layer cannot touch Key Vault), policy-as-code (Azure Policy / OPA) and signed commits.

## 3. State and drift controls: **Medium**
- **What:** all environments share one state account, there is no drift detection, and state recovery is untested.
- **Risk:** a bad state write or an out-of-band portal change goes unnoticed until the next apply.
- **Quick win:** scheduled `terraform plan -detailed-exitcode` per layer that alerts on drift; resource locks on
  the state account and Key Vault.
- **Longer term:** separate state accounts per environment, restore drill for state, immutable storage on prd state.

## Additional observations from building the lab
- Shared modules pin `azurerm ~> 3.x` (action group, metric alert, AKS add-on modules), so they cannot be used
  with provider 4.x. Constraints should be `>=` and tested in CI against the current provider.
- Module `settings` are untyped maps: a missing key passes `validate` and only fails at plan time. Typed
  `object({...})` variables with optional attributes would catch this in PR checks.
- Shared diagnostic settings use deprecated `retention_policy` blocks.
- AKS in the lab uses a public API server restricted by `authorized_ip_ranges`; production should be private.
