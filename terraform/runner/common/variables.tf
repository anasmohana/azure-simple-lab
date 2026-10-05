variable "environment" {
  description = "dev | prd"
  type        = string
}

variable "location_name" {
  type    = string
  default = "norwayeast"
}

variable "prefix" {
  type    = string
  default = "lab"
}

variable "base_tags" {
  type = map(string)
  default = {
    config_by = "terraform"
  }
}

variable "tags" {
  type = map(string)
}
