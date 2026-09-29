# ============================================================
# AZURE FIREWALL - HUB
# ============================================================

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall_pip" {
  name                = "${var.project_name}-firewall-pip"
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


# Azure Firewall
resource "azurerm_firewall" "hub_firewall" {
  name                = "${var.project_name}-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "AZFW_VNet"
  sku_tier = "Standard"

  ip_configuration {
    name                 = "firewall-ipconfig"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
} # ============================================================
# FIREWALL NETWORK RULES - SPOKE TO SPOKE
# ============================================================

resource "azurerm_firewall_network_rule_collection" "spoke_to_spoke" {
  name                = "Allow-Spoke-to-Spoke"
  azure_firewall_name = azurerm_firewall.hub_firewall.name
  resource_group_name = azurerm_resource_group.rg.name

  priority = 100
  action   = "Allow"

  # Windows VMSS -> Linux Flask App
  rule {
    name = "Allow-VMSS-to-Flask"

    source_addresses = [
      "10.1.0.0/16"
    ]

    destination_addresses = [
      "10.2.0.0/16"
    ]

    destination_ports = [
      "5000"
    ]

    protocols = [
      "TCP"
    ]
  }

  # Linux VM -> Windows IIS
  rule {
    name = "Allow-Linux-to-IIS"

    source_addresses = [
      "10.2.0.0/16"
    ]

    destination_addresses = [
      "10.1.0.0/16"
    ]

    destination_ports = [
      "80"
    ]

    protocols = [
      "TCP"
    ]
  }

  # ICMP - Spoke 1 -> Spoke 2
  rule {
    name = "Allow-ICMP-Spoke1-to-Spoke2"

    source_addresses = [
      "10.1.0.0/16"
    ]

    destination_addresses = [
      "10.2.0.0/16"
    ]

    destination_ports = [
      "*"
    ]

    protocols = [
      "ICMP"
    ]
  }

  # ICMP - Spoke 2 -> Spoke 1
  rule {
    name = "Allow-ICMP-Spoke2-to-Spoke1"

    source_addresses = [
      "10.2.0.0/16"
    ]

    destination_addresses = [
      "10.1.0.0/16"
    ]

    destination_ports = [
      "*"
    ]

    protocols = [
      "ICMP"
    ]
  }
}