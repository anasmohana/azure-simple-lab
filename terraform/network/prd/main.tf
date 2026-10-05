module "network" {
  source = "../common"

  environment   = "prd"
  address_space = "10.20.0.0/16"

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

