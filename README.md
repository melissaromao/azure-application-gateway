# Azure Application Gateway com Terraform

Infraestrutura Terraform para provisionar um ambiente Azure com Application Gateway e roteamento HTTP por caminho.

## Objetivo

O Application Gateway recebe as requisições públicas na porta 80 e direciona o tráfego para pools de backend conforme a URL:

| Rota | Pool de backend | Responsabilidade |
| --- | --- | --- |
| `/` e demais caminhos | `pool-default` | Tráfego padrão do site |
| `/imagens` e `/imagens/*` | `pool-imagens` | Gerenciamento de imagens |
| `/videos` e `/videos/*` | `pool-videos` | Gerenciamento de vídeos |

O projeto utiliza uma VM Scale Set Linux Ubuntu 22.04, atualmente com uma instância associada aos três pools. O Application Gateway utiliza SKU `Standard_v2` com escalabilidade automática de 1 a 2 instâncias.

> [!NOTE]
> Os três pools existem como destinos de roteamento distintos, mas a configuração atual associa a mesma VM Scale Set aos três. Para manter máquinas separadas por rota, é necessário criar um scale set para cada pool.

## Recursos provisionados

- Resource Group e Virtual Network
- Subnet exclusiva para o Application Gateway
- Subnet de backend protegida por Network Security Group
- Application Gateway com IP público estático
- Listener HTTP na porta 80
- Roteamento baseado em caminho
- VM Scale Set Linux com acesso SSH por chave pública
- Storage Account com container privado `uploads`

## Pré-requisitos

- Terraform instalado
- Azure CLI instalado e autenticado
- Assinatura Azure selecionada
- Chave pública em `~/.ssh/id_ed25519.pub`

## Uso

Crie um arquivo `terraform.tfvars`:

```hcl
location       = "Brazil South"
project_name   = "appgw"
address_space  = ["10.0.0.0/16"]
admin_username = "azureuser"
```

Inicialize e aplique a infraestrutura:

```bash
terraform init
terraform plan
terraform apply
```

Após a aplicação, o endereço IP público do Application Gateway pode ser consultado com:

```bash
terraform output application_gateway_public_ip
```

## Arquivos principais

- `application_gateway.tf`: Application Gateway, listener, health probe, pools e regras de roteamento.
- `vmss.tf`: VM Scale Set e associação aos pools de backend.
- `main.tf`: Resource Group, rede, subnets e regras de segurança.
- `storage.tf`: Storage Account e container privado para uploads.
- `app.py`: Aplicação Flask para as rotas padrão, `/imagens` e `/videos`.
