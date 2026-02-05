# 14 - Appendix

## Table of Contents

- [14 - Appendix](#14---appendix)
  - [Table of Contents](#table-of-contents)
  - [Cross-Reference Index](#cross-reference-index)
  - [Quick Reference Card](#quick-reference-card)
  - [CLI Commands Reference](#cli-commands-reference)
  - [API Quick Reference](#api-quick-reference)
  - [Port Reference](#port-reference)
  - [File Locations](#file-locations)
  - [Glossary](#glossary)
  - [Terminology Standards](#terminology-standards)
  - [CyberArk to WALLIX Cheat Sheet](#cyberark-to-wallix-cheat-sheet)
  - [Additional Resources](#additional-resources)
    - [Documentation Links](#documentation-links)
    - [Useful External Resources](#useful-external-resources)
  - [Next Steps](#next-steps)

---

## Cross-Reference Index

Need to find a specific topic quickly across all 47 documentation sections? Use the master index.

**[Master Cross-Reference Index](cross-reference-index.md)** - Organized topic tables covering:
- Authentication Topics (MFA, LDAP, Kerberos, RADIUS, SAML, OIDC)
- API & Automation Topics (REST API, wabadmin CLI, Terraform, Ansible)
- Networking Topics (ports, firewall rules, Fortigate, HAProxy, VPN)
- High Availability Topics (clustering, failover, replication, DR, backup)
- Troubleshooting Topics (errors, diagnostics, common issues, logs)
- Compliance Topics (audit, SOC2, ISO27001, NIS2, evidence)
- Session Management Topics (recording, playback, OCR, monitoring)
- Password & Credential Topics (vault, rotation, checkout, SSH keys)
- Infrastructure & Deployment Topics (architecture, sizing, installation)
- Advanced Features Topics (JIT access, RBAC, account discovery)

---

## Quick Reference Card

```
+===============================================================================+
|                    WALLIX BASTION QUICK REFERENCE                             |
+===============================================================================+
|                                                                               |
|  SERVICE MANAGEMENT                                                           |
|  ==================                                                           |
|                                                                               |
|  Start all services:        systemctl start wab*                              |
|  Stop all services:         systemctl stop wab*                               |
|  Restart all services:      systemctl restart wab*                            |
|  Check status:              waservices status                                 |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  Main config:               /etc/opt/wab/wabengine.conf                       |
|  Validate config:           waconfig --check                                  |
|  Apply config:              waconfig --reload                                 |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  LOGS                                                                         |
|  ====                                                                         |
|                                                                               |
|  Main log:                  /var/log/wabengine/wabengine.log                  |
|  Audit log:                 /var/log/wabaudit/audit.log                       |
|  Session log:               /var/log/wabsessions/sessions.log                 |
|  Tail all logs:             tail -f /var/log/wab*/*.log                       |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DATABASE                                                                     |
|  ========                                                                     |
|                                                                               |
|  Connect:                   mysql -u wabadmin wabdb                           |
|  Backup:                    mysqldump -u wabadmin wabdb > backup.sql          |
|  Check size:                du -sh /var/lib/mysql/                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  RECORDINGS                                                                   |
|  ==========                                                                   |
|                                                                               |
|  Storage location:          /var/wab/recorded/                                |
|  Check disk usage:          df -h /var/wab/recorded                           |
|  Count recordings:          find /var/wab/recorded -name "*.wab" | wc -l      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  WEB INTERFACE                                                                |
|  =============                                                                |
|                                                                               |
|  Admin UI:                  https://bastion.company.com/admin                 |
|  User Portal:               https://bastion.company.com/                      |
|  API Docs:                  https://bastion.company.com/api/docs              |
|                                                                               |
+===============================================================================+
```

---

## CLI Commands Reference

```
+===============================================================================+
|                    CLI COMMANDS REFERENCE                                     |
+===============================================================================+
|                                                                               |
|  SYSTEM COMMANDS                                                              |
|  ===============                                                              |
|                                                                               |
|  waservices                                                                   |
|  +-- status         Show all service status                                   |
|  +-- start          Start all services                                        |
|  +-- stop           Stop all services                                         |
|  +-- restart        Restart all services                                      |
|                                                                               |
|  waconfig                                                                     |
|  +-- --check        Validate configuration                                    |
|  +-- --reload       Reload configuration                                      |
|  +-- --export       Export configuration                                      |
|                                                                               |
|  wabdiag                                                                      |
|  +-- --quick        Quick diagnostic check                                    |
|  +-- --full         Full system diagnostic                                    |
|  +-- --network      Network connectivity check                                |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  USER COMMANDS                                                                |
|  =============                                                                |
|                                                                               |
|  wabuser                                                                      |
|  +-- list           List all users                                            |
|  +-- add            Add new user                                              |
|  +-- delete         Delete user                                               |
|  +-- passwd         Change user password                                      |
|  +-- lock/unlock    Lock or unlock user                                       |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DEVICE/ACCOUNT COMMANDS                                                      |
|  =======================                                                      |
|                                                                               |
|  wabdevice                                                                    |
|  +-- list           List all devices                                          |
|  +-- add            Add new device                                            |
|  +-- delete         Delete device                                             |
|                                                                               |
|  wabaccount                                                                   |
|  +-- list           List all accounts                                         |
|  +-- add            Add new account                                           |
|  +-- passwd         Show/change account password                              |
|  +-- rotate         Trigger password rotation                                 |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SESSION COMMANDS                                                             |
|  ================                                                             |
|                                                                               |
|  wabsession                                                                   |
|  +-- list           List active sessions                                      |
|  +-- kill           Terminate session                                         |
|  +-- history        Show session history                                      |
|                                                                               |
|  -------------------------------------------------------------------------- - |
|                                                                               |
|  BACKUP COMMANDS                                                              |
|  ===============                                                              |
|                                                                               |
|  wabbackup                                                                    |
|  +-- create         Create full backup                                        |
|  +-- restore        Restore from backup                                       |
|  +-- list           List available backups                                    |
|                                                                               |
+===============================================================================+
```

---

## API Quick Reference

```
+===============================================================================+
|                    API QUICK REFERENCE                                        |
+===============================================================================+
|                                                                               |
|  AUTHENTICATION                                                               |
|  ==============                                                               |
|                                                                               |
|  POST /api/auth/login                                                         |
|  Body: {"username": "admin", "password": "secret"}                            |
|                                                                               |
|  Or use header: X-Auth-Token: your-api-key                                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DEVICES                                                                      |
|  =======                                                                      |
|                                                                               |
|  GET    /api/devices                    List all devices                      |
|  GET    /api/devices/{name}             Get device details                    |
|  POST   /api/devices                    Create device                         |
|  PUT    /api/devices/{name}             Update device                         |
|  DELETE /api/devices/{name}             Delete device                         |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ACCOUNTS                                                                     |
|  ========                                                                     |
|                                                                               |
|  GET    /api/accounts                   List all accounts                     |
|  GET    /api/accounts/{name}            Get account details                   |
|  POST   /api/accounts                   Create account                        |
|  PUT    /api/accounts/{name}            Update account                        |
|  DELETE /api/accounts/{name}            Delete account                        |
|  GET    /api/accounts/{name}/password   Get password                          |
|  POST   /api/accounts/{name}/password/change   Rotate password                |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SESSIONS                                                                     |
|  ========                                                                     |
|                                                                               |
|  GET    /api/sessions/current           List active sessions                  |
|  DELETE /api/sessions/current/{id}      Kill session                          |
|  GET    /api/sessions/history           Session history                       |
|  GET    /api/sessions/{id}/recording    Get recording                         |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  USERS & GROUPS                                                               |
|  =============                                                                |
|                                                                               |
|  GET    /api/users                      List users                            |
|  GET    /api/usergroups                 List user groups                      |
|  GET    /api/targetgroups               List target groups                    |
|  GET    /api/authorizations             List authorizations                   |
|                                                                               |
+===============================================================================+
```

---

## Port Reference

```
+===============================================================================+
|                    PORT REFERENCE                                             |
+===============================================================================+
|                                                                               |
|  INBOUND TO WALLIX BASTION                                                    |
|  =========================                                                    |
|                                                                               |
|  Port    Protocol   Source        Purpose                                     |
|  ----    --------   ------        -------                                     |
|  443     TCP        Users         Web UI, API, HTML5 sessions                 |
|  22      TCP        Users         SSH proxy                                   |
|  3389    TCP        Users         RDP proxy                                   |
|  5900    TCP        Users         VNC proxy                                   |
|  23      TCP        Users         Telnet proxy (if needed)                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  OUTBOUND FROM WALLIX BASTION                                                 |
|  ===========================                                                  |
|                                                                               |
|  Port    Protocol   Destination   Purpose                                     |
|  ----    --------   -----------   -------                                     |
|  22      TCP        Targets       SSH to targets                              |
|  3389    TCP        Targets       RDP to targets                              |
|  5900    TCP        Targets       VNC to targets                              |
|  23      TCP        Targets       Telnet to targets                           |
|  389     TCP        LDAP          LDAP authentication                         |
|  636     TCP        LDAP          LDAPS authentication                        |
|  88      TCP/UDP    KDC           Kerberos authentication                     |
|  1812    UDP        RADIUS        RADIUS/MFA                                  |
|  514     UDP        SIEM          Syslog                                      |
|  6514    TCP        SIEM          Syslog over TLS                             |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  INTERNAL (Cluster)                                                           |
|  ==================                                                           |
|                                                                               |
|  Port    Protocol   Purpose                                                   |
|  ----    --------   -------                                                   |
|  3306    TCP        MariaDB replication                                       |
|  Various TCP        Cluster communication                                     |
|                                                                               |
+===============================================================================+
```

---

## File Locations

```
+===============================================================================+
|                    FILE LOCATIONS                                             |
+===============================================================================+
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  /etc/opt/wab/                       Main configuration directory             |
|  +-- wabengine.conf                  Engine configuration                     |
|  +-- wabproxy.conf                   Proxy configuration                      |
|  +-- wabpassword.conf                Password manager config                  |
|                                                                               |
|  /etc/opt/wab/ssl/                   SSL certificates                         |
|  +-- server.crt                      Server certificate                       |
|  +-- server.key                      Server private key                       |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  LOGS                                                                         |
|  ====                                                                         |
|                                                                               |
|  /var/log/wabengine/                 Application logs                         |
|  /var/log/wabaudit/                  Audit logs                               |
|  /var/log/wabsessions/               Session logs                             |
|  /var/lib/mysql/                     Database logs                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DATA                                                                         |
|  ====                                                                         |
|                                                                               |
|  /var/wab/recorded/                  Session recordings                       |
|  /var/lib/mysql/                     Database data                            |
|  /var/opt/wab/                       Variable application data                |
|  /var/opt/wab/keys/                  Encryption keys                          |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  BINARIES                                                                     |
|  ========                                                                     |
|                                                                               |
|  /opt/wab/bin/                       WALLIX binaries                          |
|  /opt/wab/lib/                       WALLIX libraries                         |
|                                                                               |
+===============================================================================+
```

---

## Glossary

```
+===============================================================================+
|                    GLOSSARY                                                   |
+===============================================================================+
|                                                                               |
|  Term                 Definition                                              |
|  ----                 ----------                                              |
|                                                                               |
|  Account              Privileged credential (username + password/key)         |
|  Authorization        Access policy linking user group to target group        |
|  Bastion              Core WALLIX PAM appliance/server                        |
|  Checkout             Process of requesting credential access                 |
|  Device               Target system managed by WALLIX                         |
|  Domain               Logical container for organizing devices                |
|  Injection            Transparent credential insertion into session           |
|  OCR                  Optical Character Recognition (for RDP search)          |
|  Primary Auth         First factor authentication (password, AD)              |
|  Proxy                Network intermediary handling session traffic           |
|  Recording            Captured session video/text for audit                   |
|  Reconciliation       Process to recover from password sync issues            |
|  Rotation             Automatic password change process                       |
|  Service              Protocol definition on a device (SSH, RDP, etc.)        |
|  Session              Active connection between user and target               |
|  Shadow               Real-time session viewing capability                    |
|  Subprotocol          Sub-feature of protocol (SCP, SFTP for SSH)             |
|  Target               System user connects to through WALLIX                  |
|  Target Group         Collection of accounts for authorization                |
|  User Group           Collection of users for authorization                   |
|  Vault                Encrypted credential storage                            |
|  4-Eyes               Dual control requiring second person                    |
|                                                                               |
+===============================================================================+
```

---

## Terminology Standards

To ensure consistency across all 47 documentation sections, use these standardized terms:

### Authentication & MFA

| Use This | Not This | Rationale |
|----------|----------|-----------|
| MFA (Multi-Factor Authentication) | 2FA, two-factor, multi-factor | Industry standard abbreviation; more accurate than "two-factor" which limits to exactly two factors |
| FortiAuthenticator | FortiAuth, Fortinet MFA | Official product name from Fortinet documentation |
| FortiToken | Fortinet token, MFA token | Specific product name for hardware/software tokens |
| Fortigate firewall | Fortigate FW, firewall, Fortinet firewall | Full product name for clarity; distinguishes from other firewalls |
| RADIUS authentication | RADIUS auth, Radius | Proper capitalization (RADIUS is an acronym); full term for clarity |
| LDAP/AD authentication | LDAP auth, Active Directory auth | Consistent format; AD often used with LDAP |
| Primary authentication | First-factor auth, primary auth | Clear terminology matching WALLIX documentation |
| Secondary authentication | Second-factor auth, secondary auth | Consistent with "primary authentication" terminology |

### API & Automation

| Use This | Not This | Rationale |
|----------|----------|-----------|
| REST API v3.12 | API v2, API v3, WALLIX API | Specifies both architecture (REST) and version (3.12) |
| API specification v3.12 | API spec, API version | Distinguishes spec version from endpoint URLs |
| Endpoint URL `/api/v2/` | API v2, v2 endpoint | Clarifies that v2 in URL path differs from spec version 3.12 |
| wabadmin CLI | wabadmin command, CLI tool, admin CLI | Official tool name with qualifier |
| REST API endpoint | API call, API endpoint, REST endpoint | Full technical term |
| API authentication token | API key, auth token, X-Auth-Token | Generic term; header name used in context |

### Networking & Infrastructure

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Network configuration | Network validation, network setup, networking | Neutral term covering all network-related activities |
| Port configuration | Port settings, port mapping | Consistent with "network configuration" |
| Firewall rules | Firewall config, FW rules | Standard security terminology |
| HAProxy load balancer | HAProxy, load balancer, LB | Full product name with type |
| Keepalived VRRP | Keepalived, VRRP failover | Specifies both tool and protocol |
| MariaDB replication | MySQL replication, database replication | Correct product name (MariaDB, not MySQL) |

### WALLIX Components

| Use This | Not This | Rationale |
|----------|----------|-----------|
| WALLIX Bastion | Bastion, WAB, WALLIX | Full product name; "Bastion" alone is ambiguous |
| Session Manager | session management, SM, session manager | Official component name; capitalized |
| Password Manager | password vault, PM, password manager | Official component name; matches WALLIX terminology |
| Access Manager | User Portal, access manager, AM | Official web interface name |
| WALLIX RDS | RDS Gateway, RDS, Remote Desktop Services | WALLIX-specific RDS component |
| wabengine service | WAB engine, bastion engine | Exact service name as appears in systemd |

### Session & Recording

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Session recording | session capture, recording, video recording | Official feature name |
| Session playback | session replay, playback, video playback | Matches WALLIX UI terminology |
| OCR (Optical Character Recognition) | text search, OCR search | Full term on first use, abbreviation thereafter |
| Session metadata | session data, metadata | Specific term for indexed session information |
| Active session | live session, current session, ongoing session | Consistent with WALLIX UI |
| Session history | past sessions, session logs, historical sessions | Matches UI navigation label |

### Credentials & Accounts

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Credential vault | password vault, vault, credential storage | Accurate term (stores keys too, not just passwords) |
| Password rotation | password change, automatic rotation, CPM | Industry standard term; avoids CyberArk-specific "CPM" |
| Credential checkout | password checkout, check-out, credential retrieval | Matches WALLIX workflow terminology |
| Account reconciliation | password reconciliation, account recovery | Broader than just passwords |
| Service account | privileged account, service acct | Distinguishes from interactive user accounts |
| Local account | target account, device account | Clarifies account exists on target, not in WALLIX |

### Authorization & Access Control

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Authorization policy | authorization, authz policy, access policy | Full term; distinguishes from authentication |
| User Group | user group, UserGroup, group | Capitalized; matches WALLIX object model |
| Target Group | target group, TargetGroup, account group | Capitalized; matches WALLIX object model |
| Domain | domain, safe, container | WALLIX-specific organizational unit |
| Approval workflow | approval, dual control, 4-eyes | Generic term covering all approval types |
| Just-in-time (JIT) access | JIT, temporary access, time-limited access | Industry standard abbreviation |

### Protocols & Services

| Use This | Not This | Rationale |
|----------|----------|-----------|
| RDP (Remote Desktop Protocol) | RDP, remote desktop, Remote Desktop | Standard abbreviation with full name on first use |
| SSH (Secure Shell) | SSH, secure shell | Standard abbreviation with full name on first use |
| HTTPS | https, HTTP/S, HTTP over TLS | Standard capitalization |
| Protocol service | service, protocol, connection type | Distinguishes WALLIX "service" object from OS services |
| Subprotocol | sub-protocol, protocol feature | WALLIX-specific term (e.g., SCP, SFTP under SSH) |

### High Availability & Clustering

| Use This | Not This | Rationale |
|----------|----------|-----------|
| High Availability (HA) | HA, high availability, HA cluster | Spell out on first use |
| Active-Active cluster | active-active, AA cluster, dual-active | Industry standard term with capitalization |
| Pacemaker/Corosync cluster | Pacemaker cluster, cluster manager | Specifies both components |
| Database replication | DB replication, MariaDB sync | Generic term applicable to concept |
| Failover | fail-over, fail over, switchover | Single word (industry standard) |
| Split-brain scenario | split brain, cluster split | Standard HA terminology |

### Compliance & Audit

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Audit trail | audit log, audit trail, audit history | Standard compliance terminology |
| Compliance framework | compliance standard, framework | Distinguishes framework from specific standards |
| ISO 27001 | ISO27001, ISO-27001 | Standard formatting with space |
| SOC 2 Type II | SOC2, SOC 2, SOC II | Standard formatting |
| NIS2 Directive | NIS2, NIS 2, Network and Information Security | Official EU directive name |
| Evidence collection | audit evidence, compliance evidence | Neutral term for compliance activities |

### Operations & Monitoring

| Use This | Not This | Rationale |
|----------|----------|-----------|
| System health check | health check, system check, diagnostic | Comprehensive term |
| Log aggregation | log collection, logging, centralized logging | Accurate technical term |
| SIEM integration | SIEM, syslog integration, log forwarding | Specifies integration type |
| Prometheus metrics | Prometheus, metrics, monitoring data | Specifies metrics system |
| Alert threshold | alert, threshold, monitoring threshold | Complete term |
| Runbook procedure | runbook, procedure, operational procedure | Standard DevOps terminology |

### Deployment & Installation

| Use This | Not This | Rationale |
|----------|----------|-----------|
| On-premises deployment | on-prem, on-premise, local deployment | Correct hyphenation and term |
| Bare metal server | physical server, bare metal, dedicated server | Industry standard term |
| Virtual machine (VM) | VM, virtual machine, guest | Spell out on first use |
| Multi-site deployment | multi-site, distributed deployment, geo-distributed | Matches repository architecture |
| LUKS disk encryption | LUKS, disk encryption, full-disk encryption | Specific technology name |
| Debian 12 (Bookworm) | Debian 12, Debian Bookworm | Version number with codename |

### Documentation Standards

| Use This | Not This | Rationale |
|----------|----------|-----------|
| Section 06 - Authentication | 06-authentication, section 6, Authentication section | Consistent numbering format (two digits) |
| `/home/user/file.conf` | ~/file.conf, ./file.conf, relative paths | Absolute paths for clarity |
| Code block with syntax highlighting | code snippet, command example | Specify markdown formatting |
| ASCII diagram | text diagram, ASCII art | Technical term for fixed-width diagrams |

---

### Application Guidelines

**For all 47 documentation sections:**

1. **First Use Rule**: Spell out abbreviations on first use in each document
   - Example: "Multi-Factor Authentication (MFA)" then "MFA" thereafter

2. **Consistency Within Documents**: Once a term is introduced, use it consistently
   - Don't alternate between "WALLIX Bastion" and "Bastion" in same section

3. **Code/CLI Exceptions**: Use exact technical names in code blocks
   - Systemd service: `wallix-bastion` (as-is)
   - Command: `wabadmin` (lowercase, no spaces)
   - Config file: `/etc/opt/wab/wabengine.conf` (exact path)

4. **UI References**: Match WALLIX UI labels exactly
   - UI shows "Target Groups" → use "Target Groups" when referencing UI
   - UI shows "Authorizations" → use "Authorizations"

5. **Version Specificity**: Always specify versions when relevant
   - "WALLIX Bastion 12.1.x" not "WALLIX Bastion 12"
   - "Debian 12 (Bookworm)" not "Debian"
   - "REST API v3.12" not "REST API"

6. **Cross-References**: Use consistent section naming
   - "[06 - Authentication](../06-authentication/README.md)"
   - Not "Section 6" or "the authentication section"

7. **Capitalization Rules**:
   - Product names: Capitalize (WALLIX Bastion, FortiAuthenticator)
   - Generic terms: Lowercase (firewall, load balancer, unless starting sentence)
   - WALLIX components: Capitalize (Session Manager, Password Manager)
   - Protocols: Uppercase abbreviations (SSH, RDP, HTTPS, LDAP)

8. **Avoid Vendor-Specific Terms** (unless in comparison contexts):
   - Use "credential vault" not "Safe" (CyberArk term)
   - Use "password rotation" not "CPM" (CyberArk term)
   - Use "approval workflow" not "dual control" (generic term preferred)

---

**Note**: These standards apply to all documentation sections (00-46) and should be used when creating new content or updating existing documentation. When updating a section, verify terminology consistency using this reference.

---

## CyberArk to WALLIX Cheat Sheet

```
+===============================================================================+
|                    CYBERARK > WALLIX CHEAT SHEET                              |
+===============================================================================+
|                                                                               |
|  "In CyberArk I would..."              "In WALLIX I..."                       |
|  =========================             ================                       |
|                                                                               |
|  Create a Safe                    >    Create a Domain                        |
|  Add account to Safe              >    Create Device + Account in Domain      |
|  Assign Safe member               >    Create Authorization                   |
|  Set Safe permissions             >    Configure Authorization settings       |
|  Connect via PSM                  >    Connect via Access Manager/native      |
|  View recording in PVWA           >    View in Sessions > History             |
|  Trigger CPM rotation             >    Trigger rotation via API/CLI           |
|  Check vault password             >    API: GET /api/accounts/{}/password     |
|  Create platform                  >    Create Device + configure Service      |
|  Enable Dual Control              >    Enable Approval Workflow               |
|  Check-out/Check-in               >    Checkout workflow (if enabled)         |
|  Add to group                     >    Add to User Group or Target Group      |
|  Configure LDAP                   >    Configuration > Authentication         |
|  View audit logs                  >    Audit > Logs or SIEM                   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON TASKS - QUICK COMPARISON                                              |
|  ===============================                                              |
|                                                                               |
|  Task: Grant user access to Linux root                                        |
|                                                                               |
|  CyberArk:                                                                    |
|  1. User added as Safe member to "Linux-Prod" Safe                            |
|  2. Permissions: Use, Retrieve (if needed)                                    |
|                                                                               |
|  WALLIX:                                                                      |
|  1. User in "Linux-Admins" User Group                                         |
|  2. Authorization: Linux-Admins > Linux-Prod-Root target group                |
|  3. Settings: Subprotocols, recording, time restrictions                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  Task: Connect to server via SSH                                              |
|                                                                               |
|  CyberArk:                                                                    |
|  PVWA > Accounts > Select > Connect > PSM-SSH                                 |
|  Or: RDP to PSM server, use connector                                         |
|                                                                               |
|  WALLIX:                                                                      |
|  Access Manager (web) > Targets > Select > Connect                            |
|  Or: ssh user@wallix (select target interactively)                            |
|  Or: ssh user:target_account:target@wallix (direct)                           |
|                                                                               |
+===============================================================================+
```

---

## Additional Resources

### Documentation Links

- **WALLIX Documentation Portal**: docs.wallix.com
- **WALLIX Support Portal**: support.wallix.com
- **WALLIX Training**: wallix.com/training
- **Community Forums**: community.wallix.com

### Useful External Resources

- **ANSSI PAM Guidelines**: www.ssi.gouv.fr
- **NIST SP 800-53**: csrc.nist.gov
- **CIS Benchmarks**: cisecurity.org

---

## See Also

**Quick Navigation:**
- [Cross-Reference Index](cross-reference-index.md) - Master topic index for all 48 sections

**Related Sections:**
- [31 - wabadmin Reference](../31-wabadmin-reference/README.md) - Complete CLI command reference
- [17 - API Reference](../17-api-reference/README.md) - REST API documentation

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [15 - Industrial Overview](../15-industrial-overview/README.md) for OT/industrial-specific documentation.

---

*Document Version: 1.0*
*Last Updated: January 2026*
