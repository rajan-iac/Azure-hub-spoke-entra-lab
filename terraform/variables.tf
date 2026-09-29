variable "project_name" {
  description = "Project name used for Azure resource naming"
  type        = string
  default     = "hub-spoke-lab"
}

variable "location" {
  description = "Azure region for the project"
  type        = string
  default     = "Central India"
}

variable "vm_admin_password" {
  description = "Administrator password for Windows VMSS"
  type        = string
  sensitive   = true
}