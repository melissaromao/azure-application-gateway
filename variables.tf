variable "location" {
  description = "Região onde os recursos serão criados"
  type        = string
}

variable "project_name" {
  description = "Prefixo para identificação dos recursos"
  type        = string
}

variable "address_space" {
  description = "Faixa de IP da Virtual Network"
  type        = list(string)
}

variable "admin_username" {
  description = "Usuário administrador das máquinas virtuais"
  type        = string
  default     = "azureuser"
}