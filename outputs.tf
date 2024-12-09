output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "postgresql_flexible_server_name" {
  value = azurerm_postgresql_flexible_server.default.name
}

output "postgresql_flexible_server_database_name" {
  value = azurerm_postgresql_flexible_server_database.default.name
}

output "postgresql_flexible_server_admin_password" {
  sensitive = true
  value     = azurerm_postgresql_flexible_server.default.administrator_password
}
