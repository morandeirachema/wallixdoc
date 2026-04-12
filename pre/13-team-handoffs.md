# 13 - Team Handoffs

## Documentation and Knowledge Transfer for Cross-Team Collaboration

This guide provides team-specific documentation for handoffs to Networking, SIEM, Observability, Identity, and Security teams.

> **Lab architecture summary**: Single WALLIX Bastion node (10.10.1.11, DMZ VLAN 110). HAProxy 2-node Active-Passive (VIP 10.10.1.100). FortiAuthenticator single node (10.10.1.50, Cyber VLAN 120). AD DC (10.10.1.60, Cyber VLAN 120). SIEM at 10.10.0.10 (Management). Monitoring at 10.10.0.20 (Management). Fortigate routes between DMZ, Cyber, and Targets VLANs.

---

## Handoff Overview

```
+===============================================================================+
|                           TEAM HANDOFF MATRIX                                 |
+===============================================================================+

  +------------------+     +------------------+     +------------------+
  |    NETWORKING    |     |       SIEM       |     |  OBSERVABILITY   |
  |      TEAM        |     |       TEAM       |     |      TEAM        |
  +------------------+     +------------------+     +------------------+
  | - VLANs          |     | - Log sources    |     | - Metrics        |
  | - Firewall       |     | - Parsers        |     | - Dashboards     |
  | - Load balance   |     | - Alerts         |     | - Alerts         |
  | - DNS            |     | - Reports        |     | - Runbooks       |
  +--------+---------+     +--------+---------+     +--------+---------+
           |                        |                        |
           +------------------------+------------------------+
                                    |
                          +---------+---------+
                          |      WALLIX Bastion       |
                          |    CORE TEAM      |
                          +---------+---------+
                                    |
           +------------------------+------------------------+
           |                        |                        |
  +--------+---------+     +--------+---------+     +--------+---------+
  |     IDENTITY     |     |     OT / ICS     |     |     SECURITY     |
  |       TEAM       |     |       TEAM       |     |       TEAM       |
  +------------------+     +------------------+     +------------------+
  | - AD groups      |     | - OT targets     |     | - Compliance     |
  | - MFA            |     | - Protocols      |     | - Audit          |
  | - SSO            |     | - Maintenance    |     | - Incidents      |
  | - Kerberos       |     | - Segmentation   |     | - Testing        |
  +------------------+     +------------------+     +------------------+

+===============================================================================+
```

---

## Handoff 1: Networking Team

### Network Architecture Summary

```
+===============================================================================+
|                     NETWORK DIAGRAM FOR NETWORKING TEAM                       |
+===============================================================================+
|                                                                               |
|  MANAGEMENT VLAN 100 (10.10.0.0/24)                                          |
|  +------------------+   +------------------+                                  |
|  | siem-lab         |   | monitor-lab      |                                  |
|  | 10.10.0.10       |   | 10.10.0.20       |                                  |
|  +------------------+   +------------------+                                  |
|                                                                               |
|  =================== FORTIGATE INTER-VLAN ROUTING ========================== |
|                                                                               |
|  DMZ VLAN 110 (10.10.1.x)                                                    |
|  +----------+  +----------+                                                   |
|  |haproxy-1 |  |haproxy-2 |  VIP: 10.10.1.100                               |
|  |10.10.1.5 |<>|10.10.1.6 |  Active-Passive (Keepalived)                     |
|  +----+-----+  +----+-----+                                                   |
|       +---------+                                                             |
|  +------------------+   +------------------+                                  |
|  | wallix-bastion   |   | wallix-rds       |                                  |
|  | 10.10.1.11       |   | 10.10.1.30       |                                  |
|  +------------------+   +------------------+                                  |
|                                                                               |
|  CYBER VLAN 120 (10.10.1.x)                                                  |
|  +------------------+   +------------------+                                  |
|  | fortiauth        |   | dc-lab (AD DC)   |                                  |
|  | 10.10.1.50       |   | 10.10.1.60       |                                  |
|  +------------------+   +------------------+                                  |
|                                                                               |
|  TARGETS VLAN 130 (10.10.2.0/24)                                             |
|  +-----------+  +-----------+  +-----------+  +-----------+                   |
|  |win-srv-01 |  |win-srv-02 |  |rhel10-srv |  |rhel9-srv  |                   |
|  |10.10.2.10 |  |10.10.2.11 |  |10.10.2.20 |  |10.10.2.21 |                   |
|  +-----------+  +-----------+  +-----------+  +-----------+                   |
|                                                                               |
+===============================================================================+
```

### Required Firewall Rules

| Source | Destination | Port | Protocol | Description |
|--------|-------------|------|----------|-------------|
| Users | VIP 10.10.1.100 | 443 | TCP | Web UI access |
| Users | VIP 10.10.1.100 | 22 | TCP | SSH proxy |
| Users | VIP 10.10.1.100 | 3389 | TCP | RDP proxy |
| haproxy-1/2 | wallix-bastion (10.10.1.11) | 443/22/3389 | TCP | Backend load balancing |
| haproxy-1 <-> haproxy-2 | VRRP | — | VRRP | Keepalived heartbeat |
| wallix-bastion (DMZ) | dc-lab (Cyber) | 636 | TCP | LDAPS — inter-VLAN |
| wallix-bastion (DMZ) | dc-lab (Cyber) | 389 | TCP | LDAP — inter-VLAN |
| wallix-bastion (DMZ) | dc-lab (Cyber) | 88 | TCP/UDP | Kerberos — inter-VLAN |
| wallix-bastion (DMZ) | fortiauth (Cyber) | 1812/1813 | UDP | RADIUS MFA — inter-VLAN |
| fortiauth (Cyber) | dc-lab (Cyber) | 389 | TCP | LDAP user sync — intra-VLAN |
| wallix-bastion | siem-lab (10.10.0.10) | 514/6514 | TCP | Syslog |
| monitor-lab (10.10.0.20) | wallix-bastion | 9100 | TCP | Node exporter |
| monitor-lab (10.10.0.20) | fortiauth | 9100 | TCP | Node exporter |
| monitor-lab (10.10.0.20) | dc-lab | 9182 | TCP | Windows exporter |
| wallix-bastion | 10.10.2.0/24 | 22 | TCP | SSH to targets — inter-VLAN |
| wallix-bastion | 10.10.2.0/24 | 3389 | TCP | RDP to targets — inter-VLAN |
| wallix-bastion | 10.10.2.0/24 | 5985/5986 | TCP | WinRM — inter-VLAN |

### DNS Records Required

```
; Forward zone: lab.local (hosted on dc-lab 10.10.1.60, Cyber VLAN)
siem-lab        A       10.10.0.10
monitor-lab     A       10.10.0.20
haproxy-1       A       10.10.1.5
haproxy-2       A       10.10.1.6
wallix          A       10.10.1.100     ; HAProxy VIP
wallix-bastion  A       10.10.1.11
wallix-rds      A       10.10.1.30
fortiauth       A       10.10.1.50
dc-lab          A       10.10.1.60
win-srv-01      A       10.10.2.10
win-srv-02      A       10.10.2.11
rhel10-srv      A       10.10.2.20
rhel9-srv       A       10.10.2.21
```

### HAProxy Configuration (lab — single Bastion backend)

```
; HAProxy lab configuration (single Bastion node backend)
; VIP: 10.10.1.100 (haproxy-1 MASTER / haproxy-2 BACKUP)
frontend wallix_https
    bind 10.10.1.100:443
    mode tcp
    default_backend wallix_https_backend

backend wallix_https_backend
    mode tcp
    option tcp-check
    server wallix-bastion 10.10.1.11:443 check inter 5s rise 2 fall 3

frontend wallix_ssh
    bind 10.10.1.100:22
    mode tcp
    default_backend wallix_ssh_backend

backend wallix_ssh_backend
    mode tcp
    server wallix-bastion 10.10.1.11:22 check inter 5s rise 2 fall 3
```

### Networking Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Network Admin | __________ | __________ | __________ |
| Firewall Admin | __________ | __________ | __________ |
| DNS Admin | __________ | __________ | __________ |

---

## Handoff 2: SIEM Team

### Log Sources

> **Lab**: SIEM is siem-lab (10.10.0.10, Management VLAN 100). Log sources are wallix-bastion (10.10.1.11, DMZ VLAN) and fortiauth (10.10.1.50, Cyber VLAN).

| Source | IP | Type | Protocol | Port | Format |
|--------|----|------|----------|------|--------|
| wallix-bastion | 10.10.1.11 | PAM Logs | Syslog/TLS | 6514 | CEF |
| fortiauth | 10.10.1.50 | MFA Logs | Syslog/UDP | 514 | Syslog |

### Log Categories

| Category | Description | Volume Estimate |
|----------|-------------|-----------------|
| Authentication | Login success/failure | ~500/day |
| Session | Session start/end | ~200/day |
| Admin | Configuration changes | ~20/day |
| Password | Checkout/rotation | ~50/day |
| System | Service events | ~100/day |

### CEF Field Mapping

```
CEF:0|WALLIX|WALLIX Bastion|12.1.x|<signature_id>|<name>|<severity>|<extensions>

Signature IDs:
100 - User Login Success
101 - User Login Failed
102 - User Logout
200 - Session Started
201 - Session Ended
202 - Session Command
300 - Configuration Changed
301 - User Created
302 - User Modified
400 - Password Checked Out
401 - Password Checked In
402 - Password Rotated

Extensions:
src=<source_ip>
suser=<username>
dhost=<target_host>
duser=<target_account>
outcome=<success|failure>
reason=<failure_reason>
duration=<session_duration>
protocol=<SSH|RDP|HTTP>
```

### Splunk Search Examples

```spl
# All WALLIX Bastion events
index=wallix sourcetype=syslog

# Failed logins in last 24h
index=wallix "authentication failed" earliest=-24h
| stats count by suser, src
| sort -count

# Sessions by user
index=wallix "session started" earliest=-24h
| stats count by suser, dhost, protocol
| sort -count

# Password checkouts
index=wallix "password checked out" earliest=-7d
| timechart count by suser

# Admin changes
index=wallix "configuration changed" earliest=-24h
| table _time, suser, name, reason
```

### Recommended Alerts

| Alert Name | Search | Threshold | Severity |
|------------|--------|-----------|----------|
| Multiple Failed Logins | `"authentication failed" \| stats count by suser \| where count > 5` | > 5 in 5m | High |
| After-Hours Session | `"session started" \| where date_hour < 6 OR date_hour > 22` | Any | Medium |
| Password Checkout Spike | `"password checked out" \| timechart span=1h count` | > 2x normal | Medium |
| Admin Config Change | `"configuration changed"` | Any | Low |
| Service Restart | `"service" "restart"` | Any | Low |

### Splunk Dashboard JSON

```json
{
  "title": "WALLIX Bastion Security Dashboard",
  "panels": [
    {
      "title": "Authentication Events (24h)",
      "search": "index=wallix authentication | timechart count by outcome"
    },
    {
      "title": "Top Failed Login Sources",
      "search": "index=wallix \"authentication failed\" | top 10 src"
    },
    {
      "title": "Active Sessions",
      "search": "index=wallix \"session started\" earliest=-1h | stats count"
    },
    {
      "title": "Session by Target",
      "search": "index=wallix \"session started\" | top 10 dhost"
    }
  ]
}
```

### SIEM Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| SIEM Admin | __________ | __________ | __________ |
| SOC Analyst | __________ | __________ | __________ |

---

## Handoff 3: Observability Team

### Metrics Endpoints

> **Lab**: Monitoring is monitor-lab (10.10.0.20, Management VLAN 100). Prometheus scrapes wallix-bastion (single node), fortiauth, dc-lab, haproxy nodes, and target hosts.

| Target | IP | Endpoint | Port | Exporter |
|--------|----|----------|------|----------|
| wallix-bastion | 10.10.1.11 | /metrics | 9100 | node_exporter |
| wallix-bastion | 10.10.1.11 | /metrics | 9104 | mysqld_exporter |
| fortiauth | 10.10.1.50 | /metrics | 9100 | node_exporter |
| dc-lab | 10.10.1.60 | /metrics | 9182 | windows_exporter |
| haproxy-1 | 10.10.1.5 | /metrics | 9101 | haproxy_exporter |
| haproxy-2 | 10.10.1.6 | /metrics | 9101 | haproxy_exporter |
| rhel10-srv | 10.10.2.20 | /metrics | 9100 | node_exporter |
| rhel9-srv | 10.10.2.21 | /metrics | 9100 | node_exporter |

### Key Metrics to Monitor

| Metric | Query | Threshold | Action |
|--------|-------|-----------|--------|
| Bastion Up | `up{job="wallix-bastion"}` | == 0 | Page on-call |
| CPU Usage | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | > 80% | Investigate |
| Memory | `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100` | > 85% | Investigate |
| Disk /var/wab | `(1 - node_filesystem_avail_bytes{mountpoint="/var/wab"} / node_filesystem_size_bytes) * 100` | > 80% | Clean recordings |
| MariaDB Up | `mysql_up` | == 0 | Page on-call |
| DB Connections | `mysql_global_status_threads_connected` | > 80 | Investigate |
| HAProxy Up | `up{job="haproxy"}` | == 0 | Check VRRP/VIP |

### Grafana Dashboard IDs

| Dashboard | ID | Purpose |
|-----------|---|---------|
| WALLIX Bastion Overview | 1001 | System health overview |
| MariaDB | 1002 | Database performance |
| HAProxy VIP | 1003 | HAProxy Active-Passive status |
| Session Metrics | 1004 | Session activity |

### Alert Rules

```yaml
# /etc/prometheus/rules/wallix.yml
groups:
  - name: wallix-critical
    rules:
      - alert: BastionNodeDown
        expr: up{job="wallix-bastion"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX Bastion node down (single node — immediate impact)"

      - alert: MariaDBDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: critical

  - name: wallix-warning
    rules:
      - alert: HighCPU
        expr: (100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle",job="wallix-bastion"}[5m])) * 100)) > 80
        for: 5m
        labels:
          severity: warning

      - alert: HighMemory
        expr: (1 - (node_memory_MemAvailable_bytes{job="wallix-bastion"} / node_memory_MemTotal_bytes{job="wallix-bastion"})) * 100 > 85
        for: 5m
        labels:
          severity: warning
```

### Runbook Links

| Alert | Runbook |
|-------|---------|
| BastionNodeDown | Restart wallix-bastion service; escalate if unresponsive |
| MariaDBDown | See "Database Recovery" — single node, no failover |
| HighCPU | Identify top processes, check for stuck sessions |
| HighMemory | Clear session cache, check for memory leaks |
| DiskSpaceLow | Archive old recordings, clean temp files |
| HAProxy VIP lost | Check keepalived on both haproxy nodes, verify VRRP |

### Observability Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| SRE Lead | __________ | __________ | __________ |
| On-Call | __________ | __________ | __________ |

---

## Handoff 4: Identity Team

### AD Integration Summary

> **Lab**: AD DC is dc-lab (10.10.1.60, Cyber VLAN 120). FortiAuthenticator is fortiauth (10.10.1.50, Cyber VLAN 120). WALLIX Bastion (10.10.1.11, DMZ VLAN 110) reaches both via Fortigate inter-VLAN routing.

| Setting | Value |
|---------|-------|
| Domain | LAB.LOCAL |
| DC | dc-lab.lab.local (10.10.1.60, Cyber VLAN) |
| Protocol | LDAPS (port 636) |
| Service Account | wallix-svc |
| Base DN | DC=lab,DC=local |
| User Search Base | OU=Users,OU=WALLIX Bastion,DC=lab,DC=local |

### AD Groups and Permissions

| AD Group | WALLIX Bastion Group | Permissions |
|----------|--------------|-------------|
| WALLIX Bastion-Admins | LDAP-Admins | Full administration |
| WALLIX Bastion-Operators | LDAP-Operators | View/operate, no config |
| WALLIX Bastion-Auditors | LDAP-Auditors | Audit access only |
| Linux-Admins | LDAP-Linux-Admins | Access to Linux targets (VLAN 130) |
| Windows-Admins | LDAP-Windows-Admins | Access to Windows targets (VLAN 130) |

### User Provisioning Process

```
1. Create user in AD under: OU=Users,OU=WALLIX Bastion,DC=lab,DC=local
2. Add to appropriate group(s):
   - WALLIX Bastion-Admins (for PAM administrators)
   - Linux-Admins (for rhel10-srv / rhel9-srv access)
   - Windows-Admins (for win-srv-01 / win-srv-02 access)
3. User syncs automatically on next login
4. WALLIX Bastion inherits group permissions

Deprovisioning:
1. Disable user in AD
2. Remove from all WALLIX Bastion groups
3. User loses access on next auth attempt
4. Active sessions remain until timeout
```

### MFA Configuration

```
MFA Provider: FortiAuthenticator 6.4+ (fortiauth, 10.10.1.50, Cyber VLAN 120)
Integration: RADIUS (UDP 1812/1813)
Token Type: TOTP only (FortiToken Mobile — no Push notifications)

Configuration in WALLIX Bastion:
- System > Authentication > RADIUS
- Server: 10.10.1.50 (Cyber VLAN, inter-VLAN via Fortigate)
- Port: 1812
- Required for: All privileged users
```

### SSO Configuration (If Applicable)

```
IdP: ____________
Protocol: SAML / OIDC

WALLIX Bastion SAML Settings:
- Entity ID: https://wallix.lab.local/saml
- ACS URL: https://wallix.lab.local/saml/acs
- Metadata: https://wallix.lab.local/saml/metadata
```

### Identity Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| AD Admin | __________ | __________ | __________ |
| IAM Lead | __________ | __________ | __________ |

---

## Handoff 5: Cyber VLAN Team

### Cyber VLAN Network Segment

> **Note**: The Cyber VLAN (120) and DMZ VLAN (110) share the 10.10.1.x address range but are logically separated by VLAN tag. Fortigate handles inter-VLAN routing between them.

| Host | IP | VLAN | Role |
|------|----|------|------|
| fortiauth | 10.10.1.50 | Cyber (120) | FortiAuthenticator 6.4+ — RADIUS/TOTP |
| dc-lab | 10.10.1.60 | Cyber (120) | Active Directory DC — DNS, LDAP, Kerberos |

### Inter-VLAN Connectivity Requirements

```
+===============================================================================+
|               CYBER VLAN INTER-VLAN ROUTING (via Fortigate)                   |
+===============================================================================+
|                                                                               |
|  DMZ VLAN 110                           Cyber VLAN 120                        |
|  +-----------------------+              +------------------+                  |
|  | wallix-bastion        |  LDAPS 636   | dc-lab           |                  |
|  | 10.10.1.11            |----------->  | 10.10.1.60       |                  |
|  |                       |  LDAP 389    |                  |                  |
|  |                       |----------->  +------------------+                  |
|  |                       |  Kerberos 88                                       |
|  |                       |----------->  +------------------+                  |
|  |                       |  RADIUS 1812 | fortiauth        |                  |
|  |                       |----------->  | 10.10.1.50       |                  |
|  +-----------------------+              |                  |                  |
|                                         +--------+---------+                  |
|                                                  |                            |
|                                          LDAP 389 (sync)                      |
|                                                  |                            |
|                                         +--------+---------+                  |
|                                         | dc-lab           |                  |
|                                         | 10.10.1.60       |                  |
|                                         +------------------+                  |
|                                                                               |
+===============================================================================+
```

### FortiAuthenticator Handoff Details

| Setting | Value |
|---------|-------|
| Host | fortiauth.lab.local (10.10.1.50) |
| VLAN | Cyber VLAN 120 |
| RADIUS Port | 1812/1813 |
| Token Type | TOTP only (FortiToken Mobile) — no Push |
| LDAP Sync Source | dc-lab (10.10.1.60) |
| RADIUS Clients | wallix-bastion (10.10.1.11) |

### Active Directory Handoff Details

| Setting | Value |
|---------|-------|
| Host | dc-lab.lab.local (10.10.1.60) |
| VLAN | Cyber VLAN 120 |
| DNS Server | 10.10.1.60 (all VMs use this) |
| Domain | LAB.LOCAL |
| LDAPS Port | 636 |
| Kerberos Realm | LAB.LOCAL |

### Cyber VLAN Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| FortiAuth Admin | __________ | __________ | __________ |
| AD Admin | __________ | __________ | __________ |

---

## Handoff 6: Security Team

### Compliance Requirements

| Standard | Requirement | WALLIX Bastion Feature |
|----------|-------------|----------------|
| ISO 27001 | Privileged access | RBAC, MFA |
| ISO 27001 | Audit trail | Session recording, SIEM integration |
| ISO 27001 | Secure credentials | Vault, automatic rotation |
| SOC 2 | Access logging | Audit logs, SIEM (siem-lab 10.10.0.10) |
| NIS2 | MFA for privileged accounts | FortiAuthenticator TOTP |

### Audit Log Location

| Log Type | Location | Retention |
|----------|----------|-----------|
| Authentication | /var/log/wabaudit/audit.log | 90 days |
| Session | /var/wab/recorded/ | 365 days |
| Admin | /var/log/wabengine/wabengine.log | 90 days |
| SIEM | siem-lab (10.10.0.10, Management VLAN) | Per policy |

### Security Assessment Checklist

```
[ ] Certificate validation
[ ] TLS 1.2+ enforcement
[ ] Password complexity policy
[ ] Session timeout configured
[ ] MFA enabled for admins
[ ] Audit logging enabled
[ ] SIEM integration working
[ ] Backup encryption verified
[ ] Recovery tested
[ ] Penetration test scheduled
```

### Incident Response

For security incidents involving WALLIX Bastion:

1. **Contain**: Disable affected accounts
2. **Investigate**: Review audit logs, session recordings
3. **Eradicate**: Remove malicious access
4. **Recover**: Restore from backup if needed
5. **Report**: Document and report per policy

### Security Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| CISO | __________ | __________ | __________ |
| Security Analyst | __________ | __________ | __________ |
| Incident Response | __________ | __________ | __________ |

---

## Master Contact List

| Team | Primary Contact | Email | Phone |
|------|-----------------|-------|-------|
| WALLIX Bastion Core | __________ | __________ | __________ |
| Networking | __________ | __________ | __________ |
| SIEM | __________ | __________ | __________ |
| Observability | __________ | __________ | __________ |
| Identity | __________ | __________ | __________ |
| Cyber VLAN (FortiAuth/AD) | __________ | __________ | __________ |
| Security | __________ | __________ | __________ |

---

## Handoff Acceptance Sign-Off

| Team | Representative | Date | Signature |
|------|----------------|------|-----------|
| Networking | __________ | __________ | __________ |
| SIEM | __________ | __________ | __________ |
| Observability | __________ | __________ | __________ |
| Identity | __________ | __________ | __________ |
| Cyber VLAN | __________ | __________ | __________ |
| Security | __________ | __________ | __________ |

---

Last updated: April 2026 | WALLIX Bastion 12.1.x | Lab: single node (10.10.1.11) | FortiAuthenticator 6.4+ (10.10.1.50) | AD DC (10.10.1.60)

---

<p align="center">
  <a href="./12-validation-testing.md">← Previous: Validation Testing</a> •
  <a href="./14-battery-tests.md">Next: Battery Tests →</a>
</p>
