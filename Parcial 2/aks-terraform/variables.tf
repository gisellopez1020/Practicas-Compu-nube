variable "resource_group_name" {
  description = "Nombre del resource group en Azure"
  default     = "rg-microapp"
}

variable "location" {
  description = "Region de Azure (usar eastus2, canadacentral, centralus o southcentralus para cuentas estudiante)"
  default     = "eastus2"
}

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  default     = "aks-microapp"
}
