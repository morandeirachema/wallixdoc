# WALLIX PAM4OT Examples

> Practical code examples for automating and integrating with PAM4OT.

---

## Overview

This directory contains ready-to-use examples for:

| Category | Description | Use Case |
|----------|-------------|----------|
| **Terraform** | Infrastructure as Code | Automated deployment and configuration |
| **Python API** | REST API client library | Custom integrations and scripts |
| **Shell Scripts** | curl-based API calls | Quick automation and testing |
| **Automation** | Ansible playbooks | Configuration management |
| **Labs** | Test environment setup | Learning and validation |

---

## Quick Start

### Terraform

Deploy PAM4OT resources using Infrastructure as Code.

```bash
cd terraform
export TF_VAR_bastion_host="pam4ot.company.com"
export TF_VAR_bastion_user="admin"
export TF_VAR_bastion_token="your-api-key"
terraform init && terraform plan
```

### Python API Client

Use the Python client for programmatic access.

```bash
cd api/python
pip install requests
export BASTION_HOST="pam4ot.company.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
python list_devices.py
```

### Shell Scripts (curl)

Quick API calls using shell scripts.

```bash
cd api/curl
export BASTION_HOST="pam4ot.company.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
./get_status.sh
```

---

## Directory Structure

```
examples/
│
├── terraform/                    # Infrastructure as Code
│   ├── README.md                 # Terraform guide
│   ├── provider.tf               # Provider configuration
│   └── resources/
│       ├── device.tf             # Device management
│       ├── user.tf               # User provisioning
│       └── authorization.tf      # Access policies
│
├── api/                          # REST API Examples
│   ├── README.md                 # API guide
│   ├── python/
│   │   ├── bastion_client.py     # Reusable client class
│   │   ├── list_devices.py       # List all devices
│   │   ├── create_user.py        # User provisioning
│   │   └── rotate_password.py    # Credential rotation
│   └── curl/
│       ├── get_status.sh         # Health check
│       ├── list_devices.sh       # Device listing
│       └── create_session.sh     # Session management
│
├── automation/                   # Configuration Management
│   ├── README.md                 # Automation guide
│   └── ansible/
│       ├── inventory.yml         # Host inventory
│       └── playbooks/
│           ├── deploy.yml        # Initial deployment
│           └── configure.yml     # Configuration tasks
│
└── labs/                         # Test Environments
    └── README.md                 # Lab guide (VM-based)
```

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
| WALLIX Bastion | 12.x | Target PAM4OT system |
| Terraform | >= 1.0 | `apt install terraform` |
| Python | >= 3.8 | `apt install python3` |
| requests (Python) | latest | `pip install requests` |
| curl | any | Pre-installed |
| jq | any | `apt install jq` |

### API Key Setup

```bash
# Generate API key in PAM4OT Web UI:
# Administration → API Keys → Generate

# Or via CLI:
wabadmin api-key create --user admin --name "automation-key"
```

---

## Compatibility Matrix

| Provider Version | API Version | Terraform | PAM4OT Version |
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

- [Terraform Examples](./terraform/README.md) - Infrastructure as Code details
- [API Examples](./api/README.md) - REST API client usage
- [Automation Examples](./automation/README.md) - Ansible playbooks
- [API Reference](../docs/26-api-reference/README.md) - Complete API documentation

---

<p align="center">
  <sub>PAM4OT Examples • Version 2.0 • January 2026</sub>
</p>
