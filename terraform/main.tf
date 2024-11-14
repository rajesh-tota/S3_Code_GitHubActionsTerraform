terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ws-devops"
    storage_account_name = "devopshackathontfstate"
    container_name       = "tfstate"
    key                  = "tota0610.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Get resource group
data "azurerm_resource_group" "wsdevops" {
  name = var.rg_name
}

# App Service Plan
resource "azurerm_app_service_plan" "sp1" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Web App
resource "azurerm_app_service" "website" {
  name                = var.web_app_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  app_service_plan_id = azurerm_app_service_plan.sp1.id

  site_config {
    linux_fx_version = "NODE|22-lts"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY          = azurerm_application_insights.appi.instrumentation_key
    APPINSIGHTS_PROFILERFEATURE_VERSION     = "1.0.0"
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION     = "1.0.0"
    APPLICATIONINSIGHTS_CONNECTION_STRING   = azurerm_application_insights.appi.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log" {
  name                = "tota0610-lg-analytics"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights
resource "azurerm_application_insights" "appi" {
  name                = "totanov-api"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  workspace_id        = azurerm_log_analytics_workspace.log.id
  application_type    = "web"
}
