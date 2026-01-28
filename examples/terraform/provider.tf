# WALLIX Bastion Terraform Provider Configuration
# Reference: https://registry.terraform.io/providers/wallix/wallix-bastion

terraform {
  required_version = ">= 1.0"

  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.14.0"
    }
  }
}

# Provider configuration
# Authentication uses API token generated in WALLIX Bastion
provider "wallix-bastion" {
  ip          = var.bastion_host
  user        = var.bastion_user
  token       = var.bastion_token
  api_version = var.bastion_api_version
  port        = var.bastion_port
}

# Variables
variable "bastion_host" {
  description = "WALLIX Bastion hostname or IP address"
  type        = string
}

variable "bastion_user" {
  description = "Username for API authentication"
  type        = string
}

variable "bastion_token" {
  description = "API token for authentication (generate in Bastion admin console)"
  type        = string
  sensitive   = true
}

variable "bastion_api_version" {
  description = "API version to use (v3.12 for Bastion 12.x)"
  type        = string
  default     = "v3.12"
}

variable "bastion_port" {
  description = "HTTPS port for API access"
  type        = number
  default     = 443
}
