# If I were reviewing this as production: first three findings

1. **Public network paths remain.** Storage and Key Vault use firewalls + service endpoints, but public
   endpoints are still enabled. Move to Private Endpoints + private DNS zones and disable public access.
   (Modules support `private_endpoint`; the network layer already creates the private DNS zones, the lab just skips the endpoints for cost.)
2. **Pipeline identity is over-privileged and the apply path is thin.** One identity is Contributor on the
   whole subscription for both envs. Split identities per environment/subscription, scope to resource group,
   add policy-as-code (checkov is report-only today), require signed commits/CODEOWNERS on `terraform/`.
3. **State and drift controls.** One state account for all envs, no drift detection, no DR test for state.
   Separate state per environment/subscription, scheduled `plan -detailed-exitcode` drift job that alerts,
   resource locks on state + Key Vault.

Also noticed while building: shared modules still pin `azurerm ~>3.x` (action group, metric alert, AKS)
so they can't be used with provider 4.x; I worked around one with a native resource. Version constraints in
shared modules should be `>=` with CI testing against the current provider.
