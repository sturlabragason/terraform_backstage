# ------------------------------------------------------
# Configuration - Locals [resource names, location] and provider configuration.
# ------------------------------------------------------

locals {
  resource_location               = "West Europe"
  resource_group_name_landingzone = "rg-backstage"
  aks_name_landingzone            = "aks${random_string.random.result}"
  storage_account_name_aks        = lower("sa${random_string.random.result}")
  share_name                      = "postgresshare"
  acr_name                        = "acrregistry${random_string.random.result}"
  appId                           = "22937906-cbd5-4e66-a09b-33476e2cb898"
  displayName                     = "azure-cli-2022-05-09-11-01-27"
  tenant                          = "241f985c-5a26-4377-bd6d-157c2c17fb20"
  subscription_id                 = "a7a2cf01-7973-4e18-8a5d-f30983ab5dbd"
}

resource "random_string" "random" {
  length  = 5
  special = false
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  subscription_id            = local.subscription_id
  tenant_id                  = local.tenant_id
  client_secret              = var.az_client_secret
  client_id                  = local.appId
  skip_provider_registration = true
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.landingzone.kube_config.0.host
  username               = azurerm_kubernetes_cluster.landingzone.kube_config.0.username
  password               = azurerm_kubernetes_cluster.landingzone.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.landingzone.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.landingzone.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.landingzone.kube_config.0.cluster_ca_certificate)
}


data "azurerm_client_config" "landingzone" {
}

# # ------------------------------------------------------
# # Resources - Resource Groups, Virtual Network, Storage Account, Container with Terraform Statefile, Keyvault containing Service Principal Credentials 
# # ------------------------------------------------------

# resource "azurerm_resource_group" "landingzone" {
#   name     = local.resource_group_name_landingzone
#   location = local.resource_location
# }

# resource "azurerm_kubernetes_cluster" "landingzone" {
#   name                = local.aks_name_landingzone
#   resource_group_name = azurerm_resource_group.landingzone.name
#   location            = azurerm_resource_group.landingzone.location
#   dns_prefix          = "${local.aks_name_landingzone}-1"

#   default_node_pool {
#     name       = "node1545f414"
#     node_count = 1
#     vm_size    = "Standard_D2_v2"
#   }

#   identity {
#     type = "SystemAssigned"
#   }
#   # addon_profile {
#   #   http_application_routing {
#   #     enabled = true
#   #   }
#   #   azure_policy {
#   #     enabled = true
#   #   }
#   # }
# }

# resource "azurerm_container_registry" "landingzone" {
#   name                = local.acr_name
#   resource_group_name = azurerm_resource_group.landingzone.name
#   location            = azurerm_resource_group.landingzone.location
#   sku                 = "Basic"
# }

# resource "azurerm_role_assignment" "landingzone" {
#   principal_id                     = azurerm_kubernetes_cluster.landingzone.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.landingzone.id
#   skip_service_principal_aad_check = true
# }

# resource "azurerm_role_assignment" "lzpush" {
#   principal_id                     = data.azurerm_client_config.landingzone.object_id
#   role_definition_name             = "AcrPush"
#   scope                            = azurerm_container_registry.landingzone.id
#   skip_service_principal_aad_check = true
# }

resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name_aks
  resource_group_name      = azurerm_resource_group.landingzone.name
  location                 = azurerm_resource_group.landingzone.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_share" "main" {
  name                 = local.share_name
  storage_account_name = azurerm_storage_account.main.name
  quota                = 1
}

resource "azurerm_storage_account" "demo" {
  name                     = "demo${local.storage_account_name_aks}"
  resource_group_name      = azurerm_resource_group.landingzone.name
  location                 = azurerm_resource_group.landingzone.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
}