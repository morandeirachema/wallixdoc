# CLAUDE.md - Repository Context for AI Assistants

This file provides context for AI assistants (Claude, Copilot, etc.) working with this repository.

## Repository Overview

| Property | Value |
|----------|-------|
| **Purpose** | WALLIX Bastion 12.x technical documentation |
| **Type** | Documentation repository (no source code) |
| **Focus** | Privileged Access Management (PAM) for IT and OT environments |
| **Version** | WALLIX Bastion 12.1.x |
| **Content** | ~33,700 lines across 44 markdown files |

## Directory Structure

```
wallix/
├── CLAUDE.md              # This file - AI assistant context
├── README.md              # Repository overview and navigation
├── docs/                  # Product documentation (29 sections)
│   ├── README.md          # Documentation index with learning paths
│   ├── 01-introduction/   # Company and product overview
│   ├── 02-architecture/   # System architecture and deployment models
│   ├── 03-core-components/# Session Manager, Password Manager, Access Manager
│   ├── 04-configuration/  # Object model, domains, devices, accounts
│   ├── 05-authentication/ # MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML
│   ├── 06-authorization/  # RBAC, approval workflows, JIT access
│   ├── 07-password-management/  # Credential vault, rotation, checkout
│   ├── 08-session-management/   # Recording, monitoring, audit trails
│   ├── 09-api-automation/       # REST API, DevOps integration
│   ├── 10-high-availability/    # Clustering, DR, failover
│   ├── 11-migration-from-cyberark/  # Migration strategies
│   ├── 12-troubleshooting/      # Diagnostics, log analysis
│   ├── 13-best-practices/       # Security hardening, operations
│   ├── 14-appendix/             # Quick reference, glossary
│   ├── 15-industrial-overview/  # OT vs IT, regulatory requirements
│   ├── 16-ot-architecture/      # Zone deployment, IEC 62443 zones
│   ├── 17-industrial-protocols/ # Modbus, DNP3, OPC UA, IEC 61850
│   ├── 18-scada-ics-access/     # HMI, PLC, vendor maintenance
│   ├── 19-airgapped-environments/   # Isolated deployments, data diodes
│   ├── 20-iec62443-compliance/  # Security levels, audit evidence
│   ├── 21-industrial-use-cases/ # Power, Oil & Gas, Manufacturing
│   ├── 22-ot-integration/       # SIEM, CMDB, monitoring
│   ├── 23-industrial-best-practices/ # OT security design
│   ├── 24-cloud-deployment/     # AWS, Azure, GCP, Terraform
│   ├── 25-container-deployment/ # Docker, Kubernetes, Helm
│   ├── 26-api-reference/        # REST API documentation
│   ├── 27-error-reference/      # Error codes and remediation
│   ├── 28-system-requirements/  # Hardware, sizing, performance
│   └── 29-upgrade-guide/        # Version upgrades, HA clusters
└── install/               # Multi-site OT installation guide
    ├── README.md          # Architecture overview, 30-day timeline
    ├── HOWTO.md           # Step-by-step guide (1685 lines)
    ├── 00-debian-luks-installation.md  # Base OS with disk encryption
    ├── 01-prerequisites.md             # Pre-deployment checklist
    ├── 02-site-a-primary.md            # Primary HA cluster (Active-Active)
    ├── 03-site-b-secondary.md          # Secondary HA cluster (Active-Passive)
    ├── 04-site-c-remote.md             # Remote standalone with offline
    ├── 05-multi-site-sync.md           # Cross-site replication
    ├── 06-ot-network-config.md         # Industrial protocol setup
    ├── 07-security-hardening.md        # Security configuration
    ├── 08-validation-testing.md        # Testing and go-live
    ├── 09-architecture-diagrams.md     # Visual diagrams and ports
    └── 10-postgresql-streaming-replication.md  # Database HA
```

## Technical Stack

| Component | Technology |
|-----------|------------|
| **Operating System** | Debian 12 (Bookworm) |
| **Database** | PostgreSQL 15+ with streaming replication |
| **Clustering** | Pacemaker/Corosync |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk encryption |
| **Key Derivation** | Argon2ID |
| **Protocols** | SSH, RDP, VNC, HTTP, Modbus, DNP3, OPC UA |

## Key Topics Covered

### Core PAM
- Multi-factor authentication (TOTP, FIDO2, LDAP/AD, Kerberos, OIDC, SAML)
- Role-based access control with approval workflows
- Session recording with OCR and keystroke logging
- Credential vault with automatic password rotation
- Just-in-time (JIT) privileged access

### Industrial/OT Security
- IEC 62443 compliance (Security Levels 1-4)
- Zone-based architecture (Zones 0-5)
- Industrial protocols: Modbus, DNP3, OPC UA, EtherNet/IP, IEC 61850, S7comm
- Air-gapped deployments with offline credential caching
- SCADA/ICS access patterns

### Deployment Models
- Multi-site (3-site): Primary HQ + Secondary Plant + Remote Field
- High Availability: Active-Active and Active-Passive clustering
- Cloud: AWS, Azure, GCP with Terraform IaC
- Containers: Docker, Kubernetes, OpenShift

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
```
Use these characters for diagrams:
┌───┐  Box corners and lines
│   │  Vertical lines
├───┤  Intersections
└───┘  Bottom corners
─────  Horizontal lines
═════  Double lines for emphasis
  │    Arrows: use simple ASCII
  ▼    or unicode arrows sparingly
```

### Content Guidelines
- Reference specific WALLIX Bastion versions (12.1.x)
- Include compliance mappings (IEC 62443, NIST 800-82, NIS2)
- Provide command examples with expected output
- Link to related sections using relative paths

## Important Files to Know

| File | Purpose | Lines |
|------|---------|-------|
| `docs/README.md` | Documentation index with role-based learning paths | 167 |
| `install/HOWTO.md` | Main installation walkthrough | 1685 |
| `install/README.md` | Architecture overview and 30-day timeline | 788 |
| `install/09-architecture-diagrams.md` | Network diagrams and port reference | 913 |
| `docs/26-api-reference/README.md` | REST API documentation | 1386 |
| `docs/24-cloud-deployment/README.md` | Cloud deployment patterns | 1289 |

## Common Editing Tasks

### Adding a New Documentation Section
1. Create numbered directory: `docs/XX-section-name/`
2. Add `README.md` with section content
3. Update `docs/README.md` index
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
4. Test rendering in GitHub markdown preview

### Expanding API Examples
1. Add to `docs/26-api-reference/README.md`
2. Include curl and Python examples
3. Show request and response payloads
4. Reference official wbrest_samples for patterns

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
| Documentation Version | 3.0 |
| WALLIX Bastion Version | 12.1.x |
| Terraform Provider | 0.14.0 (API v3.12) |
| Last Updated | January 2026 |

---

*This file helps AI assistants understand the repository context for more accurate and consistent contributions.*
