
locals {
  backend_pool_ids = {
    default = one([
      for pool in azurerm_application_gateway.appgw.backend_address_pool :
      pool.id if pool.name == "pool-default"
    ])

    imagens = one([
      for pool in azurerm_application_gateway.appgw.backend_address_pool :
      pool.id if pool.name == "pool-imagens"
    ])

    videos = one([
      for pool in azurerm_application_gateway.appgw.backend_address_pool :
      pool.id if pool.name == "pool-videos"
    ])
  }

  ssh_public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "azurerm_linux_virtual_machine_scale_set" "default" {
  name                = "vmss-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku       = "Standard_D2as_v4"
  instances = 1

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-app"
    primary = true

    ip_configuration {
      name      = "ipconfig-app"
      primary   = true
      subnet_id = azurerm_subnet.backend.id

      application_gateway_backend_address_pool_ids = [
        local.backend_pool_ids.default,
        local.backend_pool_ids.imagens,
        local.backend_pool_ids.videos
      ]
    }
  }

  tags = {
    project     = var.project_name
    environment = "lab"
    role        = "application"
    managed_by  = "terraform"
  }
}
