locals {
  clusters = {
    main = {
      name                       = local.aks_name
      location                   = var.location_name
      resource_group_name        = local.resource_group_name
      kubernetes_version         = var.kubernetes_version
      sku_tier                   = var.environment == "prd" ? "Standard" : "Free"
      dns_prefix_private_cluster = local.aks_name
      private_cluster_enabled    = true
      oidc_issuer_enabled        = true
      workload_identity_enabled  = true
      azure_policy_enabled       = true
      local_account_disabled     = true # no static admin kubeconfig
      run_command_enabled        = false
      image_cleaner_enabled      = true

      automatic_upgrade_channel = "patch"
      node_os_upgrade_channel   = "NodeImage"

      identity = {
        type = "SystemAssigned"
      }

      azure_active_directory_role_based_access_control = {
        azure_rbac_enabled     = true
        tenant_id              = data.azurerm_client_config.current.tenant_id
        admin_group_object_ids = var.admin_group_object_ids
      }

      network_profile = {
        network_plugin    = "azure"
        network_policy    = "calico"
        service_cidr      = "172.16.0.0/16"
        dns_service_ip    = "172.16.0.10"
        outbound_type     = "loadBalancer"
        load_balancer_sku = "standard"
      }

      key_vault_secrets_provider = {
        secret_rotation_enabled = true
      }

      oms_agent = {
        log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logs.id
      }

      default_node_pool = {
        name                         = "system"
        vm_size                      = "Standard_D2s_v5"
        vnet_subnet_id               = data.azurerm_subnet.aks.id
        availability_zones           = ["1", "2", "3"]
        auto_scaling_enabled         = true
        min_count                    = var.environment == "prd" ? 3 : 1
        max_count                    = 5
        only_critical_addons_enabled = true
        os_sku                       = "AzureLinux"
        temporary_name_for_rotation  = "systemtmp"
        upgrade_settings = {
          max_surge = "33%"
        }
      }

      node_pools = {
        user = {
          name                 = "user"
          vm_size              = "Standard_D4s_v5"
          vnet_subnet_id       = data.azurerm_subnet.aks.id
          availability_zones   = ["1", "2", "3"]
          auto_scaling_enabled = true
          min_count            = var.environment == "prd" ? 3 : 1
          max_count            = 12
          os_sku               = "AzureLinux"
        }
      }

      tags = local.tags
    }
  }
}
