output "acr" {
  description = "ACR login server, for example acraksdemo17825.azurecr.io"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  description = "AKS cluster name (use with az aks get-credentials)."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  description = "Resource group that holds ACR and AKS."
  value       = data.azurerm_resource_group.existing_rg.name
}
