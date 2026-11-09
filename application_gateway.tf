resource "azurerm_public_ip" "appgw_ip" {
  name                = "pip-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    project = var.project_name
  }
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  # Subnet exclusiva do Application Gateway
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Porta HTTP
  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  # Endereço público
  frontend_ip_configuration {
    name                 = "frontend-public"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  # Backend Pool padrão
  backend_address_pool {
    name = "pool-default"
  }

  # Backend Pool de imagens
  backend_address_pool {
    name = "pool-imagens"
  }

  # Backend Pool de vídeos
  backend_address_pool {
    name = "pool-videos"
  }

  # Configuração de comunicação com os backends
  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "health-probe"
  }

  # Verificação de saúde
  probe {
    name                = "health-probe"
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  # Listener HTTP
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "frontend-public"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  # Mapa de roteamento por caminho
  url_path_map {
    name = "path-map"

    # Caminhos não especificados utilizam o pool padrão
    default_backend_address_pool_name  = "pool-default"
    default_backend_http_settings_name = "http-settings"

    path_rule {
      name = "route-imagens"

      paths = [
        "/imagens",
        "/imagens/*"
      ]

      backend_address_pool_name  = "pool-imagens"
      backend_http_settings_name = "http-settings"
    }

    path_rule {
      name = "route-videos"

      paths = [
        "/videos",
        "/videos/*"
      ]

      backend_address_pool_name  = "pool-videos"
      backend_http_settings_name = "http-settings"
    }
  }

  # Regra de roteamento
  request_routing_rule {
    name               = "routing-rule"
    priority           = 100
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener-http"
    url_path_map_name  = "path-map"
  }

  tags = {
    project     = var.project_name
    environment = "lab"
    managed_by  = "terraform"
  }
}