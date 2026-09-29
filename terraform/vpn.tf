# ============================================================
# P2S VPN GATEWAY
# ============================================================

resource "azurerm_public_ip" "vpn_gateway_pip" {
  name                = "${var.project_name}-vpn-gateway-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "${var.project_name}-vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  bgp_enabled   = false

  sku = "VpnGw1AZ"

  ip_configuration {
    name                          = "vpn-gateway-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }

  vpn_client_configuration {
    address_space = [
      "172.16.100.0/24"
    ]

    vpn_client_protocols = [
      "IkeV2"
    ]

    root_certificate {
      name = "AzureHubSpokeRootCert"

      public_cert_data = filebase64(
        "${path.module}/AzureHubSpokeRootCert.cer"
      )
    }
  }

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

