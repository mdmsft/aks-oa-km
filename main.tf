terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

locals {
  resource_suffix      = "${var.project}-${var.environment}-${var.location}"
  safe_resource_suffix = replace(local.resource_suffix, "-", "")
  context_name         = "${var.project}-${var.environment}"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  use_msi         = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azurerm" {
  alias           = "hub"
  use_msi         = true
  subscription_id = var.hub_subscription_id
  tenant_id       = var.tenant_id
  features {}
}

data "azurerm_client_config" "main" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_suffix}"
  location = var.location
  tags = {
    project     = var.project
    environment = var.environment
    location    = var.location
  }
}
