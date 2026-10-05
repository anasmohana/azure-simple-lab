module "network" {
  source = "../common"

  environment   = "dev"
  address_space = "10.10.0.0/16"

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

