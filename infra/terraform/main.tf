terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

# Variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "acr-sample-rg"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "acrsamplekoudaiii"
}

variable "container_app_name" {
  description = "Container app name"
  type        = string
  default     = "acr-sample-app"
}

variable "container_app_environment_name" {
  description = "Container app environment name"
  type        = string
  default     = "acr-sample-env"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "acr-sample-logs"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "production"
    project     = "acr-sample"
    managed_by  = "terraform"
  }
}

# Resource Group using Azure Verified Module
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace using Azure Verified Module
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.1"

  name                = var.log_analytics_workspace_name
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags

  workspace_sku          = "PerGB2018"
  workspace_retention_in_days = 30
}

# Azure Container Registry using Azure Verified Module
module "container_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.4.0"

  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags

  sku                     = "Basic"
  admin_enabled           = true
  public_network_access   = true
}

# Container Apps Environment using Azure Verified Module
module "container_app_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.3.1"

  name                = var.container_app_environment_name
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags

  log_analytics_workspace_id = module.log_analytics.resource_id
}

# Container App (using azapi provider as there's no AVM for container apps yet)
resource "azapi_resource" "container_app" {
  type      = "Microsoft.App/containerApps@2024-03-01"
  name      = var.container_app_name
  parent_id = module.resource_group.resource_id
  location  = var.location
  tags      = var.tags

  body = jsonencode({
    properties = {
      managedEnvironmentId = module.container_app_environment.resource_id
      configuration = {
        activeRevisionsMode = "Single"
        ingress = {
          external   = true
          targetPort = 8000
          transport  = "auto"
          allowInsecure = false
        }
        registries = [
          {
            server            = module.container_registry.login_server
            username          = module.container_registry.admin_username
            passwordSecretRef = "acr-password"
          }
        ]
        secrets = [
          {
            name  = "acr-password"
            value = module.container_registry.admin_password
          }
        ]
      }
      template = {
        containers = [
          {
            name  = var.container_app_name
            image = "${module.container_registry.login_server}/acrsample:latest"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
            env = [
              {
                name  = "DEBUG"
                value = "False"
              }
            ]
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 3
          rules = [
            {
              name = "http-rule"
              http = {
                metadata = {
                  concurrentRequests = "10"
                }
              }
            }
          ]
        }
      }
    }
  })

  depends_on = [
    module.container_registry,
    module.container_app_environment
  ]
}

# Outputs
output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.container_registry.login_server
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = module.container_registry.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "ACR admin password"
  value       = module.container_registry.admin_password
  sensitive   = true
}

output "container_app_fqdn" {
  description = "Container app FQDN"
  value       = jsondecode(azapi_resource.container_app.output).properties.configuration.ingress.fqdn
}

output "container_app_url" {
  description = "Container app URL"
  value       = "https://${jsondecode(azapi_resource.container_app.output).properties.configuration.ingress.fqdn}"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.log_analytics.resource_id
}
