# WALLIX Bastion Examples

> Practical code examples for automating and integrating with WALLIX Bastion.

---

## Overview

This directory contains ready-to-use examples for:

| Category | Description | Use Case |
|----------|-------------|----------|
| **Terraform** | Infrastructure as Code | Automated deployment and configuration |
| **Python API** | REST API client library | Custom integrations and scripts |
| **Shell Scripts** | curl-based API calls | Quick automation and testing |
| **Ansible** | Ansible playbooks | Configuration management |
| **Labs** | Test environment setup | Learning and validation |

---

## Quick Start

### Ansible

```bash
cd ansible
pip install ansible>=2.12
export WALLIX_HOST="bastion.example.com"
export WALLIX_API_KEY="your-api-key"
export WALLIX_USER="api-admin"
ansible-playbook playbooks/health_check.yml
```

### Terraform

Deploy WALLIX Bastion resources using Infrastructure as Code.

```bash
cd terraform
export TF_VAR_bastion_host="wallix.company.com"
export TF_VAR_bastion_user="admin"
export TF_VAR_bastion_token="your-api-key"
terraform init && terraform plan
```

### Python API Client

Use the Python client for programmatic access.

```bash
cd api/python
pip install requests
export BASTION_HOST="wallix.company.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
python list_devices.py
```

### Shell Scripts (curl)

Quick API calls using shell scripts.

```bash
cd api/curl
export BASTION_HOST="wallix.company.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
./get_status.sh
```

---

## Directory Structure

```
examples/
├── ansible/                         # Ansible automation
│   ├── playbooks/
│   │   ├── provision_devices.yml    # Bulk device provisioning
│   │   ├── provision_users.yml      # User lifecycle management
│   │   ├── manage_accounts.yml      # Account/password operations
│   │   ├── manage_authorizations.yml# Authorization policies
│   │   ├── health_check.yml         # Health checks
│   │   ├── backup_config.yml        # Configuration backup
│   │   └── sync_from_cmdb.yml       # ServiceNow/CMDB sync
│   ├── roles/wallix_bastion/        # Reusable Ansible role
│   ├── files/csv/                   # Sample import files
│   └── filter_plugins/              # Custom filters
│
├── terraform/                       # Infrastructure as Code
│   ├── README.md                    # Terraform guide
│   ├── provider.tf                  # Provider configuration
│   └── resources/
│       └── device.tf                # Device management
│
├── api/                             # REST API Examples
│   ├── README.md                    # API guide
│   ├── python/
│   │   ├── bastion_client.py        # Reusable client class
│   │   └── list_devices.py          # List all devices
│   └── curl/
│       ├── get_status.sh            # Health check
│       └── list_devices.sh          # Device listing
│
├── automation/                      # Additional automation
│   └── README.md                    # Automation guide
│
└── labs/                            # Test Environments
    └── README.md                    # Lab guide (VM-based)
```

---

## Ansible Playbooks

| Playbook | Description | Use Case |
|----------|-------------|----------|
| `provision_devices.yml` | Bulk device onboarding | Import servers from CSV/CMDB |
| `provision_users.yml` | User lifecycle management | Sync users from LDAP/CSV |
| `manage_accounts.yml` | Password operations | Rotate credentials, checkout |
| `manage_authorizations.yml` | Access policies | Create/modify authorizations |
| `health_check.yml` | System health checks | Daily health monitoring |
| `backup_config.yml` | Configuration export | Backup WALLIX config via API |
| `sync_from_cmdb.yml` | CMDB synchronization | ServiceNow integration |

See [ansible/README.md](./ansible/README.md) for full documentation.

---

## Examples by Use Case

### Device Management

| Task | Terraform | Python | curl |
|------|-----------|--------|------|
| List devices | `terraform state list` | `list_devices.py` | `list_devices.sh` |
| Create device | `device.tf` | `create_device.py` | `create_device.sh` |
| Update device | `device.tf` (modify) | `update_device.py` | `update_device.sh` |
| Delete device | `terraform destroy` | `delete_device.py` | `delete_device.sh` |

### User Provisioning

| Task | Terraform | Python | curl |
|------|-----------|--------|------|
| Create user | `user.tf` | `create_user.py` | `create_user.sh` |
| Assign groups | `user.tf` | `assign_groups.py` | - |
| Sync from LDAP | - | `ldap_sync.py` | - |

### Password Management

| Task | Python | curl |
|------|--------|------|
| Rotate password | `rotate_password.py` | `rotate_password.sh` |
| Check out credential | `checkout_credential.py` | `checkout.sh` |
| Check in credential | `checkin_credential.py` | `checkin.sh` |

---

## Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| WALLIX Bastion | 12.x | Target WALLIX Bastion system |
| Terraform | >= 1.0 | `apt install terraform` |
| Python | >= 3.8 | `apt install python3` |
| requests (Python) | latest | `pip install requests` |
| curl | any | Pre-installed |
| jq | any | `apt install jq` |

### API Key Setup

```bash
# Generate API key in WALLIX Bastion Web UI:
# Administration → API Keys → Generate

# Or via CLI:
wabadmin api-key create --user admin --name "automation-key"
```

---

## Compatibility Matrix

| Provider Version | API Version | Terraform | WALLIX Bastion Version |
|------------------|-------------|-----------|----------------|
| 0.14.x | v3.12 | >= 1.0 | 12.1.x |
| 0.13.x | v3.6 | >= 0.14 | 12.0.x |

---

## Common Patterns

### Error Handling (Python)

```python
from bastion_client import BastionClient, BastionAPIError

client = BastionClient()
try:
    devices = client.list_devices()
except BastionAPIError as e:
    print(f"API Error: {e.status_code} - {e.message}")
```

### Pagination (curl)

```bash
# Fetch all pages
PAGE=1
while true; do
    RESULT=$(curl -s "${BASTION_HOST}/api/devices?page=${PAGE}")
    echo "$RESULT" | jq '.data[]'
    NEXT=$(echo "$RESULT" | jq -r '.next')
    [ "$NEXT" == "null" ] && break
    PAGE=$((PAGE + 1))
done
```

---

## Resources

| Resource | URL |
|----------|-----|
| Terraform Registry | https://registry.terraform.io/providers/wallix/wallix-bastion |
| Provider GitHub | https://github.com/wallix/terraform-provider-wallix-bastion |
| REST API Samples | https://github.com/wallix/wbrest_samples |
| API Documentation | https://pam.wallix.one/documentation |
| SCIM API | https://scim.wallix.com/scim/doc/Usage.html |

---

## Next Steps

- [Ansible Playbooks](./ansible/README.md) - Configuration management
- [Terraform Examples](./terraform/README.md) - Infrastructure as Code
- [API Examples](./api/README.md) - REST API client usage
- [Automation Examples](./automation/README.md) - Additional automation
- [API Reference](../docs/17-api-reference/README.md) - Complete API documentation

---

<p align="center">
  <a href="./ansible/README.md">Ansible</a> •
  <a href="./terraform/README.md">Terraform</a> •
  <a href="./api/README.md">API</a>
</p>

<p align="center">
  <sub>WALLIX Bastion Examples • Version 2.0 • February 2026</sub>
</p>
