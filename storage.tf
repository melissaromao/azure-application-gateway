# Gera um sufixo aleatório para o nome da Storage Account
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Cria a Storage Account
resource "azurerm_storage_account" "storage" {
  name = "st${replace(var.project_name, "-", "")}${random_string.storage_suffix.result}"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = {
    project     = var.project_name
    environment = "lab"
    managed_by  = "terraform"
  }
}

# Container privado para os uploads
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}