resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}