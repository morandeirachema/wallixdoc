# WALLIX Bastion Examples

> Practical code examples for automating and integrating with WALLIX Bastion.

---

## Quick Start

### Terraform

```bash
cd terraform
export TF_VAR_bastion_host="bastion.example.com"
export TF_VAR_bastion_user="admin"
export TF_VAR_bastion_token="your-api-key"
terraform init && terraform plan
```

### Python

```bash
cd api/python
pip install requests
export BASTION_HOST="bastion.example.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
python list_devices.py
```

### curl

```bash
cd api/curl
export BASTION_HOST="bastion.example.com"
export BASTION_USER="admin"
export BASTION_API_KEY="your-api-key"
./get_status.sh
```

---

## Contents

```
examples/
├── terraform/
│   ├── provider.tf              # Provider configuration
│   └── resources/device.tf      # Device examples
└── api/
    ├── python/
    │   ├── bastion_client.py    # Reusable API client
    │   └── list_devices.py      # Device listing
    └── curl/
        ├── get_status.sh        # Status check
        └── list_devices.sh      # Device listing
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| WALLIX Bastion | 12.x | Target system |
| Terraform | 1.0+ | IaC |
| Python | 3.8+ | API scripts |
| API Key | - | Authentication |

---

## Compatibility

| Provider Version | API Version | Terraform |
|------------------|-------------|-----------|
| 0.14.x | v3.12 | >= 1.0 |
| 0.13.x | v3.6 | >= 0.14 |

---

## Resources

| Resource | Link |
|----------|------|
| Terraform Registry | https://registry.terraform.io/providers/wallix/wallix-bastion |
| Provider GitHub | https://github.com/wallix/terraform-provider-wallix-bastion |
| API Samples | https://github.com/wallix/wbrest_samples |
| SCIM API | https://scim.wallix.com/scim/doc/Usage.html |

---

<p align="center">
  <a href="./terraform/README.md">Terraform</a> •
  <a href="./api/README.md">API</a>
</p>
