# ============================================================
# LOG ANALYTICS WORKSPACE
# ============================================================

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}


# ============================================================
# AZURE FIREWALL DIAGNOSTIC LOGGING
# ============================================================

resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostics" {
  name                       = "${var.project_name}-firewall-diagnostics"
  target_resource_id         = azurerm_firewall.hub_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}