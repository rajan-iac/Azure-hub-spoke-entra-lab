# ============================================================
# WINDOWS VMSS AUTOSCALING
# Minimum: 1
# Default: 1
# Maximum: 3
# ============================================================

resource "azurerm_monitor_autoscale_setting" "web_vmss_autoscale" {
  name                = "${var.project_name}-vmss-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  target_resource_id = azurerm_windows_virtual_machine_scale_set.web_vmss.id

  profile {
    name = "Web-VMSS-Autoscale"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    # --------------------------------------------------------
    # SCALE OUT
    # CPU > 70% -> Add 1 VM
    # --------------------------------------------------------

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # --------------------------------------------------------
    # SCALE IN
    # CPU < 30% -> Remove 1 VM
    # --------------------------------------------------------

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}