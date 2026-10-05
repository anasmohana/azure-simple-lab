module "aks" {
  source = "../common"

  environment = "prd"
  enabled     = false # flip to true to deploy this layer

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

