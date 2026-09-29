resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "${var.project_name}-spoke1-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "spoke1_vmss_subnet" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "${var.project_name}-spoke2-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "spoke2_linux_subnet" {
  name                 = "linux-app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}