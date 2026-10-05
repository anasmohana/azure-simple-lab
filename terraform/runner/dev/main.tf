module "runner" {
  source = "../common"

  environment = "dev"
  enabled     = false # flip to true to deploy this layer

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

