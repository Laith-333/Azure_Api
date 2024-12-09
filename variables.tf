variable "subscription_id" {
  description = "The subscription ID for the Azure provider"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "The location for the resource group"
  type        = string
  default     = "North Europe"
}

variable "vnet_name" {
  description = "The name of the Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = list(string)
}

variable "acr_name" {
  description = "The base name for the Azure Container Registry"
  type        = string
}
