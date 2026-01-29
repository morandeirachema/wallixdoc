# Official WALLIX Resources

This document provides curated links to official WALLIX documentation, tools, and resources for WALLIX Bastion 12.x.

---

## Documentation Portal

| Resource | URL | Description |
|----------|-----|-------------|
| **WALLIX One PAM Portal** | https://pam.wallix.one/documentation | Main documentation portal |
| **Getting Started** | https://pam.wallix.one/documentation/user/getting-started/documentation.html | Quick start guides |
| **Architecture Guide** | https://pam.wallix.one/documentation/deployment/getting-started/architecture.html | Deployment architecture |

---

## Official PDF Documentation

### WALLIX Bastion 12.x

| Document | URL | Last Updated |
|----------|-----|--------------|
| **User Guide** | [bastion_en_user_guide.pdf](https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf) | 2025 |
| **Administration Guide** | [bastion_en_administration_guide.pdf](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf) | 2025 |
| **Deployment Guide (12.0.2)** | [bastion_12.0.2_en_deployment_guide.pdf](https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf) | 2024 |

### WALLIX Access Manager

| Document | URL | Version |
|----------|-----|---------|
| **Admin Guide** | [am-admin-guide_en.pdf](https://pam.wallix.one/documentation/admin-doc/am-admin-guide_en.pdf) | 5.2.1.3 |
| **Installation Guide** | [am-install_en.pdf](https://marketplace-wallix.s3.amazonaws.com/am-install_en.pdf) | 4.0.6.1 |

### Release Notes

| Version | URL |
|---------|-----|
| **Bastion 12.1.1** | [bastion-rn-en.html](https://pam.wallix.one/documentation/release-notes/1.5.1/bastion-rn-en.html) |
| **Access Manager 1.5.1** | [am-rn-en.html](https://pam.wallix.one/documentation/release-notes/1.5.1/am-rn-en.html) |

---

## API Documentation

| Resource | URL | Description |
|----------|-----|-------------|
| **SCIM API 2.0** | https://scim.wallix.com/scim/doc/Usage.html | User provisioning API |
| **REST API Samples** | https://github.com/wallix/wbrest_samples | Python examples (official) |

### API Version Compatibility

| API Version | WALLIX Bastion | Status |
|-------------|----------------|--------|
| v3.12 | 12.x | Current |
| v3.6 | 11.x | Supported |
| v3.3 | 10.x | Legacy |
| v2.x | < 10.x | Deprecated |

---

## Automation & Infrastructure as Code

### Terraform Provider

| Resource | URL |
|----------|-----|
| **Terraform Registry** | https://registry.terraform.io/providers/wallix/wallix-bastion |
| **GitHub Repository** | https://github.com/wallix/terraform-provider-wallix-bastion |
| **Provider Documentation** | https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs |

**Current Version:** 0.14.0 (supports API v3.12)

### WAAPM (Application-to-Application)

| Resource | URL |
|----------|-----|
| **Terraform Provider** | https://github.com/wallix/terraform-provider-waapm |

### Automation Showroom

| Resource | URL | Description |
|----------|-----|-------------|
| **Automation Examples** | https://github.com/wallix/Automation_Showroom | Terraform, Python, Ansible examples |

---

## GitHub Repositories

| Repository | URL | Description |
|------------|-----|-------------|
| **WALLIX Organization** | https://github.com/wallix | All official repositories |
| **Terraform Provider** | https://github.com/wallix/terraform-provider-wallix-bastion | IaC provider |
| **REST API Samples** | https://github.com/wallix/wbrest_samples | Python API examples |
| **WAAPM Provider** | https://github.com/wallix/terraform-provider-waapm | A2A password management |
| **Automation Showroom** | https://github.com/wallix/Automation_Showroom | Automation examples |

---

## Monitoring & Observability

| Tool | URL | Description |
|------|-----|-------------|
| **Prometheus Exporter** | https://github.com/claranet/wallix_bastion_exporter | Community exporter by Claranet |

---

## Integrations

### Security Platforms

| Integration | URL | Description |
|-------------|-----|-------------|
| **Tenable** | https://docs.tenable.com/integrations/WALLIX/Bastion/Content/Introduction.htm | Vulnerability scanning |
| **Cortex XSOAR** | https://xsoar.pan.dev/docs/reference/integrations/wallix-bastion | SOAR integration |
| **Rudder** | https://docs.rudder.io/reference/7.0/plugins/wallix.html | Configuration management |

### Identity Providers

| Integration | URL | Description |
|-------------|-----|-------------|
| **Trustelem (SSO)** | https://trustelem-doc.wallix.com/books/trustelem-applications/page/wallix-access-manager | WALLIX SSO |

---

## Support & Community

| Resource | URL |
|----------|-----|
| **Support Portal** | https://support.wallix.com |
| **WALLIX Website** | https://www.wallix.com |
| **Product Page** | https://www.wallix.com/products/privileged-access-management/ |

---

## Best Practices Articles

| Topic | URL |
|-------|-----|
| **PAM Best Practices** | https://www.wallix.com/blogpost/privileged-access-management-best-practices/ |
| **IAM Guide for Leaders** | https://www.wallix.com/blogpost/conquer-identity-and-access-management-guide/ |
| **Access Manager Overview** | https://www.wallix.com/blogpost/access-management-platform-wallix-access-manager-2/ |
| **Deployment Options** | https://blog.wallix.com/privileged-account-management-deployment-options |

---

## Version Compatibility Matrix

| Component | Version | Notes |
|-----------|---------|-------|
| WALLIX Bastion | 12.1.x | Current release |
| Operating System | Debian 12 (Bookworm) | Required for new installs |
| Database | PostgreSQL 15+ | Required |
| Terraform Provider | 0.14.x | API v3.12 support |
| Access Manager | 5.2.x | Compatible |

---

## Quick Links by Role

### For Administrators
1. [Administration Guide (PDF)](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
2. [Deployment Guide](https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf)
3. [Release Notes](https://pam.wallix.one/documentation/release-notes/1.5.1/bastion-rn-en.html)

### For End Users
1. [User Guide (PDF)](https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf)
2. [Getting Started](https://pam.wallix.one/documentation/user/getting-started/documentation.html)

### For Developers/DevOps
1. [Terraform Provider](https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs)
2. [REST API Samples](https://github.com/wallix/wbrest_samples)
3. [SCIM API](https://scim.wallix.com/scim/doc/Usage.html)

---

## Next Steps

- [Quick Start Guide](../00-quick-start/README.md) - Get started with PAM4OT
- [Introduction](../01-introduction/README.md) - Learn about WALLIX PAM

---

*Last Updated: January 2026*
