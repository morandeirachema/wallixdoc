# WALLIX Bastion Examples

This directory contains practical code examples for automating and integrating with WALLIX Bastion.

## Directory Structure

```
examples/
├── terraform/          # Infrastructure as Code examples
│   ├── README.md       # Terraform provider setup guide
│   ├── provider.tf     # Provider configuration
│   └── resources/      # Resource examples
└── api/                # REST API examples
    ├── README.md       # API usage guide
    ├── python/         # Python scripts
    └── curl/           # curl command examples
```

## Prerequisites

- WALLIX Bastion 12.x installed and configured
- API access enabled with valid API key
- For Terraform: Terraform 1.0+ installed
- For Python: Python 3.8+ with `requests` library

## Quick Start

### Terraform

```bash
cd terraform
terraform init
terraform plan
```

### Python API

```bash
cd api/python
pip install requests
python list_devices.py
```

### curl Examples

```bash
cd api/curl
./get_status.sh
```

## Official Resources

- [Terraform Provider Registry](https://registry.terraform.io/providers/wallix/wallix-bastion)
- [Terraform Provider GitHub](https://github.com/wallix/terraform-provider-wallix-bastion)
- [REST API Samples (Official)](https://github.com/wallix/wbrest_samples)
- [SCIM API Documentation](https://scim.wallix.com/scim/doc/Usage.html)

## Version Compatibility

| Terraform Provider | WALLIX Bastion API | Terraform Version |
|-------------------|--------------------|--------------------|
| 0.14.x | v3.12 | >= 1.0 |
| 0.13.x | v3.3, v3.6 | >= 0.14 |

---

See individual directories for detailed documentation and examples.
