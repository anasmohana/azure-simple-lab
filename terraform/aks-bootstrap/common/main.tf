# Layer 5 - aks-bootstrap: what must exist around the cluster before workloads can run.
# Pods get Azure access through federated user-assigned identities (no secrets).
# In-cluster objects (namespaces, NetworkPolicy, RBAC, Flux) live in /k8s and are delivered by GitOps.

data "azurerm_kubernetes_cluster" "aks" {
  count               = var.enabled ? 1 : 0
  name                = local.aks_name
  resource_group_name = local.resource_group_name
}

data "azurerm_key_vault" "boot" {
  count               = var.enabled ? 1 : 0
  name                = local.key_vault_name
  resource_group_name = local.resource_group_name
}

module "workload_identity" {
  source              = "git::https://github.com/anasmohana/terraform-modules.git//modules/federated_identity_uai?ref=a3daf2d82881f9aba947a82877faac6c7007602c"
  for_each            = var.enabled ? var.namespaces : {}
  resource_group_name = local.resource_group_name
  location_name       = var.location_name
  base_tags           = local.tags
  settings = {
    uai_name = "${local.name_prefix}-${each.key}-wi"
    tags     = local.tags
    federated_identities = {
      sa = {
        uai_federated_name   = "${each.key}-${each.value}-federated"
        oidc_issuer_url      = data.azurerm_kubernetes_cluster.aks[0].oidc_issuer_url
        service_account_name = "system:serviceaccount:${each.key}:${each.value}"
      }
    }
  }
}

# Least privilege: workloads can only read secrets from the platform vault
resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = module.workload_identity
  scope                = data.azurerm_key_vault.boot[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
}

# ---------- GitOps (Flux) ----------
# Installed as an AKS extension through the Azure API, so CI never needs cluster credentials.
# Flux then pulls manifests from Git and keeps the cluster in that state.
resource "azurerm_kubernetes_cluster_extension" "flux" {
  count          = var.enabled ? 1 : 0
  name           = "flux"
  cluster_id     = data.azurerm_kubernetes_cluster.aks[0].id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "apps" {
  count      = var.enabled ? 1 : 0
  name       = "lab-gitops"
  cluster_id = data.azurerm_kubernetes_cluster.aks[0].id
  namespace  = "flux-system"
  scope      = "cluster"

  git_repository {
    url                      = var.gitops_repo_url
    reference_type           = "branch"
    reference_value          = var.gitops_branch
    sync_interval_in_seconds = 120
  }

  kustomizations {
    name                       = "infrastructure"
    path                       = "./infrastructure"
    sync_interval_in_seconds   = 120
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "apps"
    path                       = "./apps"
    depends_on                 = ["infrastructure"]
    sync_interval_in_seconds   = 120
    garbage_collection_enabled = true
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}
