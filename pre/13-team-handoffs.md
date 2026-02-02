# 10 - Team Handoffs

## Documentation and Knowledge Transfer for Cross-Team Collaboration

This guide provides team-specific documentation for handoffs to Networking, SIEM, Observability, Identity, and OT teams.

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

  MANAGEMENT VLAN (10.10.1.0/24)              IT-TEST VLAN (10.10.2.0/24)
  ==============================              ============================

  +------------------+                        +------------------+
  |  dc-lab          |                        |  linux-test      |
  |  10.10.1.10      |                        |  10.10.2.10      |
  +------------------+                        +------------------+

  +------------------+  +------------------+  +------------------+
  |  wallix-node1    |  |  wallix-node2    |  |  windows-test    |
  |  10.10.1.11      |  |  10.10.1.12      |  |  10.10.2.20      |
  +------------------+  +------------------+  +------------------+
          \                     /             +------------------+
           \                   /              |  network-test    |
            \  VIP: 10.10.1.100               |  10.10.2.30      |
             +---------------+                +------------------+

  +------------------+  +------------------+
  |  siem-lab        |  |  monitoring-lab  |  OT-TEST VLAN (10.10.3.0/24)
  |  10.10.1.50      |  |  10.10.1.60      |  ============================
  +------------------+  +------------------+
                                              +------------------+
                                              |  plc-sim         |
                                              |  10.10.3.10      |
                                              +------------------+

+===============================================================================+
```

### Required Firewall Rules

| Source | Destination | Port | Protocol | Description |
|--------|-------------|------|----------|-------------|
| Users | VIP 10.10.1.100 | 443 | TCP | Web UI access |
| Users | VIP 10.10.1.100 | 22 | TCP | SSH proxy |
| Users | VIP 10.10.1.100 | 3389 | TCP | RDP proxy |
| wallix-node1/2 | dc-lab | 636 | TCP | LDAPS |
| wallix-node1/2 | dc-lab | 88 | TCP/UDP | Kerberos |
| wallix-node1/2 | dc-lab | 389 | TCP | LDAP |
| wallix-node1/2 | dc-lab | 53 | TCP/UDP | DNS |
| wallix-node1 | wallix-node2 | 3306/3307 | TCP | MariaDB replication |
| wallix-node1 | wallix-node2 | 2224 | TCP | Pacemaker |
| wallix-node1 | wallix-node2 | 5405 | UDP | Corosync |
| wallix-node1/2 | siem-lab | 514 | TCP | Syslog |
| wallix-node1/2 | siem-lab | 6514 | TCP | Syslog TLS |
| monitoring-lab | wallix-node1/2 | 9100 | TCP | Node exporter |
| monitoring-lab | wallix-node1/2 | 9104 | TCP | MariaDB exporter |
| wallix-node1/2 | 10.10.2.0/24 | 22 | TCP | SSH to targets |
| wallix-node1/2 | 10.10.2.0/24 | 3389 | TCP | RDP to targets |
| wallix-node1/2 | 10.10.3.0/24 | 22 | TCP | SSH to OT targets |
| wallix-node1/2 | 10.10.3.0/24 | 502 | TCP | Modbus to OT |

### DNS Records Required

```
; Forward zone: lab.local
dc-lab          A       10.10.1.10
wallix-node1    A       10.10.1.11
wallix-node2    A       10.10.1.12
wallix          A       10.10.1.100     ; VIP
siem-lab        A       10.10.1.50
monitoring-lab  A       10.10.1.60
linux-test      A       10.10.2.10
windows-test    A       10.10.2.20
network-test    A       10.10.2.30
plc-sim         A       10.10.3.10

; Reverse zones
10.1.10.10.in-addr.arpa.    PTR     dc-lab.lab.local.
11.1.10.10.in-addr.arpa.    PTR     wallix-node1.lab.local.
12.1.10.10.in-addr.arpa.    PTR     wallix-node2.lab.local.
```

### Load Balancer Configuration (If Required)

```
; HAProxy configuration for production
frontend wallix_https
    bind *:443
    mode tcp
    default_backend wallix_nodes

backend wallix_nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server wallix-node1 10.10.1.11:443 check
    server wallix-node2 10.10.1.12:443 check backup

frontend wallix_ssh
    bind *:22
    mode tcp
    default_backend wallix_ssh_nodes

backend wallix_ssh_nodes
    mode tcp
    balance roundrobin
    server wallix-node1 10.10.1.11:22 check
    server wallix-node2 10.10.1.12:22 check backup
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

| Source | Type | Protocol | Port | Format |
|--------|------|----------|------|--------|
| wallix-node1 | PAM Logs | Syslog/TLS | 6514 | CEF |
| wallix-node2 | PAM Logs | Syslog/TLS | 6514 | CEF |

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
CEF:0|WALLIX|WALLIX Bastion|12.1|<signature_id>|<name>|<severity>|<extensions>

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

| Target | Endpoint | Port | Exporter |
|--------|----------|------|----------|
| wallix-node1 | /metrics | 9100 | node_exporter |
| wallix-node1 | /metrics | 9104 | mysqld_exporter |
| wallix-node2 | /metrics | 9100 | node_exporter |
| wallix-node2 | /metrics | 9104 | mysqld_exporter |
| dc-lab | /metrics | 9182 | windows_exporter |

### Key Metrics to Monitor

| Metric | Query | Threshold | Action |
|--------|-------|-----------|--------|
| Node Up | `up{job="wallix"}` | < 2 | Page on-call |
| CPU Usage | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | > 80% | Investigate |
| Memory | `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100` | > 85% | Investigate |
| Disk /var/wab | `(1 - node_filesystem_avail_bytes{mountpoint="/var/wab"} / node_filesystem_size_bytes) * 100` | > 80% | Clean recordings |
| MariaDB Up | `mysql_up` | 0 | Page on-call |
| Replication Lag | `mysql_slave_status_seconds_behind_master` | > 60s | Investigate |
| Connections | `mysql_global_status_threads_connected` | > 80 | Investigate |

### Grafana Dashboard IDs

| Dashboard | ID | Purpose |
|-----------|---|---------|
| WALLIX Bastion Overview | 1001 | System health overview |
| MariaDB | 1002 | Database performance |
| HA Cluster | 1003 | Cluster status |
| Session Metrics | 1004 | Session activity |

### Alert Rules

```yaml
# /etc/prometheus/rules/wallix.yml
groups:
  - name: wallix-critical
    rules:
      - alert: WALLIX BastionNodeDown
        expr: up{job="wallix"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX Bastion node down"

      - alert: MariaDBDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: critical

  - name: wallix-warning
    rules:
      - alert: HighCPU
        expr: (100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle",job="wallix"}[5m])) * 100)) > 80
        for: 5m
        labels:
          severity: warning

      - alert: HighMemory
        expr: (1 - (node_memory_MemAvailable_bytes{job="wallix"} / node_memory_MemTotal_bytes{job="wallix"})) * 100 > 85
        for: 5m
        labels:
          severity: warning
```

### Runbook Links

| Alert | Runbook |
|-------|---------|
| WALLIX BastionNodeDown | See "HA Failover Procedure" |
| MariaDBDown | See "Database Recovery" |
| HighCPU | Identify top processes, check for stuck sessions |
| HighMemory | Clear session cache, check for memory leaks |
| DiskSpaceLow | Archive old recordings, clean temp files |
| ReplicationLag | Check network, restart replica if needed |

### Observability Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| SRE Lead | __________ | __________ | __________ |
| On-Call | __________ | __________ | __________ |

---

## Handoff 4: Identity Team

### AD Integration Summary

| Setting | Value |
|---------|-------|
| Domain | LAB.LOCAL |
| DC | dc-lab.lab.local |
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
| Linux-Admins | LDAP-Linux-Admins | Access to Linux targets |
| Windows-Admins | LDAP-Windows-Admins | Access to Windows targets |
| Network-Admins | LDAP-Network-Admins | Access to network devices |
| OT-Engineers | LDAP-OT-Engineers | Access to OT targets |

### User Provisioning Process

```
1. Create user in AD under: OU=Users,OU=WALLIX Bastion,DC=lab,DC=local
2. Add to appropriate group(s):
   - WALLIX Bastion-Admins (for PAM administrators)
   - Linux-Admins (for Linux access)
   - Windows-Admins (for Windows access)
   - OT-Engineers (for OT access)
3. User syncs automatically on next login
4. WALLIX Bastion inherits group permissions

Deprovisioning:
1. Disable user in AD
2. Remove from all WALLIX Bastion groups
3. User loses access on next auth attempt
4. Active sessions remain until timeout
```

### MFA Configuration (If Applicable)

```
MFA Provider: ____________
Integration: RADIUS / TOTP / FIDO2

Configuration in WALLIX Bastion:
- System > Authentication > MFA
- Provider: [configured provider]
- Required for: All users / Admin only
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

## Handoff 5: OT / ICS Team

### OT Network Segment

| VLAN | Subnet | Purpose |
|------|--------|---------|
| OT-Test | 10.10.3.0/24 | OT test devices |

### OT Targets

| Device | IP | Type | Protocol | Account |
|--------|---|------|----------|---------|
| plc-sim | 10.10.3.10 | PLC Simulator | Modbus/SSH | root |

### Access Patterns for OT

```
+===============================================================================+
|                        OT ACCESS THROUGH WALLIX Bastion                               |
+===============================================================================+

  OT Engineer                  WALLIX Bastion                       PLC/HMI
  ===========                  ======                       =======

  1. Engineer authenticates to WALLIX Bastion (MFA)
  2. Requests session to OT target
  3. Approval workflow (if required)
  4. WALLIX Bastion creates tunneled connection
  5. Session recorded (video + commands)
  6. Engineer accesses OT device
  7. Session ends, recording archived

  +------------+            +------------+            +------------+
  |  OT Eng    |    SSH     |   WALLIX Bastion   |   Tunnel   |  PLC-SIM   |
  |    MFA     | ---------> |   Proxy    | ---------> |   Modbus   |
  +------------+            +------------+            +------------+
                                  |
                             Recording
                              Storage

+===============================================================================+
```

### Modbus Access via SSH Tunnel

```bash
# Engineer connects to WALLIX Bastion
ssh ot-engineer@wallix.lab.local

# Select: plc-sim / Modbus Tunnel

# This creates local port forward:
# localhost:502 -> plc-sim:502

# Then use Modbus client locally
modbus-cli localhost:502
```

### OT Session Recording

- All sessions to OT targets recorded
- Video capture for graphical sessions
- Command logging for CLI sessions
- Session approval may be required
- Recordings retained per policy

### Emergency Access Procedure

```
For emergency OT access when WALLIX Bastion is unavailable:

1. Contact OT Lead and Security
2. Use break-glass credentials stored in:
   [Location: ____________]
3. Log all access manually
4. Report to security within 24h
5. Rotate credentials after use
```

### OT Team Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| OT Lead | __________ | __________ | __________ |
| ICS Engineer | __________ | __________ | __________ |
| Plant Manager | __________ | __________ | __________ |

---

## Handoff 6: Security Team

### Compliance Requirements

| Standard | Requirement | WALLIX Bastion Feature |
|----------|-------------|----------------|
| IEC 62443 | Access control | RBAC, MFA |
| IEC 62443 | Audit trail | Session recording |
| IEC 62443 | Secure credentials | Vault, rotation |
| SOC 2 | Access logging | Audit logs, SIEM |
| ISO 27001 | Privileged access | PAM controls |

### Audit Log Location

| Log Type | Location | Retention |
|----------|----------|-----------|
| Authentication | /var/log/wabaudit/audit.log | 90 days |
| Session | /var/wab/recorded/ | 365 days |
| Admin | /var/log/wabengine/wabengine.log | 90 days |
| SIEM | siem-lab.lab.local | Per policy |

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
| OT/ICS | __________ | __________ | __________ |
| Security | __________ | __________ | __________ |

---

## Handoff Acceptance Sign-Off

| Team | Representative | Date | Signature |
|------|----------------|------|-----------|
| Networking | __________ | __________ | __________ |
| SIEM | __________ | __________ | __________ |
| Observability | __________ | __________ | __________ |
| Identity | __________ | __________ | __________ |
| OT/ICS | __________ | __________ | __________ |
| Security | __________ | __________ | __________ |

---

<p align="center">
  <a href="./12-validation-testing.md">← Previous: Validation Testing</a> •
  <a href="./14-battery-tests.md">Next: Battery Tests →</a>
</p>
