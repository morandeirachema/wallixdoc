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
| **Content** | 64 documentation sections (47 PAM + 17 OT) |

## Directory Structure

```
wallixdoc/
├── CLAUDE.md              # This file - AI assistant context
├── README.md              # Repository overview and navigation
│
├── docs/                  # Product documentation (64 sections)
│   ├── README.md          # Documentation index with learning paths
│   │
│   ├── pam/               # PAM/WALLIX Core Documentation (47 sections)
│   │   ├── 00-official-resources/     # Official WALLIX documentation links
│   │   ├── 00-quick-start/            # Quick start guide and UI walkthrough
│   │   ├── 01-introduction/           # Company and product overview
│   │   ├── 02-architecture/           # System architecture, deployment models
│   │   ├── 03-core-components/        # Session Manager, Password Manager
│   │   ├── 04-configuration/          # Object model, domains, devices
│   │   ├── 05-authentication/         # MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML
│   │   ├── 06-authorization/          # RBAC, approval workflows, JIT access
│   │   ├── 07-password-management/    # Credential vault, rotation, checkout
│   │   ├── 08-session-management/     # Recording, monitoring, audit trails
│   │   ├── 09-api-automation/         # REST API, DevOps integration
│   │   ├── 10-high-availability/      # Clustering, DR, failover
│   │   ├── 11-monitoring-observability/ # Prometheus, Grafana, alerting
│   │   ├── 12-troubleshooting/        # Diagnostics, log analysis
│   │   ├── 13-best-practices/         # Security hardening, operations
│   │   ├── 14-appendix/               # Quick reference, glossary
│   │   ├── 24-cloud-deployment/       # On-premises deployment patterns
│   │   ├── 26-api-reference/          # REST API documentation
│   │   ├── 27-error-reference/        # Error codes and remediation
│   │   ├── 28-system-requirements/    # Hardware, sizing, performance
│   │   ├── 29-upgrade-guide/          # Version upgrades, HA clusters
│   │   ├── 30-operational-runbooks/   # Daily/weekly/monthly procedures
│   │   ├── 31-faq-known-issues/       # FAQ, known issues, compatibility
│   │   ├── 32-incident-response/      # Security incident playbooks
│   │   ├── 33-compliance-audit/       # SOC2, ISO27001, PCI-DSS, HIPAA, GDPR
│   │   ├── 34-jit-access/             # Just-In-Time access, approvals
│   │   ├── 35-performance-benchmarks/ # Capacity planning, load testing
│   │   ├── 36-vendor-integration/     # Cisco, Siemens, ABB, Rockwell
│   │   ├── 38-certificate-management/ # TLS/SSL, CSR, renewal, Let's Encrypt
│   │   ├── 39-disaster-recovery/      # DR runbooks, RTO/RPO, PITR
│   │   ├── 40-backup-restore/         # Full/selective backup, disaster recovery
│   │   ├── 41-wabadmin-reference/     # Complete CLI command reference
│   │   ├── 42-load-balancer/          # HAProxy, Nginx, F5, health checks
│   │   ├── 44-password-rotation-troubleshooting/ # Rotation failures
│   │   ├── 45-ldap-ad-integration/    # Active Directory integration
│   │   ├── 46-kerberos-authentication/ # Kerberos, SPNEGO, SSO
│   │   ├── 47-network-validation/     # Firewall rules, DNS, NTP
│   │   ├── 48-compliance-evidence/    # Evidence collection, attestation
│   │   ├── 49-command-filtering/      # Command whitelist/blacklist
│   │   ├── 50-session-recording-playback/ # Playback, OCR, forensics
│   │   ├── 52-fido2-hardware-mfa/     # FIDO2/WebAuthn, YubiKey
│   │   ├── 53-account-discovery/      # Discovery scanning, bulk import
│   │   ├── 56-ssh-key-lifecycle/      # SSH key management, rotation, CA
│   │   ├── 57-service-account-lifecycle/ # Service account governance
│   │   ├── 58-session-sharing/        # Multi-user sessions, dual-control
│   │   ├── 59-user-self-service/      # Self-service portal
│   │   └── 60-privileged-task-automation/ # Automated privileged operations
│   │
│   └── ot/                # OT Foundational Documentation (17 sections)
│       ├── 15-industrial-overview/    # OT vs IT, regulatory requirements
│       ├── 16-ot-architecture/        # Zone deployment, IEC 62443 zones
│       ├── 17-industrial-protocols/   # Modbus, DNP3, OPC UA, IEC 61850
│       ├── 18-scada-ics-access/       # HMI, PLC, vendor maintenance
│       ├── 19-airgapped-environments/ # Isolated deployments, data diodes
│       ├── 20-iec62443-compliance/    # Security levels, audit evidence
│       ├── 21-industrial-use-cases/   # Power, Oil & Gas, Manufacturing
│       ├── 22-ot-integration/         # SIEM, CMDB, monitoring platforms
│       ├── 23-industrial-best-practices/ # OT security design
│       ├── 51-offline-operations/     # Air-gapped ops, credential cache
│       ├── 54-vendor-remote-access/   # Third-party vendor access
│       ├── 55-ot-jump-host/           # Jump server configuration
│       ├── 61-ot-safety-procedures/   # LOTO integration, SIS access
│       ├── 62-engineering-workstation-access/ # EWS access patterns
│       ├── 63-ot-change-management/   # Change windows, rollback
│       ├── 64-historian-access/       # Historian security, data diode
│       └── 65-rtu-field-access/       # RTU and field device management
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

## Key Topics Covered

### Core PAM (docs/pam/)
- Multi-factor authentication (TOTP, FIDO2/WebAuthn, LDAP/AD, Kerberos, OIDC, SAML)
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
| `docs/pam/26-api-reference/README.md` | REST API documentation | PAM Core |
| `docs/pam/41-wabadmin-reference/README.md` | Complete CLI reference | PAM Core |
| `docs/ot/20-iec62443-compliance/README.md` | IEC 62443 compliance guide | OT |
| `install/HOWTO.md` | Main installation walkthrough | Installation |
| `install/README.md` | Architecture overview and 30-day timeline | Installation |
| `install/09-architecture-diagrams.md` | Network diagrams and port reference | Installation |
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
1. Add to `docs/pam/26-api-reference/README.md`
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
| Documentation Version | 6.0 |
| WALLIX Bastion Version | 12.1.x |
| Terraform Provider | 0.14.0 (API v3.12) |
| Last Updated | February 2026 |

## Documentation Categories

| Category | Sections | Location | Focus |
|----------|----------|----------|-------|
| **PAM Core** | 47 | `docs/pam/` | Authentication, authorization, password management, session recording, API, deployment, operations, compliance |
| **OT Foundational** | 17 | `docs/ot/` | Industrial protocols, IEC 62443, SCADA/ICS, air-gapped environments, OT safety, vendor access |
| **Installation** | 11 | `install/` | Multi-site deployment, HA configuration, security hardening |
| **Automation** | 3 | `examples/` | Ansible playbooks, Terraform IaC, API samples |

---

*This file helps AI assistants understand the repository context for more accurate and consistent contributions.*
