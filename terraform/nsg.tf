# ============================================================
# SPOKE 1 - VMSS NSG
# ============================================================

resource "azurerm_network_security_group" "spoke1_nsg" {
  name                = "${var.project_name}-spoke1-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Allow HTTP from P2S VPN clients
resource "azurerm_network_security_rule" "spoke1_allow_http_p2s" {
  name                       = "Allow-HTTP-P2S"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "172.16.100.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke1_nsg.name
}

# Allow traffic from Spoke 2
resource "azurerm_network_security_rule" "spoke1_allow_spoke2" {
  name                       = "Allow-Spoke2"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "10.2.0.0/16"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke1_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "spoke1_nsg_association" {
  subnet_id                 = azurerm_subnet.spoke1_vmss_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke1_nsg.id
}


# ============================================================
# SPOKE 2 - LINUX APP NSG
# ============================================================

resource "azurerm_network_security_group" "spoke2_nsg" {
  name                = "${var.project_name}-spoke2-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Allow Flask application from P2S VPN clients
resource "azurerm_network_security_rule" "spoke2_allow_flask_p2s" {
  name                       = "Allow-Flask-P2S"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5000"
  source_address_prefix      = "172.16.100.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke2_nsg.name
}

# Allow Flask traffic from Spoke 1
resource "azurerm_network_security_rule" "spoke2_allow_flask_spoke1" {
  name                       = "Allow-Flask-Spoke1"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5000"
  source_address_prefix      = "10.1.0.0/16"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke2_nsg.name
}

# SSH from P2S VPN only
resource "azurerm_network_security_rule" "spoke2_allow_ssh_p2s" {
  name                       = "Allow-SSH-P2S"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "172.16.100.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke2_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "spoke2_nsg_association" {
  subnet_id                 = azurerm_subnet.spoke2_linux_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke2_nsg.id
}

resource "azurerm_network_security_rule" "spoke1_allow_rdp_p2s" {
  name      = "Allow-RDP-P2S"
  priority  = 120
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "3389"

  source_address_prefix      = "172.16.100.0/24"
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.spoke1_nsg.name
}