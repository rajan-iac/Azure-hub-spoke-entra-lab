# ============================================================
# SPOKE 1 ROUTE TABLE
# Traffic destined for Spoke-2 goes through Azure Firewall
# ============================================================

resource "azurerm_route_table" "spoke1_rt" {
  name                = "${var.project_name}-spoke1-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_route" "spoke1_to_spoke2" {
  name                = "spoke1-to-spoke2-via-firewall"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.spoke1_rt.name

  address_prefix         = "10.2.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "spoke1_rt_association" {
  subnet_id      = azurerm_subnet.spoke1_vmss_subnet.id
  route_table_id = azurerm_route_table.spoke1_rt.id
}


# ============================================================
# SPOKE 2 ROUTE TABLE
# Traffic destined for Spoke-1 goes through Azure Firewall
# ============================================================

resource "azurerm_route_table" "spoke2_rt" {
  name                = "${var.project_name}-spoke2-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_route" "spoke2_to_spoke1" {
  name                = "spoke2-to-spoke1-via-firewall"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.spoke2_rt.name

  address_prefix         = "10.1.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub_firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "spoke2_rt_association" {
  subnet_id      = azurerm_subnet.spoke2_linux_subnet.id
  route_table_id = azurerm_route_table.spoke2_rt.id
}