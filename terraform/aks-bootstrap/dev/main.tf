module "aks_bootstrap" {
  source = "../common"

  environment = "dev"
  enabled     = false # flip to true to deploy this layer

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

