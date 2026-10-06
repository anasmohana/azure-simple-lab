module "bootstrap" {
  source = "../common"

  environment      = "dev"
  alert_email      = var.alert_email
  purge_protection = false
  allow_aks_subnet = true

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
    demo    = "approval-test"
  }
}

variable "alert_email" {
  type = string
}

