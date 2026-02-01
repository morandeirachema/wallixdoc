# CLAUDE.md - Repository Context for AI Assistants

This file provides context for AI assistants (Claude, Copilot, etc.) working with this repository.

## Repository Overview

| Property | Value |
|----------|-------|
| **Purpose** | WALLIX Bastion 12.x technical documentation |
| **Type** | Documentation repository (no source code) |
| **Focus** | Privileged Access Management (PAM) for IT and OT environments |
| **Deployment** | On-premises only (bare metal and VMs, no cloud/SaaS) |
| **Version** | WALLIX Bastion 12.1.x |
| **Content** | 66 documentation sections (47 PAM + 19 OT) |

## Directory Structure

```
wallixdoc/
├── CLAUDE.md              # This file - AI assistant context
├── README.md              # Repository overview and navigation
│
├── docs/                  # Product documentation (66 sections)
│   ├── README.md          # Documentation index with learning paths
│   │
│   ├── pam/               # PAM/WALLIX Core Documentation (47 sections)
│   │   ├── 00-official-resources/     # Official WALLIX documentation links
│   │   ├── 01-quick-start/            # Quick start guide and UI walkthrough
│   │   ├── 02-introduction/           # Company and product overview
│   │   ├── 03-architecture/           # System architecture, deployment models
│   │   ├── 04-core-components/        # Session Manager, Password Manager
│   │   ├── 05-configuration/          # Object model, domains, devices
│   │   ├── 06-authentication/         # MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML
│   │   ├── 07-authorization/          # RBAC, approval workflows, JIT access
│   │   ├── 08-password-management/    # Credential vault, rotation, checkout
│   │   ├── 09-session-management/     # Recording, monitoring, audit trails
│   │   ├── 10-api-automation/         # REST API, DevOps integration
│   │   ├── 11-high-availability/      # Clustering, DR, failover
│   │   ├── 12-monitoring-observability/ # Prometheus, Grafana, alerting
│   │   ├── 13-troubleshooting/        # Diagnostics, log analysis
│   │   ├── 14-best-practices/         # Security hardening, operations
│   │   ├── 15-appendix/               # Quick reference, glossary
│   │   ├── 16-cloud-deployment/       # On-premises deployment patterns
│   │   ├── 17-api-reference/          # REST API documentation
│   │   ├── 18-error-reference/        # Error codes and remediation
│   │   ├── 19-system-requirements/    # Hardware, sizing, performance
│   │   ├── 20-upgrade-guide/          # Version upgrades, HA clusters
│   │   ├── 21-operational-runbooks/   # Daily/weekly/monthly procedures
│   │   ├── 22-faq-known-issues/       # FAQ, known issues, compatibility
│   │   ├── 23-incident-response/      # Security incident playbooks
│   │   ├── 24-compliance-audit/       # SOC2, ISO27001, PCI-DSS, HIPAA, GDPR
│   │   ├── 25-jit-access/             # Just-In-Time access, approvals
│   │   ├── 26-performance-benchmarks/ # Capacity planning, load testing
│   │   ├── 27-vendor-integration/     # Cisco, Siemens, ABB, Rockwell
│   │   ├── 28-certificate-management/ # TLS/SSL, CSR, renewal, Let's Encrypt
│   │   ├── 29-disaster-recovery/      # DR runbooks, RTO/RPO, PITR
│   │   ├── 30-backup-restore/         # Full/selective backup, disaster recovery
│   │   ├── 31-wabadmin-reference/     # Complete CLI command reference
│   │   ├── 32-load-balancer/          # HAProxy, Nginx, F5, health checks
│   │   ├── 33-password-rotation-troubleshooting/ # Rotation failures
│   │   ├── 34-ldap-ad-integration/    # Active Directory integration
│   │   ├── 35-kerberos-authentication/ # Kerberos, SPNEGO, SSO
│   │   ├── 36-network-validation/     # Firewall rules, DNS, NTP
│   │   ├── 37-compliance-evidence/    # Evidence collection, attestation
│   │   ├── 38-command-filtering/      # Command whitelist/blacklist
│   │   ├── 39-session-recording-playback/ # Playback, OCR, forensics
│   │   ├── 40-fido2-hardware-mfa/     # FIDO2/WebAuthn, YubiKey
│   │   ├── 41-account-discovery/      # Discovery scanning, bulk import
│   │   ├── 42-ssh-key-lifecycle/      # SSH key management, rotation, CA
│   │   ├── 43-service-account-lifecycle/ # Service account governance
│   │   ├── 44-session-sharing/        # Multi-user sessions, dual-control
│   │   ├── 45-user-self-service/      # Self-service portal
│   │   └── 46-privileged-task-automation/ # Automated privileged operations
│   │
│   └── ot/                # OT Foundational Documentation (19 sections)
│       ├── 00-fundamentals/           # OT Cybersecurity Fundamentals (16 modules)
│       │   ├── README.md              # 16-week learning path overview
│       │   ├── 01-ot-fundamentals.md  # Control theory, process basics
│       │   ├── 02-control-systems-101.md # PLC, RTU, DCS, HMI, SCADA
│       │   ├── 03-ot-vs-it-security.md # Mindset shift, CIA reversal
│       │   ├── 04-industrial-protocols.md # Modbus, DNP3, OPC UA
│       │   ├── 05-ot-network-architecture.md # Purdue Model, zones
│       │   ├── 06-legacy-systems.md   # Securing unpatchable systems
│       │   ├── 07-ot-threat-landscape.md # APT groups, ICS malware
│       │   ├── 08-ot-threat-modeling.md # Attack trees, STRIDE for OT
│       │   ├── 09-ot-incident-response.md # Safety-first IR
│       │   ├── 10-iec62443-deep-dive.md # Security levels, compliance
│       │   ├── 11-regulatory-landscape.md # NERC CIP, CFATS, NIS2
│       │   ├── 12-vendor-risk-management.md # Third-party access
│       │   ├── 13-ot-security-career.md # Certifications, career paths
│       │   ├── 14-hands-on-labs.md    # Lab setup, practice
│       │   └── 15-resources.md        # Books, courses, communities
│       ├── 01-industrial-overview/    # OT vs IT, regulatory requirements
│       ├── 02-ot-architecture/        # Zone deployment, IEC 62443 zones
│       ├── 03-industrial-protocols/   # Modbus, DNP3, OPC UA, IEC 61850
│       ├── 04-scada-ics-access/       # HMI, PLC, vendor maintenance
│       ├── 05-airgapped-environments/ # Isolated deployments, data diodes
│       ├── 06-iec62443-compliance/    # Security levels, audit evidence
│       ├── 07-industrial-use-cases/   # Power, Oil & Gas, Manufacturing
│       ├── 08-ot-integration/         # SIEM, CMDB, monitoring platforms
│       ├── 09-industrial-best-practices/ # OT security design
│       ├── 10-offline-operations/     # Air-gapped ops, credential cache
│       ├── 11-vendor-remote-access/   # Third-party vendor access
│       ├── 12-ot-jump-host/           # Jump server configuration
│       ├── 13-ot-safety-procedures/   # LOTO integration, SIS access
│       ├── 14-engineering-workstation-access/ # EWS access patterns
│       ├── 15-ot-change-management/   # Change windows, rollback
│       ├── 16-historian-access/       # Historian security, data diode
│       ├── 17-rtu-field-access/       # RTU and field device management
│       └── 18-ot-training-certifications/ # OT cybersecurity training, certifications, career paths
│
├── install/               # Multi-site OT installation guide
│   ├── README.md          # Architecture overview, 30-day timeline
│   ├── HOWTO.md           # Step-by-step guide (1685 lines)
│   ├── 00-debian-luks-installation.md  # Base OS with disk encryption
│   ├── 01-prerequisites.md             # Pre-deployment checklist
│   ├── 02-site-a-primary.md            # Primary HA cluster (Active-Active)
│   ├── 03-site-b-secondary.md          # Secondary HA cluster (Active-Passive)
│   ├── 04-site-c-remote.md             # Remote standalone with offline
│   ├── 05-multi-site-sync.md           # Cross-site replication
│   ├── 06-ot-network-config.md         # Industrial protocol setup
│   ├── 07-security-hardening.md        # Security configuration
│   ├── 08-validation-testing.md        # Testing and go-live
│   ├── 09-architecture-diagrams.md     # Visual diagrams and ports
│   └── 10-postgresql-streaming-replication.md  # Database HA
│
├── pre/                   # Pre-production lab environment
│   ├── README.md          # Lab overview and architecture
│   ├── 01-infrastructure-setup.md      # VMware vSphere/ESXi setup
│   ├── 02-active-directory-setup.md    # AD domain controller
│   ├── 03-haproxy-setup.md             # Load balancer configuration
│   ├── 04-fortiauthenticator-setup.md  # FortiAuthenticator MFA
│   ├── 05-wallix-rds-setup.md          # WALLIX RDS configuration
│   ├── 06-ad-integration.md            # AD/LDAP integration
│   ├── 07-pam4ot-installation.md       # WALLIX Bastion installation
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
| **Database** | PostgreSQL 15+ with streaming replication |
| **Clustering** | Pacemaker/Corosync |
| **Load Balancer** | HAProxy (2x in HA) |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk encryption |
| **Key Derivation** | Argon2ID |
| **Protocols** | SSH, RDP, VNC, HTTP, Modbus, DNP3, OPC UA |
| **Hypervisor (Pre-Prod Lab)** | VMware vSphere/ESXi 8.0+ |
| **MFA (Pre-Prod Lab)** | FortiAuthenticator 6.4+ |

## Key Topics Covered

### Core PAM (docs/pam/)
- Multi-factor authentication (TOTP, FIDO2/WebAuthn, FortiAuthenticator, LDAP/AD, Kerberos, OIDC, SAML)
- Role-based access control with approval workflows
- Session recording with OCR and keystroke logging
- Credential vault with automatic password rotation
- Just-in-time (JIT) privileged access
- SSH key lifecycle management
- Service account governance
- Session sharing and collaboration
- User self-service portal
- Command filtering and restrictions

### Industrial/OT Security (docs/ot/)
- **OT Cybersecurity Fundamentals** - 16-week learning path for IT professionals transitioning to OT
- **OT Training & Certifications** - Professional certifications (GICSP, GRID), training providers, career paths
- IEC 62443 compliance (Security Levels 1-4)
- Zone-based architecture (Zones 0-5)
- Industrial protocols: Modbus, DNP3, OPC UA, EtherNet/IP, IEC 61850, S7comm
- Air-gapped deployments with offline credential caching
- SCADA/ICS access patterns
- OT safety procedures (LOTO, SIS)
- Engineering workstation access
- Vendor remote access management
- Historian and RTU field access

### Deployment Models
- Multi-site (3-site): Primary HQ + Secondary Plant + Remote Field
- High Availability: Active-Active and Active-Passive clustering
- Infrastructure: On-premises only (bare metal servers and VMs)
- Load Balancing: HAProxy in HA configuration
- **Note**: No cloud/SaaS, no Docker/Kubernetes - all deployments are on-prem

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
- Include compliance mappings (IEC 62443, NIST 800-82, NIS2)
- Provide command examples with expected output
- Link to related sections using relative paths (account for pam/ and ot/ directories)

## Important Files to Know

| File | Purpose | Location |
|------|---------|----------|
| `docs/README.md` | Documentation index with role-based learning paths | Root |
| `docs/pam/17-api-reference/README.md` | REST API documentation | PAM Core |
| `docs/pam/31-wabadmin-reference/README.md` | Complete CLI reference | PAM Core |
| `docs/ot/00-fundamentals/README.md` | OT Cybersecurity Fundamentals (16-week learning path) | OT |
| `docs/ot/06-iec62443-compliance/README.md` | IEC 62443 compliance guide | OT |
| `docs/ot/18-ot-training-certifications/README.md` | OT training, certifications, career paths | OT |
| `install/HOWTO.md` | Main installation walkthrough | Installation |
| `install/README.md` | Architecture overview and 30-day timeline | Installation |
| `install/09-architecture-diagrams.md` | Network diagrams and port reference | Installation |
| `pre/README.md` | Pre-production lab setup guide | Pre-Prod Lab |
| `examples/ansible/README.md` | Ansible automation documentation | Examples |

## Common Editing Tasks

### Adding a New Documentation Section

**For PAM Core sections:**
1. Create numbered directory: `docs/pam/XX-section-name/`
2. Add `README.md` with section content
3. Update `docs/README.md` PAM section index
4. Follow existing section structure for consistency

**For OT Foundational sections:**
1. Create numbered directory: `docs/ot/XX-section-name/`
2. Add `README.md` with section content
3. Update `docs/README.md` OT section index
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

### Cross-Referencing Between PAM and OT
- PAM sections: Use `../../pam/XX-section/` for relative links
- OT sections: Use `../../ot/XX-section/` for relative links
- From root docs: Use `./pam/XX-section/` or `./ot/XX-section/`

## Compliance Standards Referenced

| Standard | Description | Coverage |
|----------|-------------|----------|
| **IEC 62443** | Industrial Automation and Control Systems Security | Full |
| **NIST 800-82** | Guide to Industrial Control Systems Security | Full |
| **NIS2 Directive** | EU Network and Information Security Directive | Full |
| **ISO 27001** | Information Security Management | Partial |
| **SOC 2 Type II** | Service Organization Control | Partial |

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

# PostgreSQL replication status
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Check synchronization status
wabadmin sync-status
```

## Version Information

| Item | Value |
|------|-------|
| Documentation Version | 7.0 |
| WALLIX Bastion Version | 12.1.x |
| Terraform Provider | 0.14.0 (API v3.12) |
| Last Updated | February 2026 |

## Documentation Categories

| Category | Sections | Location | Focus |
|----------|----------|----------|-------|
| **PAM Core** | 47 | `docs/pam/` | Authentication, authorization, password management, session recording, API, deployment, operations, compliance |
| **OT Foundational** | 19 | `docs/ot/` | OT fundamentals (16-week learning path), industrial protocols, IEC 62443, SCADA/ICS, air-gapped environments, OT safety, vendor access, training & certifications |
| **Installation** | 11 | `install/` | Multi-site deployment, HA configuration, security hardening |
| **Pre-Production Lab** | 14 | `pre/` | VMware vSphere/ESXi lab setup, FortiAuthenticator MFA, WALLIX RDS, test targets, validation |
| **Automation** | 3 | `examples/` | Ansible playbooks, Terraform IaC, API samples |

---

*This file helps AI assistants understand the repository context for more accurate and consistent contributions.*
