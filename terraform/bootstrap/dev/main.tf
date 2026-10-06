module "bootstrap" {
  source = "../common"

  environment      = "dev"
  alert_email      = var.alert_email
  purge_protection = false

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
    demo    = "approval-test"
  }
}

variable "alert_email" {
  type = string
}

