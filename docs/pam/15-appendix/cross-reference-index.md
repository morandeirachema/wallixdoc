# Cross-Reference Index

## Quick Topic Navigation for WALLIX Bastion Documentation

This index provides rapid access to topics across all 47 documentation sections. Use this when you need to find specific information quickly without browsing the full table of contents.

---

## How to Use This Index

1. Locate your topic in one of the category tables below
2. Note the section number (00-46)
3. Click the link to jump directly to the relevant documentation
4. Use your browser's search (Ctrl+F / Cmd+F) to find specific keywords within sections

**Tip**: Most topics appear in multiple sections. Primary reference is listed first, with related sections below.

---

## Table of Contents

- [Authentication Topics](#authentication-topics)
- [API and Automation Topics](#api-and-automation-topics)
- [Networking Topics](#networking-topics)
- [High Availability Topics](#high-availability-topics)
- [Troubleshooting Topics](#troubleshooting-topics)
- [Compliance and Audit Topics](#compliance-and-audit-topics)
- [Session Management Topics](#session-management-topics)
- [Password and Credential Topics](#password-and-credential-topics)
- [Infrastructure and Deployment Topics](#infrastructure-and-deployment-topics)
- [Advanced Features Topics](#advanced-features-topics)

---

## Authentication Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **MFA / Multi-Factor Authentication** | 06 | [Authentication](../06-authentication/README.md) | FortiToken, RADIUS, SMS, push notifications |
| **FortiAuthenticator MFA** | 46 | [Fortigate Integration](../46-fortigate-integration/README.md) | FortiAuthenticator RADIUS integration with FortiToken |
| **LDAP Integration** | 06, 34 | [Authentication](../06-authentication/README.md), [LDAP/AD](../34-ldap-ad-integration/README.md) | Active Directory, LDAP sync, group mapping |
| **Active Directory** | 34 | [LDAP/AD Integration](../34-ldap-ad-integration/README.md) | AD domain integration, user sync, nested groups |
| **Kerberos SSO** | 06, 35 | [Authentication](../06-authentication/README.md), [Kerberos](../35-kerberos-authentication/README.md) | Kerberos, SPNEGO, keytab management, cross-realm |
| **RADIUS Authentication** | 06 | [Authentication](../06-authentication/README.md) | RADIUS primary authentication and MFA |
| **SAML Federation** | 06 | [Authentication](../06-authentication/README.md) | SAML 2.0 SSO with external IdP |
| **OIDC / OpenID Connect** | 06 | [Authentication](../06-authentication/README.md) | OpenID Connect SSO (new in 12.x) |
| **Certificate-Based Auth** | 06, 28 | [Authentication](../06-authentication/README.md), [Certificates](../28-certificate-management/README.md) | X.509 client certificates, mutual TLS |
| **Local Authentication** | 06 | [Authentication](../06-authentication/README.md) | Local database users, password policies |
| **Authentication Chaining** | 06 | [Authentication](../06-authentication/README.md) | Multiple auth methods in sequence |
| **Password Policies** | 06, 08 | [Authentication](../06-authentication/README.md), [Password Management](../08-password-management/README.md) | Complexity, expiry, lockout policies |

---

## API and Automation Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **REST API Reference** | 17 | [API Reference](../17-api-reference/README.md) | Complete REST API v3.12 documentation |
| **wabadmin CLI** | 31 | [wabadmin Reference](../31-wabadmin-reference/README.md) | Complete CLI command reference with examples |
| **API Authentication** | 17 | [API Reference](../17-api-reference/README.md) | API key generation, OAuth2, token management |
| **SCIM API** | 00, 17 | [Official Resources](../00-official-resources/README.md), [API Reference](../17-api-reference/README.md) | User provisioning via SCIM protocol |
| **Terraform Provider** | 00, 10 | [Official Resources](../00-official-resources/README.md), [API & Automation](../10-api-automation/README.md) | Infrastructure as Code with Terraform |
| **Ansible Automation** | 10 | [API & Automation](../10-api-automation/README.md) | Ansible playbooks for configuration management |
| **Python SDK** | 10, 17 | [API & Automation](../10-api-automation/README.md), [API Reference](../17-api-reference/README.md) | Python client examples and patterns |
| **Bulk Import/Export** | 10, 40 | [API & Automation](../10-api-automation/README.md), [Account Discovery](../40-account-discovery/README.md) | CSV import, API bulk operations |
| **DevOps Integration** | 10 | [API & Automation](../10-api-automation/README.md) | CI/CD pipelines, GitOps workflows |
| **Webhook Integration** | 10 | [API & Automation](../10-api-automation/README.md) | External system notifications |
| **Task Automation** | 45 | [Privileged Task Automation](../45-privileged-task-automation/README.md) | Automated privileged operations, runbooks |

---

## Networking Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Port Reference** | 36 | [Network Configuration](../36-network-validation/README.md) | Complete port matrix for all protocols |
| **Firewall Rules** | 36, 46 | [Network Configuration](../36-network-validation/README.md), [Fortigate](../46-fortigate-integration/README.md) | Required firewall policies and ACLs |
| **Fortigate Integration** | 46 | [Fortigate Integration](../46-fortigate-integration/README.md) | Fortigate firewall placement, SSL VPN, routing |
| **HAProxy Configuration** | 32 | [Load Balancer](../32-load-balancer/README.md) | HAProxy setup, health checks, SSL termination |
| **Load Balancing** | 32 | [Load Balancer](../32-load-balancer/README.md) | HAProxy, Nginx, F5, Keepalived VRRP |
| **DNS Configuration** | 36 | [Network Configuration](../36-network-validation/README.md) | DNS requirements, forward/reverse lookup |
| **NTP Time Sync** | 36 | [Network Configuration](../36-network-validation/README.md) | NTP configuration, time synchronization |
| **VPN Integration** | 46 | [Fortigate Integration](../46-fortigate-integration/README.md) | SSL VPN, IPsec VPN with Fortigate |
| **Network Validation** | 36 | [Network Configuration](../36-network-validation/README.md) | Connectivity testing, bandwidth validation |
| **MTU Configuration** | 36 | [Network Configuration](../36-network-validation/README.md) | Jumbo frames, fragmentation handling |
| **Network Architecture** | 03, 36 | [Architecture](../03-architecture/README.md), [Network Config](../36-network-validation/README.md) | Multi-site topology, network diagrams |
| **SSL/TLS Termination** | 32, 28 | [Load Balancer](../32-load-balancer/README.md), [Certificates](../28-certificate-management/README.md) | SSL offloading at HAProxy |

---

## High Availability Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **HA Clustering** | 11 | [High Availability](../11-high-availability/README.md) | Pacemaker/Corosync active-active clustering |
| **MariaDB Replication** | 11 | [High Availability](../11-high-availability/README.md) | Database replication, stream replication |
| **Failover Configuration** | 11 | [High Availability](../11-high-availability/README.md) | Automatic failover, VIP management |
| **Disaster Recovery** | 29 | [Disaster Recovery](../29-disaster-recovery/README.md) | DR runbooks, RTO/RPO planning, PITR |
| **Backup and Restore** | 30 | [Backup and Restore](../30-backup-restore/README.md) | Full/selective backup, disaster recovery |
| **Multi-Site Replication** | 11 | [High Availability](../11-high-availability/README.md) | Cross-site synchronization |
| **Split-Brain Prevention** | 11 | [High Availability](../11-high-availability/README.md) | Fencing, quorum management |
| **Health Checks** | 32 | [Load Balancer](../32-load-balancer/README.md) | HAProxy health monitoring |
| **Cluster Status** | 11, 31 | [High Availability](../11-high-availability/README.md), [wabadmin](../31-wabadmin-reference/README.md) | Monitoring cluster health with crm_mon |
| **Upgrade Procedures** | 20 | [Upgrade Guide](../20-upgrade-guide/README.md) | Rolling upgrades for HA clusters |

---

## Troubleshooting Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Error Reference** | 18 | [Error Reference](../18-error-reference/README.md) | Complete error code catalog with remediation |
| **Log Analysis** | 13 | [Troubleshooting](../13-troubleshooting/README.md) | Log locations, grep patterns, log levels |
| **Diagnostics** | 13 | [Troubleshooting](../13-troubleshooting/README.md) | System diagnostics, health checks |
| **Common Issues** | 22 | [FAQ & Known Issues](../22-faq-known-issues/README.md) | FAQ, known bugs, workarounds |
| **Password Rotation Failures** | 33 | [Password Rotation Troubleshooting](../33-password-rotation-troubleshooting/README.md) | Debug rotation issues, SSH key problems |
| **Connection Failures** | 13, 36 | [Troubleshooting](../13-troubleshooting/README.md), [Network Config](../36-network-validation/README.md) | Network connectivity debugging |
| **Authentication Failures** | 13, 06 | [Troubleshooting](../13-troubleshooting/README.md), [Authentication](../06-authentication/README.md) | Debug MFA, LDAP, Kerberos issues |
| **Performance Issues** | 13, 26 | [Troubleshooting](../13-troubleshooting/README.md), [Performance](../26-performance-benchmarks/README.md) | Slow sessions, database performance |
| **Database Issues** | 13, 11 | [Troubleshooting](../13-troubleshooting/README.md), [High Availability](../11-high-availability/README.md) | MariaDB replication lag, corruption |
| **Certificate Errors** | 28 | [Certificate Management](../28-certificate-management/README.md) | SSL/TLS certificate troubleshooting |
| **Cluster Issues** | 11, 13 | [High Availability](../11-high-availability/README.md), [Troubleshooting](../13-troubleshooting/README.md) | Split-brain, node failures |
| **Fortigate Integration Issues** | 46 | [Fortigate Integration](../46-fortigate-integration/README.md) | VPN, MFA, routing problems |

---

## Compliance and Audit Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Compliance Frameworks** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR, NIS2 |
| **SOC 2 Type II** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | SOC 2 control mapping and evidence |
| **ISO 27001** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | ISO 27001 control alignment |
| **NIS2 Directive** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | EU NIS2 compliance requirements |
| **PCI-DSS** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | Payment Card Industry requirements |
| **HIPAA** | 24 | [Compliance & Audit](../24-compliance-audit/README.md) | Healthcare data protection |
| **Audit Logs** | 09, 24 | [Session Management](../09-session-management/README.md), [Compliance](../24-compliance-audit/README.md) | Comprehensive audit trail logging |
| **Evidence Collection** | 37 | [Compliance Evidence](../37-compliance-evidence/README.md) | Automated evidence gathering for audits |
| **Session Recording** | 09, 39 | [Session Management](../09-session-management/README.md), [Playback](../39-session-recording-playback/README.md) | Video recording, OCR, keystroke logging |
| **Approval Workflows** | 07, 25 | [Authorization](../07-authorization/README.md), [JIT Access](../25-jit-access/README.md) | Multi-tier approvals, ticketing integration |
| **Access Reviews** | 07 | [Authorization](../07-authorization/README.md) | Periodic access certification |
| **Incident Response** | 23 | [Incident Response](../23-incident-response/README.md) | Security incident playbooks, forensics |

---

## Session Management Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Session Recording** | 09 | [Session Management](../09-session-management/README.md) | Video recording, OCR search, metadata |
| **Session Playback** | 39 | [Session Recording Playback](../39-session-recording-playback/README.md) | Playback interface, OCR search, export |
| **Live Session Monitoring** | 09 | [Session Management](../09-session-management/README.md) | Real-time session watching, alerts |
| **Session Sharing** | 43 | [Session Sharing](../43-session-sharing/README.md) | Multi-user sessions, collaboration, training |
| **Session Termination** | 09 | [Session Management](../09-session-management/README.md) | Admin kill sessions, automatic timeouts |
| **Protocol Support** | 04, 09 | [Core Components](../04-core-components/README.md), [Sessions](../09-session-management/README.md) | SSH, RDP, VNC, HTTP, WinRM, Telnet |
| **RDP Session Manager** | 04 | [Core Components](../04-core-components/README.md) | WALLIX RDS for Windows sessions |
| **OCR Search** | 39 | [Session Recording Playback](../39-session-recording-playback/README.md) | Full-text search in recorded sessions |
| **Keystroke Logging** | 09 | [Session Management](../09-session-management/README.md) | Command and keystroke capture |
| **Session Metadata** | 09 | [Session Management](../09-session-management/README.md) | Timestamps, users, targets, protocols |
| **Command Filtering** | 38 | [Command Filtering](../38-command-filtering/README.md) | Command whitelist/blacklist, blocking |

---

## Password and Credential Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Password Vault** | 08 | [Password Management](../08-password-management/README.md) | Encrypted credential storage, AES-256 |
| **Password Rotation** | 08 | [Password Management](../08-password-management/README.md) | Automatic password rotation schedules |
| **Password Rotation Troubleshooting** | 33 | [Password Rotation Troubleshooting](../33-password-rotation-troubleshooting/README.md) | Debug rotation failures |
| **Credential Checkout** | 08, 44 | [Password Management](../08-password-management/README.md), [Self-Service](../44-user-self-service/README.md) | Temporary credential access |
| **SSH Key Management** | 41 | [SSH Key Lifecycle](../41-ssh-key-lifecycle/README.md) | SSH key generation, rotation, CA |
| **Service Account Management** | 42 | [Service Account Lifecycle](../42-service-account-lifecycle/README.md) | Service account governance, rotation |
| **Encryption** | 08, 28 | [Password Management](../08-password-management/README.md), [Certificates](../28-certificate-management/README.md) | AES-256-GCM, Argon2ID, TLS 1.3 |
| **HSM Integration** | 28 | [Certificate Management](../28-certificate-management/README.md) | Hardware security module for keys |
| **Password Policies** | 08 | [Password Management](../08-password-management/README.md) | Complexity, length, expiry requirements |
| **Credential Discovery** | 40 | [Account Discovery](../40-account-discovery/README.md) | Scan for orphaned accounts and credentials |
| **Privileged Account Discovery** | 40 | [Account Discovery](../40-account-discovery/README.md) | Discover privileged accounts on targets |

---

## Infrastructure and Deployment Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Architecture Overview** | 03 | [Architecture](../03-architecture/README.md) | Deployment models, component architecture |
| **System Requirements** | 19 | [System Requirements](../19-system-requirements/README.md) | Hardware sizing, CPU, memory, storage |
| **Installation Guide** | 01 | [Quick Start](../01-quick-start/README.md) | Initial installation and configuration |
| **Multi-Site Deployment** | 03, 11 | [Architecture](../03-architecture/README.md), [High Availability](../11-high-availability/README.md) | 4-site synchronized architecture |
| **On-Premises Deployment** | 16 | [Deployment Options](../16-cloud-deployment/README.md) | Bare metal and VM deployment patterns |
| **Capacity Planning** | 26 | [Performance Benchmarks](../26-performance-benchmarks/README.md) | Sizing, session capacity, load testing |
| **Performance Tuning** | 19, 26 | [System Requirements](../19-system-requirements/README.md), [Performance](../26-performance-benchmarks/README.md) | Database tuning, kernel parameters |
| **Security Hardening** | 14 | [Best Practices](../14-best-practices/README.md) | OS hardening, LUKS encryption, firewall |
| **Debian Installation** | 01 | [Quick Start](../01-quick-start/README.md) | Debian 12 base OS with LUKS encryption |
| **Vendor Integration** | 27 | [Vendor Integration](../27-vendor-integration/README.md) | Cisco, Microsoft, Red Hat integrations |
| **Upgrade Procedures** | 20 | [Upgrade Guide](../20-upgrade-guide/README.md) | Version upgrades, HA upgrade paths |
| **Operational Runbooks** | 21 | [Operational Runbooks](../21-operational-runbooks/README.md) | Daily, weekly, monthly procedures |

---

## Advanced Features Topics

| Topic | Section | Link | Description |
|-------|---------|------|-------------|
| **Just-In-Time Access** | 25 | [JIT Access](../25-jit-access/README.md) | Time-bounded access, temporary elevation |
| **Approval Workflows** | 07, 25 | [Authorization](../07-authorization/README.md), [JIT Access](../25-jit-access/README.md) | Multi-tier approvals, ticketing integration |
| **RBAC / Role-Based Access** | 07 | [Authorization](../07-authorization/README.md) | Role hierarchies, permission matrices |
| **Account Discovery** | 40 | [Account Discovery](../40-account-discovery/README.md) | Automated account scanning, bulk import |
| **Privileged Task Automation** | 45 | [Privileged Task Automation](../45-privileged-task-automation/README.md) | Automated privileged operations |
| **User Self-Service Portal** | 44 | [User Self-Service](../44-user-self-service/README.md) | Password checkout, MFA enrollment |
| **Command Filtering** | 38 | [Command Filtering](../38-command-filtering/README.md) | Command restrictions, whitelist/blacklist |
| **Session Collaboration** | 43 | [Session Sharing](../43-session-sharing/README.md) | Multi-user sessions, dual-control |
| **Monitoring & Observability** | 12 | [Monitoring & Observability](../12-monitoring-observability/README.md) | Prometheus, Grafana, alerting |
| **SIEM Integration** | 12 | [Monitoring & Observability](../12-monitoring-observability/README.md) | Syslog forwarding to SIEM platforms |
| **Certificate Management** | 28 | [Certificate Management](../28-certificate-management/README.md) | TLS/SSL, CSR, renewal, Let's Encrypt |
| **Access Manager** | 04 | [Core Components](../04-core-components/README.md) | Web application password insertion |

---

## Related Resources

### Installation Guides
- [Installation HOWTO](../../../install/HOWTO.md) - Complete multi-site installation walkthrough
- [Architecture Diagrams](../../../install/09-architecture-diagrams.md) - Network diagrams and port reference
- [Pre-Production Lab Setup](../../../pre/README.md) - Lab environment configuration

### Automation Examples
- [Ansible Playbooks](../../../examples/ansible/README.md) - Configuration automation
- [Terraform Examples](../../../examples/terraform/README.md) - Infrastructure as Code
- [API Examples](../../../examples/api/README.md) - REST API usage patterns

### Official WALLIX Resources
- [Official Resources Section](../00-official-resources/README.md) - Links to WALLIX documentation portal, PDFs, GitHub repos

---

## Quick Command Reference

```bash
# Check system status
wabadmin status
systemctl status wallix-bastion

# View recent audit logs
wabadmin audit --last 50

# Check HA cluster health
crm status
crm_mon -1

# Database replication status
mysql -e "SHOW SLAVE STATUS\G"

# View license information
wabadmin license-info

# Network connectivity test
wabadmin network-test

# Generate diagnostic bundle
wabadmin diagnostics-bundle
```

---

## Version Information

| Item | Version |
|------|---------|
| Documentation Version | 8.0 |
| WALLIX Bastion | 12.1.x |
| API Version | v3.12 |
| Last Updated | February 2026 |

---

**Navigation**: [Back to Appendix](README.md) | [Back to Documentation Index](../../README.md)
