module "bootstrap" {
  source = "../common"

  environment      = "prd"
  alert_email      = var.alert_email
  purge_protection = true

  tags = {
    project = "azure-simple-lab"
    owner   = "platform"
  }
}

variable "alert_email" {
  type = string
}

