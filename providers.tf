terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "1.8.0-beta.1"
    }
  }
}

provider "nutanix" {
  username = var.NUTANIX_USERNAME
  password = var.NUTANIX_PASSWORD
  endpoint = var.NUTANIX_ENDPOINT
  port     = var.NUTANIX_PORT
  insecure = var.NUTANIX_INSECURE
}
