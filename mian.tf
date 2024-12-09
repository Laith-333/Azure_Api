provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Virtual Network
resource "azurerm_virtual_network" "hub_network" {
  name                = var.vnet_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = var.vnet_address_space
}

# Subnet for Container
resource "azurerm_subnet" "container_subnet" {
  name                 = "container-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.hub_network.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet for Database
resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.hub_network.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Random String for Unique Naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Basic"
  admin_enabled       = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "example-postgres-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  administrator_login    = "adminuser"
  administrator_password = "ComplexPassword123!"
  sku_name               = "B_Standard_B1ms"
  version                = "13"

  storage_mb            = 32768
  backup_retention_days = 7
  zone                  = "1"
}

# PostgreSQL Flexible Server Database
resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = "exampledb"
  server_id = azurerm_postgresql_flexible_server.default.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Private Endpoint for PostgreSQL
resource "azurerm_private_endpoint" "postgresql_private_endpoint" {
  name                = "postgresql-private-endpoint"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.database_subnet.id

  private_service_connection {
    name                           = "postgresql-private-connection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.default.id
    is_manual_connection           = false
  }
}

# Container Group
resource "azurerm_container_group" "api_container" {
  name                = "api-container-group"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"

  ip_address_type = "Private"
  subnet_ids      = [azurerm_subnet.container_subnet.id]

  container {
    name   = "api-container"
    image  = "${azurerm_container_registry.acr.login_server}/my-api:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      DB_HOST     = azurerm_postgresql_flexible_server.default.fqdn
      DB_USER     = "adminuser"
      DB_PASSWORD = "ComplexPassword123!"
    }
  }

  tags = {
    environment = "production"
  }
}
