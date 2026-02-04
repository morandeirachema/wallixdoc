# CLAUDE.md - Repository Context for AI Assistants

This file provides context for AI assistants (Claude, Copilot, etc.) working with this repository.

## Repository Overview

| Property | Value |
|----------|-------|
| **Purpose** | WALLIX Bastion 12.x technical documentation |
| **Type** | Documentation repository (no source code) |
| **Focus** | Privileged Access Management (PAM) with Fortigate MFA |
| **Deployment** | On-premises only (bare metal and VMs, no cloud/SaaS) |
| **Version** | WALLIX Bastion 12.1.x |
| **Content** | 48 PAM documentation sections |

## Directory Structure

```
wallixdoc/
├── CLAUDE.md              # This file - AI assistant context
├── README.md              # Repository overview and navigation
│
├── docs/                  # Product documentation (48 sections)
│   ├── README.md          # Documentation index with learning paths
│   │
│   └── pam/               # PAM/WALLIX Core Documentation (48 sections)
│       │
│       │   # Getting Started (00-05)
│       ├── 00-official-resources/     # Official WALLIX documentation links
│       ├── 01-quick-start/            # Quick start guide and UI walkthrough
│       ├── 02-introduction/           # Company and product overview
│       ├── 03-architecture/           # System architecture, deployment models
│       ├── 04-core-components/        # Session Manager, Password Manager
│       ├── 05-configuration/          # Object model, domains, devices
│       │
│       │   # Authentication & Authorization (06-07)
│       ├── 06-authentication/         # MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML
│       ├── 07-authorization/          # RBAC, approval workflows, JIT access
│       │
│       │   # Credential & Session Management (08-09)
│       ├── 08-password-management/    # Credential vault, rotation, checkout
│       ├── 09-session-management/     # Recording, monitoring, audit trails
│       │
│       │   # API & Automation (10)
│       ├── 10-api-automation/         # REST API, DevOps integration
│       │
│       │   # Infrastructure & High Availability (11-14)
│       ├── 11-high-availability/      # Clustering, DR, failover
│       ├── 12-monitoring-observability/ # Prometheus, Grafana, alerting
│       ├── 13-troubleshooting/        # Diagnostics, log analysis
│       ├── 14-best-practices/         # Security hardening, operations
│       │
│       │   # Reference & Appendix (15-22)
│       ├── 15-appendix/               # Quick reference, glossary
│       ├── 16-cloud-deployment/       # On-premises deployment patterns
│       ├── 17-api-reference/          # REST API documentation
│       ├── 18-error-reference/        # Error codes and remediation
│       ├── 19-system-requirements/    # Hardware, sizing, performance
│       ├── 20-upgrade-guide/          # Version upgrades, HA clusters
│       ├── 21-operational-runbooks/   # Daily/weekly/monthly procedures
│       ├── 22-faq-known-issues/       # FAQ, known issues, compatibility
│       │
│       │   # Compliance & Incident Response (23-25)
│       ├── 23-incident-response/      # Security incident playbooks
│       ├── 24-compliance-audit/       # SOC2, ISO27001, PCI-DSS, HIPAA, GDPR
│       ├── 25-jit-access/             # Just-In-Time access, approvals
│       │
│       │   # Performance & Infrastructure (26-32)
│       ├── 26-performance-benchmarks/ # Capacity planning, load testing
│       ├── 27-vendor-integration/     # Cisco, Microsoft, Red Hat
│       ├── 28-certificate-management/ # TLS/SSL, CSR, renewal, Let's Encrypt
│       ├── 29-disaster-recovery/      # DR runbooks, RTO/RPO, PITR
│       ├── 30-backup-restore/         # Full/selective backup, disaster recovery
│       ├── 31-wabadmin-reference/     # Complete CLI command reference
│       ├── 32-load-balancer/          # HAProxy, Nginx, F5, health checks
│       │
│       │   # Advanced Authentication (33-40)
│       ├── 33-password-rotation-troubleshooting/ # Rotation failures
│       ├── 34-ldap-ad-integration/    # Active Directory integration
│       ├── 35-kerberos-authentication/ # Kerberos, SPNEGO, SSO
│       ├── 36-network-validation/     # Firewall rules, DNS, NTP
│       ├── 37-compliance-evidence/    # Evidence collection, attestation
│       ├── 38-command-filtering/      # Command whitelist/blacklist
│       ├── 39-session-recording-playback/ # Playback, OCR, forensics
│       │
│       │   # Advanced Features (40-48)
│       ├── 40-account-discovery/      # Discovery scanning, bulk import
│       ├── 41-ssh-key-lifecycle/      # SSH key management, rotation, CA
│       ├── 42-service-account-lifecycle/ # Service account governance
│       ├── 43-session-sharing/        # Multi-user sessions, dual-control
│       ├── 44-user-self-service/      # Self-service portal
│       ├── 45-privileged-task-automation/ # Automated privileged operations
│       ├── 46-fortigate-integration/  # Fortigate firewall and MFA integration
│       ├── 47-access-manager/         # WALLIX Access Manager setup and configuration
│       └── 48-licensing/              # Licensing models, HA licensing, activation
│
├── install/               # Multi-site installation guide
│   ├── README.md          # Architecture overview, 30-day timeline
│   ├── HOWTO.md           # Step-by-step guide
│   ├── 00-debian-luks-installation.md  # Base OS with disk encryption
│   ├── 01-prerequisites.md             # Pre-deployment checklist
│   ├── 02-site-a-primary.md            # Primary HA cluster (Active-Active)
│   ├── 03-site-b-secondary.md          # Secondary HA cluster (Active-Active)
│   ├── 05-multi-site-sync.md           # Cross-site replication
│   ├── 07-security-hardening.md        # Security configuration
│   ├── 08-validation-testing.md        # Testing and go-live
│   ├── 09-architecture-diagrams.md     # Visual diagrams and ports
│   └── 10-mariadb-replication.md  # Database HA
│
├── pre/                   # Pre-production lab environment
│   ├── README.md          # Lab overview and architecture
│   ├── 01-infrastructure-setup.md      # VMware vSphere/ESXi setup
│   ├── 02-active-directory-setup.md    # AD domain controller
│   ├── 03-haproxy-setup.md             # Load balancer configuration
│   ├── 04-fortiauthenticator-setup.md  # FortiAuthenticator MFA
│   ├── 05-wallix-rds-setup.md          # WALLIX RDS configuration
│   ├── 06-ad-integration.md            # AD/LDAP integration
│   ├── 08-ha-active-active.md          # HA cluster setup
│   ├── 09-test-targets.md              # Target systems configuration
│   ├── 10-siem-integration.md          # SIEM integration
│   ├── 11-observability.md             # Monitoring and observability
│   ├── 12-validation-testing.md        # Validation procedures
│   ├── 13-team-handoffs.md             # Team handoff documentation
│   └── 14-battery-tests.md             # Comprehensive test suite
│
└── examples/              # Automation examples
    ├── README.md          # Examples overview and quick start
    ├── ansible/           # Ansible automation
    │   ├── README.md      # Ansible documentation
    │   ├── ansible.cfg    # Ansible configuration
    │   ├── requirements.yml # Galaxy dependencies
    │   ├── inventory/     # Sample inventory and group_vars
    │   ├── playbooks/     # 7 production playbooks
    │   ├── roles/         # wallix_bastion reusable role
    │   ├── files/csv/     # Sample CSV import files
    │   └── filter_plugins/ # Custom Jinja2 filters
    ├── terraform/         # Infrastructure as Code
    │   ├── README.md      # Terraform guide
    │   ├── provider.tf    # Provider configuration
    │   └── resources/     # Resource definitions
    └── api/               # REST API Examples
        ├── README.md      # API guide
        ├── python/        # Python client examples
        └── curl/          # Shell script examples
```

## Technical Stack

| Component | Technology |
|-----------|------------|
| **Operating System** | Debian 12 (Bookworm) |
| **Database** | MariaDB 10.11+ with replication |
| **Clustering** | Pacemaker/Corosync |
| **Load Balancer** | HAProxy (2x in HA per site) |
| **Firewall** | Fortigate with FortiAuthenticator MFA |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk encryption |
| **Key Derivation** | Argon2ID |
| **Protocols** | SSH, RDP, VNC, HTTP, WinRM |
| **Hypervisor (Pre-Prod Lab)** | VMware vSphere/ESXi 8.0+ |
| **MFA** | FortiAuthenticator 6.4+ with FortiToken |

## Architecture Overview

### 4-Site Synchronized Architecture (Single CPD)

```
4 Sites in Single CPD (synchronized):
Each site: Fortigate → 2x HAProxy (HA) → 2x WALLIX Bastion (HA) → WALLIX RDS → Targets

Site 1-4: Active-Active HA with cross-site sync
Targets: Windows Server 2022, RHEL 10, RHEL 9
```

### Per-Site Components

| Component | Quantity | Purpose |
|-----------|----------|---------|
| Fortigate Firewall | 1 | Perimeter security, SSL VPN, RADIUS proxy |
| HAProxy | 2 (HA pair) | Load balancing with Keepalived VRRP |
| WALLIX Bastion | 2 (HA pair) | PAM core with MariaDB replication |
| WALLIX RDS | 1 | Windows session management |
| Targets | N | Windows Server 2022, RHEL 10/9 |

## Key Topics Covered

### Core PAM (docs/pam/)
- Multi-factor authentication (FortiAuthenticator with FortiToken, LDAP/AD, Kerberos)
- Fortigate firewall integration with FortiToken MFA
- Role-based access control with approval workflows
- Session recording with OCR and keystroke logging
- Credential vault with automatic password rotation
- Just-in-time (JIT) privileged access
- SSH key lifecycle management
- Service account governance
- Session sharing and collaboration
- User self-service portal
- Command filtering and restrictions

### Deployment Models
- Multi-site (4-site): All sites in single CPD with cross-site sync
- High Availability: Active-Active clustering at each site
- Infrastructure: On-premises only (bare metal servers and VMs)
- Load Balancing: HAProxy in HA configuration (Keepalived VRRP)
- **Note**: No cloud/SaaS, no Docker/Kubernetes - all deployments are on-prem

### Target Systems
- Windows Server 2022 (RDP, WinRM)
- RHEL 10 (SSH)
- RHEL 9 legacy (SSH)

## Official WALLIX Resources

Use these authoritative sources when verifying or extending documentation:

| Resource | URL |
|----------|-----|
| **Documentation Portal** | https://pam.wallix.one/documentation |
| **User Guide (PDF)** | https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf |
| **Admin Guide (PDF)** | https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf |
| **Terraform Provider** | https://registry.terraform.io/providers/wallix/wallix-bastion |
| **Terraform GitHub** | https://github.com/wallix/terraform-provider-wallix-bastion |
| **REST API Samples** | https://github.com/wallix/wbrest_samples |
| **SCIM API** | https://scim.wallix.com/scim/doc/Usage.html |
| **WALLIX GitHub** | https://github.com/wallix |
| **Release Notes** | https://pam.wallix.one/documentation/release-notes |
| **Support Portal** | https://support.wallix.com |

## Documentation Conventions

### File Naming
- Sections numbered with two-digit prefix: `01-introduction/`, `02-architecture/`
- Installation steps numbered: `00-debian-luks-installation.md`, `01-prerequisites.md`
- Use lowercase with hyphens: `security-hardening.md`, not `SecurityHardening.md`

### Markdown Style
- GitHub-flavored Markdown (GFM)
- Tables for structured data
- Fenced code blocks with language hints
- ASCII diagrams for architecture (fixed-width, no special characters)

### ASCII Diagram Guidelines

**Standard Width**: All full-width diagrams must be exactly **79 characters** wide (81 total including border characters).

**Outer Frame Format** (required for all diagrams):
```
+===============================================================================+
|  DIAGRAM TITLE                                                                |
+===============================================================================+
|                                                                               |
|  Content here with consistent padding to reach 79 chars                       |
|                                                                               |
+===============================================================================+
```

**Key Rules**:
- Outer borders use `=` (equals signs): `+===============================================================================+`
- Inner component boxes use `-` (dashes): `+------------------+`
- All content lines must be padded to exactly 79 characters between the `|` borders
- Use 2 spaces after opening `|` and before closing `|`

**Character Reference**:
```
+=====+  Outer frame borders (equals signs)
+-----+  Inner component boxes (dashes)
|     |  Vertical borders
   |     Connection lines
   v     Arrows (simple ASCII)
```

**Example Inner Components**:
```
+===============================================================================+
|  ARCHITECTURE DIAGRAM                                                         |
+===============================================================================+
|                                                                               |
|  +------------------+     +------------------+     +------------------+        |
|  |   Component A    |     |   Component B    |     |   Component C    |        |
|  +------------------+     +------------------+     +------------------+        |
|                                                                               |
+===============================================================================+
```

### Content Guidelines
- Reference specific WALLIX Bastion versions (12.1.x)
- Include compliance mappings (ISO 27001, SOC 2, NIS2)
- Provide command examples with expected output
- Link to related sections using relative paths

## Important Files to Know

| File | Purpose | Location |
|------|---------|----------|
| `docs/README.md` | Documentation index with role-based learning paths | Root |
| `docs/pam/17-api-reference/README.md` | REST API documentation | PAM Core |
| `docs/pam/31-wabadmin-reference/README.md` | Complete CLI reference | PAM Core |
| `docs/pam/06-authentication/fortiauthenticator-integration.md` | FortiAuthenticator MFA integration | PAM Core |
| `docs/pam/46-fortigate-integration/README.md` | Fortigate firewall integration | PAM Core |
| `install/HOWTO.md` | Main installation walkthrough | Installation |
| `install/README.md` | Architecture overview and timeline | Installation |
| `install/09-architecture-diagrams.md` | Network diagrams and port reference | Installation |
| `pre/README.md` | Pre-production lab setup guide | Pre-Prod Lab |
| `examples/ansible/README.md` | Ansible automation documentation | Examples |

## Common Editing Tasks

### Adding a New Documentation Section

1. Create numbered directory: `docs/pam/XX-section-name/`
2. Add `README.md` with section content
3. Update `docs/README.md` section index
4. Follow existing section structure for consistency

### Updating Installation Procedures
1. Identify affected file in `install/`
2. Maintain step numbering consistency
3. Update `install/HOWTO.md` if major changes
4. Verify cross-references between files

### Adding Architecture Diagrams
1. Use ASCII art for maximum compatibility
2. Place in `install/09-architecture-diagrams.md` or relevant section
3. Include port numbers and protocol details
4. Follow 79-character width standard
5. Test rendering in GitHub markdown preview

### Expanding API Examples
1. Add to `docs/pam/17-api-reference/README.md`
2. Include curl and Python examples
3. Show request and response payloads
4. Reference official wbrest_samples for patterns
5. Update `examples/` with working code samples

## Compliance Standards Referenced

| Standard | Description | Coverage |
|----------|-------------|----------|
| **ISO 27001** | Information Security Management | Full |
| **SOC 2 Type II** | Service Organization Control | Full |
| **NIS2 Directive** | EU Network and Information Security Directive | Full |
| **PCI-DSS** | Payment Card Industry Data Security Standard | Partial |
| **HIPAA** | Health Insurance Portability and Accountability Act | Partial |

## Quick Reference Commands

```bash
# Check WALLIX Bastion status
systemctl status wallix-bastion
wabadmin status

# View license info
wabadmin license-info

# Check HA cluster health
crm status
crm_mon -1

# View audit logs
wabadmin audit --last 20

# MariaDB replication status
mysql -e "SHOW SLAVE STATUS\G"

# Check synchronization status
wabadmin sync-status
```

## Version Information

| Item | Value |
|------|-------|
| Documentation Version | 8.0 |
| WALLIX Bastion Version | 12.1.x |
| Terraform Provider | 0.14.0 (API v3.12) |
| Last Updated | February 2026 |

## Documentation Categories

| Category | Sections | Location | Focus |
|----------|----------|----------|-------|
| **PAM Core** | 46 | `docs/pam/` | Authentication, authorization, password management, session recording, API, deployment, operations, compliance, Fortigate integration |
| **Installation** | 9 | `install/` | Multi-site deployment, HA configuration, security hardening |
| **Pre-Production Lab** | 13 | `pre/` | VMware vSphere/ESXi lab setup, FortiAuthenticator MFA, WALLIX RDS, test targets, validation |
| **Automation** | 3 | `examples/` | Ansible playbooks, Terraform IaC, API samples |

---

*This file helps AI assistants understand the repository context for more accurate and consistent contributions.*
