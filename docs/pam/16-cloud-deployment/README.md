# 24 - Deployment Options

> **Note**: This documentation focuses on **on-premises deployment**. For cloud-specific guidance, refer to the official WALLIX documentation linked below.

---

## Official WALLIX Documentation

For authoritative deployment guidance, always refer to the official WALLIX documentation:

### Primary Resources

| Document | URL | Description |
|----------|-----|-------------|
| **Deployment Guide** | [bastion_12.0.2_en_deployment_guide.pdf](https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf) | Official deployment procedures |
| **Administration Guide** | [bastion_en_administration_guide.pdf](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf) | Complete administration reference |
| **Architecture Guide** | [architecture.html](https://pam.wallix.one/documentation/deployment/getting-started/architecture.html) | Deployment architecture patterns |
| **Documentation Portal** | [pam.wallix.one](https://pam.wallix.one/documentation) | All official documentation |

### Automation Resources

| Resource | URL | Description |
|----------|-----|-------------|
| **Terraform Provider** | [registry.terraform.io](https://registry.terraform.io/providers/wallix/wallix-bastion) | Infrastructure as Code |
| **Terraform GitHub** | [github.com/wallix](https://github.com/wallix/terraform-provider-wallix-bastion) | Source and examples |
| **Automation Showroom** | [github.com/wallix](https://github.com/wallix/Automation_Showroom) | Terraform, Python, Ansible examples |
| **REST API Samples** | [github.com/wallix](https://github.com/wallix/wbrest_samples) | API integration examples |

---

## Deployment Overview

### Supported Deployment Models

```
+===============================================================================+
|                   WALLIX BASTION DEPLOYMENT OPTIONS                           |
+===============================================================================+

  RECOMMENDED: ON-PREMISES DEPLOYMENT
  ====================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 1: BARE METAL / VIRTUAL MACHINES (Recommended)                  |
  | =====================================================                  |
  |                                                                        |
  |   * Full control over infrastructure                                   |
  |   * Maximum security and compliance                                    |
  |   * Suitable for OT/Industrial environments                            |
  |   * Air-gapped deployment support                                      |
  |                                                                        |
  |   Supported Hypervisors:                                               |
  |   - VMware vSphere / ESXi                                              |
  |   - Microsoft Hyper-V                                                  |
  |   - Proxmox VE                                                         |
  |   - KVM / QEMU                                                         |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 2: HARDWARE APPLIANCE                                           |
  | ============================                                           |
  |                                                                        |
  |   * Pre-configured WALLIX appliance                                    |
  |   * Optimized hardware and software                                    |
  |   * Simplified deployment                                              |
  |   * Enterprise support                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## On-Premises Architecture

### High Availability Configuration

```
+===============================================================================+
|                   ON-PREMISES HA ARCHITECTURE                                 |
+===============================================================================+
|                                                                               |
|                           USERS / OPERATORS                                   |
|                                  |                                            |
|                                  v                                            |
|                      +---------------------+                                  |
|                      |      HAProxy        |                                  |
|                      |    Load Balancer    |                                  |
|                      |   (Active/Standby)  |                                  |
|                      +---------------------+                                  |
|                           |           |                                       |
|                     +-----+           +-----+                                 |
|                     |                       |                                 |
|                     v                       v                                 |
|            +----------------+      +----------------+                         |
|            |   WALLIX       |      |   WALLIX       |                         |
|            |   Bastion      |<---->|   Bastion      |                         |
|            |   Node 1       | Sync |   Node 2       |                         |
|            +----------------+      +----------------+                         |
|                     |                       |                                 |
|                     +-----+           +-----+                                 |
|                           |           |                                       |
|                           v           v                                       |
|                      +---------------------+                                  |
|                      |      MariaDB        |                                  |
|                      |    Replication      |                                  |
|                      |   (Master/Master)   |                                  |
|                      +---------------------+                                  |
|                                                                               |
|   PORTS:                                                                      |
|   - 443:       HTTPS Web UI                                                   |
|   - 22:        SSH Proxy                                                      |
|   - 3389:      RDP Proxy                                                      |
|   - 3306/3307: MariaDB Replication                                            |
|   - 5404-5406: Corosync Cluster                                               |
|                                                                               |
+===============================================================================+
```

### Multi-Site Architecture

For multi-site deployments, refer to:
- [install/README.md](../../install/README.md) - Multi-site architecture overview
- [install/HOWTO.md](../../install/HOWTO.md) - Step-by-step deployment guide

---

## System Requirements

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 vCPU | 8+ vCPU |
| **RAM** | 16 GB | 32 GB |
| **Storage (OS)** | 50 GB SSD | 100 GB SSD |
| **Storage (Data)** | 150 GB SSD | 500+ GB SSD |
| **Network** | 1 Gbps | 10 Gbps |

### Software Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **Operating System** | Debian 12 (Bookworm) | Required |
| **Database** | MariaDB 10.5+ | Included |
| **Clustering** | Pacemaker/Corosync | For HA |
| **Load Balancer** | HAProxy 2.x | Recommended |

For detailed requirements, see [28-system-requirements/README.md](../19-system-requirements/README.md).

---

## Infrastructure as Code

### Terraform Provider

WALLIX provides an official Terraform provider for automation:

```hcl
# Example: Configure WALLIX Bastion provider
terraform {
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.14.0"
    }
  }
}

provider "wallix-bastion" {
  ip        = var.bastion_ip
  user      = var.bastion_user
  password  = var.bastion_password
  api_version = "v3.12"
}

# See official documentation for resource examples:
# https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs
```

### Official Terraform Resources

| Resource | URL |
|----------|-----|
| Provider Documentation | https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs |
| GitHub Repository | https://github.com/wallix/terraform-provider-wallix-bastion |
| Example Configurations | https://github.com/wallix/Automation_Showroom |

---

## API Integration

### REST API

WALLIX Bastion provides a comprehensive REST API for automation:

```bash
# Example: List devices via API
curl -k -X GET \
  "https://bastion.example.com/api/devices" \
  -H "Authorization: Basic $(echo -n 'admin:password' | base64)" \
  -H "Content-Type: application/json"
```

### API Resources

| Resource | URL |
|----------|-----|
| REST API Samples | https://github.com/wallix/wbrest_samples |
| SCIM API (Provisioning) | https://scim.wallix.com/scim/doc/Usage.html |

---

## Related Documentation

### Internal Guides

| Guide | Description |
|-------|-------------|
| [Installation Guide](../../install/README.md) | Multi-site deployment |
| [HA Configuration](../11-high-availability/README.md) | Clustering setup |
| [System Requirements](../19-system-requirements/README.md) | Hardware/software specs |
| [Pre-Production Lab](../../pre/README.md) | Test environment setup |

### Official WALLIX Resources

| Resource | URL |
|----------|-----|
| Documentation Portal | https://pam.wallix.one/documentation |
| Support Portal | https://support.wallix.com |
| Release Notes | https://pam.wallix.one/documentation/release-notes |

---

## Support

For deployment assistance, contact WALLIX Support:

- **Support Portal**: https://support.wallix.com
- **Documentation**: https://pam.wallix.one/documentation

---

## See Also

**Related Sections:**
- [19 - System Requirements](../19-system-requirements/README.md) - Hardware sizing and specifications
- [26 - Performance Benchmarks](../26-performance-benchmarks/README.md) - Capacity planning

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site deployment procedures

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

*For the most current deployment guidance, always refer to the official WALLIX documentation.*
