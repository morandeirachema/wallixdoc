# Terraform Examples for WALLIX Bastion

This directory contains Terraform configuration examples for managing WALLIX Bastion resources using Infrastructure as Code.

## Prerequisites

- Terraform >= 1.0
- WALLIX Bastion 12.x with API access enabled
- API token with appropriate permissions

## Provider Setup

### 1. Configure Provider

Create a `provider.tf` file (see example in this directory):

```hcl
terraform {
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.14.0"
    }
  }
}

provider "wallix-bastion" {
  ip        = var.bastion_host
  user      = var.bastion_user
  token     = var.bastion_token
  api_version = "v3.12"
  port      = 443
}
```

### 2. Set Variables

Create `terraform.tfvars`:

```hcl
bastion_host  = "bastion.example.com"
bastion_user  = "admin"
bastion_token = "your-api-token"
```

Or use environment variables:

```bash
export TF_VAR_bastion_host="bastion.example.com"
export TF_VAR_bastion_user="admin"
export TF_VAR_bastion_token="your-api-token"
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Available Resources

The WALLIX Bastion Terraform provider supports managing:

| Resource Type | Description |
|---------------|-------------|
| `wallix-bastion_device` | Target devices/servers |
| `wallix-bastion_device_service` | Services on devices (SSH, RDP, etc.) |
| `wallix-bastion_device_localdomain` | Local domains on devices |
| `wallix-bastion_domain` | Global domains |
| `wallix-bastion_domain_account` | Domain accounts |
| `wallix-bastion_domain_account_credential` | Account credentials |
| `wallix-bastion_user` | Local users |
| `wallix-bastion_usergroup` | User groups |
| `wallix-bastion_targetgroup` | Target groups |
| `wallix-bastion_authorization` | Access authorizations |
| `wallix-bastion_authdomain_ldap` | LDAP authentication domains |
| `wallix-bastion_authdomain_ad` | Active Directory authentication |
| `wallix-bastion_cluster` | Cluster configuration |
| `wallix-bastion_externalauth_ldap` | External LDAP authentication |
| `wallix-bastion_timeframe` | Access timeframes |

## Example Files

See the `resources/` directory for complete examples:

- `device.tf` - Device and service configuration
- `user.tf` - User and group management
- `authorization.tf` - Access authorization rules
- `domain.tf` - Domain and credential management

## Best Practices

### State Management

Use remote state for team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "wallix-bastion/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

### Sensitive Values

Never commit tokens or passwords:

```hcl
variable "bastion_token" {
  description = "API token for WALLIX Bastion"
  type        = string
  sensitive   = true
}
```

### Resource Dependencies

Use explicit dependencies when needed:

```hcl
resource "wallix-bastion_device_service" "ssh" {
  device_id = wallix-bastion_device.server.id
  # ...
  depends_on = [wallix-bastion_device.server]
}
```

## Troubleshooting

### Common Issues

**API Connection Failed**
```
Error: failed to connect to Bastion API
```
- Verify `ip` and `port` settings
- Check firewall rules (port 443)
- Confirm API is enabled on Bastion

**Authentication Failed**
```
Error: authentication failed
```
- Verify API token is valid
- Check user has API access permissions
- Confirm token hasn't expired

**Version Mismatch**
```
Error: API version not supported
```
- Update provider version or change `api_version`
- Check Bastion version compatibility

## Resources

- [Provider Documentation](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs)
- [GitHub Repository](https://github.com/wallix/terraform-provider-wallix-bastion)
- [WALLIX Automation Showroom](https://github.com/wallix/Automation_Showroom)
