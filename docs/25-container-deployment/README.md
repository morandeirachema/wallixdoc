# 25 - Container Deployment

> **Note**: This deployment model is **not recommended** for production OT/Industrial environments. For production deployments, use bare metal or virtual machines as described in the [Deployment Options](../24-cloud-deployment/README.md) guide.

---

## Recommendation

For WALLIX Bastion deployments, **on-premises bare metal or VMs are recommended** because:

1. **Security**: Full control over infrastructure isolation
2. **Compliance**: Meets IEC 62443 and OT security requirements
3. **Performance**: Dedicated resources for session recording
4. **Support**: Official WALLIX support for standard deployments
5. **Air-Gap**: Supports disconnected/isolated environments

---

## Official Documentation

For supported deployment options, refer to the official WALLIX documentation:

| Document | URL |
|----------|-----|
| **Deployment Guide** | [bastion_12.0.2_en_deployment_guide.pdf](https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf) |
| **Administration Guide** | [bastion_en_administration_guide.pdf](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf) |
| **Documentation Portal** | [pam.wallix.one](https://pam.wallix.one/documentation) |

---

## Recommended Alternatives

### Virtual Machine Deployment

For virtualized environments, deploy WALLIX Bastion on standard VMs:

- VMware vSphere / ESXi
- Microsoft Hyper-V
- Proxmox VE
- KVM / QEMU

See [Pre-Production Lab](../../pre/README.md) for VM-based deployment examples.

### Hardware Appliance

WALLIX offers pre-configured hardware appliances with:

- Optimized hardware and software configuration
- Simplified deployment
- Enterprise support

Contact WALLIX Sales for appliance options.

---

## API and Automation

For infrastructure automation with WALLIX Bastion:

| Resource | URL | Description |
|----------|-----|-------------|
| **Terraform Provider** | [registry.terraform.io](https://registry.terraform.io/providers/wallix/wallix-bastion) | Infrastructure as Code |
| **REST API Samples** | [github.com/wallix](https://github.com/wallix/wbrest_samples) | Python examples |
| **Automation Showroom** | [github.com/wallix](https://github.com/wallix/Automation_Showroom) | Multi-tool examples |

---

## Related Documentation

| Guide | Description |
|-------|-------------|
| [Deployment Options](../24-cloud-deployment/README.md) | On-premises deployment |
| [Installation Guide](../../install/README.md) | Multi-site deployment |
| [Pre-Production Lab](../../pre/README.md) | VM-based test environment |
| [System Requirements](../28-system-requirements/README.md) | Hardware specifications |

---

## Support

- **Support Portal**: https://support.wallix.com
- **Documentation**: https://pam.wallix.one/documentation

---

*For production deployments, use bare metal or virtual machines with the official WALLIX documentation.*
