# ============================================================
# SPOKE 1 - WINDOWS WEB VM SCALE SET
# ============================================================

resource "azurerm_windows_virtual_machine_scale_set" "web_vmss" {
  name                 = "${var.project_name}-web-vmss"
  computer_name_prefix = "webvm"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku       = "Standard_B2s"
  instances = 1

  lifecycle {
    ignore_changes = [
      instances
    ]
  }

  admin_username = "azureadmin"
  admin_password = var.vm_admin_password

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "web-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.spoke1_vmss_subnet.id
    }
  }

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    Tier        = "Web"
    OS          = "Windows"
    ManagedBy   = "Terraform"
  }
}