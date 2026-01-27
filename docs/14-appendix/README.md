# 14 - Appendix

## Table of Contents

1. [Quick Reference Card](#quick-reference-card)
2. [CLI Commands Reference](#cli-commands-reference)
3. [API Quick Reference](#api-quick-reference)
4. [Port Reference](#port-reference)
5. [File Locations](#file-locations)
6. [Glossary](#glossary)
7. [CyberArk to WALLIX Cheat Sheet](#cyberark-to-wallix-cheat-sheet)

---

## Quick Reference Card

```
+==============================================================================+
|                    WALLIX BASTION QUICK REFERENCE                             |
+==============================================================================+
|                                                                               |
|  SERVICE MANAGEMENT                                                           |
|  ==================                                                           |
|                                                                               |
|  Start all services:        systemctl start wab*                             |
|  Stop all services:         systemctl stop wab*                              |
|  Restart all services:      systemctl restart wab*                           |
|  Check status:              waservices status                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  Main config:               /etc/opt/wab/wabengine.conf                      |
|  Validate config:           waconfig --check                                 |
|  Apply config:              waconfig --reload                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  LOGS                                                                         |
|  ====                                                                         |
|                                                                               |
|  Main log:                  /var/log/wabengine/wabengine.log                 |
|  Audit log:                 /var/log/wabaudit/audit.log                      |
|  Session log:               /var/log/wabsessions/sessions.log                |
|  Tail all logs:             tail -f /var/log/wab*/*.log                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DATABASE                                                                     |
|  ========                                                                     |
|                                                                               |
|  Connect:                   psql -U wabadmin wabdb                           |
|  Backup:                    pg_dump -U wabadmin wabdb > backup.sql           |
|  Check size:                du -sh /var/lib/postgresql/                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  RECORDINGS                                                                   |
|  ==========                                                                   |
|                                                                               |
|  Storage location:          /var/wab/recorded/                               |
|  Check disk usage:          df -h /var/wab/recorded                          |
|  Count recordings:          find /var/wab/recorded -name "*.wab" | wc -l     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WEB INTERFACE                                                                |
|  =============                                                                |
|                                                                               |
|  Admin UI:                  https://bastion.company.com/admin                |
|  User Portal:               https://bastion.company.com/                     |
|  API Docs:                  https://bastion.company.com/api/docs             |
|                                                                               |
+==============================================================================+
```

---

## CLI Commands Reference

```
+==============================================================================+
|                    CLI COMMANDS REFERENCE                                     |
+==============================================================================+
|                                                                               |
|  SYSTEM COMMANDS                                                              |
|  ===============                                                              |
|                                                                               |
|  waservices                                                                   |
|  +-- status         Show all service status                                  |
|  +-- start          Start all services                                       |
|  +-- stop           Stop all services                                        |
|  +-- restart        Restart all services                                     |
|                                                                               |
|  waconfig                                                                     |
|  +-- --check        Validate configuration                                   |
|  +-- --reload       Reload configuration                                     |
|  +-- --export       Export configuration                                     |
|                                                                               |
|  wabdiag                                                                      |
|  +-- --quick        Quick diagnostic check                                   |
|  +-- --full         Full system diagnostic                                   |
|  +-- --network      Network connectivity check                               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USER COMMANDS                                                                |
|  =============                                                                |
|                                                                               |
|  wabuser                                                                      |
|  +-- list           List all users                                           |
|  +-- add            Add new user                                             |
|  +-- delete         Delete user                                              |
|  +-- passwd         Change user password                                     |
|  +-- lock/unlock    Lock or unlock user                                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DEVICE/ACCOUNT COMMANDS                                                      |
|  =======================                                                      |
|                                                                               |
|  wabdevice                                                                    |
|  +-- list           List all devices                                         |
|  +-- add            Add new device                                           |
|  +-- delete         Delete device                                            |
|                                                                               |
|  wabaccount                                                                   |
|  +-- list           List all accounts                                        |
|  +-- add            Add new account                                          |
|  +-- passwd         Show/change account password                             |
|  +-- rotate         Trigger password rotation                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SESSION COMMANDS                                                             |
|  ================                                                             |
|                                                                               |
|  wabsession                                                                   |
|  +-- list           List active sessions                                     |
|  +-- kill           Terminate session                                        |
|  +-- history        Show session history                                     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  BACKUP COMMANDS                                                              |
|  ===============                                                              |
|                                                                               |
|  wabbackup                                                                    |
|  +-- create         Create full backup                                       |
|  +-- restore        Restore from backup                                      |
|  +-- list           List available backups                                   |
|                                                                               |
+==============================================================================+
```

---

## API Quick Reference

```
+==============================================================================+
|                    API QUICK REFERENCE                                        |
+==============================================================================+
|                                                                               |
|  AUTHENTICATION                                                               |
|  ==============                                                               |
|                                                                               |
|  POST /api/auth/login                                                         |
|  Body: {"username": "admin", "password": "secret"}                           |
|                                                                               |
|  Or use header: X-Auth-Token: your-api-key                                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DEVICES                                                                      |
|  =======                                                                      |
|                                                                               |
|  GET    /api/devices                    List all devices                     |
|  GET    /api/devices/{name}             Get device details                   |
|  POST   /api/devices                    Create device                        |
|  PUT    /api/devices/{name}             Update device                        |
|  DELETE /api/devices/{name}             Delete device                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ACCOUNTS                                                                     |
|  ========                                                                     |
|                                                                               |
|  GET    /api/accounts                   List all accounts                    |
|  GET    /api/accounts/{name}            Get account details                  |
|  POST   /api/accounts                   Create account                       |
|  PUT    /api/accounts/{name}            Update account                       |
|  DELETE /api/accounts/{name}            Delete account                       |
|  GET    /api/accounts/{name}/password   Get password                         |
|  POST   /api/accounts/{name}/password/change   Rotate password              |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SESSIONS                                                                     |
|  ========                                                                     |
|                                                                               |
|  GET    /api/sessions/current           List active sessions                 |
|  DELETE /api/sessions/current/{id}      Kill session                         |
|  GET    /api/sessions/history           Session history                      |
|  GET    /api/sessions/{id}/recording    Get recording                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USERS & GROUPS                                                               |
|  =============                                                                |
|                                                                               |
|  GET    /api/users                      List users                           |
|  GET    /api/usergroups                 List user groups                     |
|  GET    /api/targetgroups               List target groups                   |
|  GET    /api/authorizations             List authorizations                  |
|                                                                               |
+==============================================================================+
```

---

## Port Reference

```
+==============================================================================+
|                    PORT REFERENCE                                             |
+==============================================================================+
|                                                                               |
|  INBOUND TO WALLIX BASTION                                                    |
|  =========================                                                    |
|                                                                               |
|  Port    Protocol   Source        Purpose                                    |
|  ----    --------   ------        -------                                    |
|  443     TCP        Users         Web UI, API, HTML5 sessions                |
|  22      TCP        Users         SSH proxy                                  |
|  3389    TCP        Users         RDP proxy                                  |
|  5900    TCP        Users         VNC proxy                                  |
|  23      TCP        Users         Telnet proxy (if needed)                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  OUTBOUND FROM WALLIX BASTION                                                 |
|  ===========================                                                  |
|                                                                               |
|  Port    Protocol   Destination   Purpose                                    |
|  ----    --------   -----------   -------                                    |
|  22      TCP        Targets       SSH to targets                             |
|  3389    TCP        Targets       RDP to targets                             |
|  5900    TCP        Targets       VNC to targets                             |
|  23      TCP        Targets       Telnet to targets                          |
|  389     TCP        LDAP          LDAP authentication                        |
|  636     TCP        LDAP          LDAPS authentication                       |
|  88      TCP/UDP    KDC           Kerberos authentication                    |
|  1812    UDP        RADIUS        RADIUS/MFA                                 |
|  514     UDP        SIEM          Syslog                                     |
|  6514    TCP        SIEM          Syslog over TLS                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  INTERNAL (Cluster)                                                           |
|  ==================                                                           |
|                                                                               |
|  Port    Protocol   Purpose                                                  |
|  ----    --------   -------                                                  |
|  5432    TCP        PostgreSQL replication                                   |
|  Various TCP        Cluster communication                                    |
|                                                                               |
+==============================================================================+
```

---

## File Locations

```
+==============================================================================+
|                    FILE LOCATIONS                                             |
+==============================================================================+
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  /etc/opt/wab/                       Main configuration directory            |
|  +-- wabengine.conf                  Engine configuration                    |
|  +-- wabproxy.conf                   Proxy configuration                     |
|  +-- wabpassword.conf                Password manager config                 |
|                                                                               |
|  /etc/opt/wab/ssl/                   SSL certificates                        |
|  +-- server.crt                      Server certificate                      |
|  +-- server.key                      Server private key                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  LOGS                                                                         |
|  ====                                                                         |
|                                                                               |
|  /var/log/wabengine/                 Application logs                        |
|  /var/log/wabaudit/                  Audit logs                              |
|  /var/log/wabsessions/               Session logs                            |
|  /var/log/postgresql/                Database logs                           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DATA                                                                         |
|  ====                                                                         |
|                                                                               |
|  /var/wab/recorded/                  Session recordings                      |
|  /var/lib/postgresql/                Database data                           |
|  /var/opt/wab/                       Variable application data               |
|  /var/opt/wab/keys/                  Encryption keys                         |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  BINARIES                                                                     |
|  ========                                                                     |
|                                                                               |
|  /opt/wab/bin/                       WALLIX binaries                         |
|  /opt/wab/lib/                       WALLIX libraries                        |
|                                                                               |
+==============================================================================+
```

---

## Glossary

```
+==============================================================================+
|                    GLOSSARY                                                   |
+==============================================================================+
|                                                                               |
|  Term                 Definition                                              |
|  ----                 ----------                                              |
|                                                                               |
|  Account              Privileged credential (username + password/key)        |
|  Authorization        Access policy linking user group to target group       |
|  Bastion              Core WALLIX PAM appliance/server                       |
|  Checkout             Process of requesting credential access                |
|  Device               Target system managed by WALLIX                        |
|  Domain               Logical container for organizing devices               |
|  Injection            Transparent credential insertion into session          |
|  OCR                  Optical Character Recognition (for RDP search)         |
|  Primary Auth         First factor authentication (password, AD)             |
|  Proxy                Network intermediary handling session traffic          |
|  Recording            Captured session video/text for audit                  |
|  Reconciliation       Process to recover from password sync issues           |
|  Rotation             Automatic password change process                      |
|  Service              Protocol definition on a device (SSH, RDP, etc.)       |
|  Session              Active connection between user and target              |
|  Shadow               Real-time session viewing capability                   |
|  Subprotocol          Sub-feature of protocol (SCP, SFTP for SSH)           |
|  Target               System user connects to through WALLIX                 |
|  Target Group         Collection of accounts for authorization               |
|  User Group           Collection of users for authorization                  |
|  Vault                Encrypted credential storage                           |
|  4-Eyes               Dual control requiring second person                   |
|                                                                               |
+==============================================================================+
```

---

## CyberArk to WALLIX Cheat Sheet

```
+==============================================================================+
|                    CYBERARK > WALLIX CHEAT SHEET                              |
+==============================================================================+
|                                                                               |
|  "In CyberArk I would..."              "In WALLIX I..."                      |
|  =========================             ================                      |
|                                                                               |
|  Create a Safe                    >    Create a Domain                       |
|  Add account to Safe              >    Create Device + Account in Domain     |
|  Assign Safe member               >    Create Authorization                  |
|  Set Safe permissions             >    Configure Authorization settings      |
|  Connect via PSM                  >    Connect via Access Manager/native     |
|  View recording in PVWA           >    View in Sessions > History            |
|  Trigger CPM rotation             >    Trigger rotation via API/CLI          |
|  Check vault password             >    API: GET /api/accounts/{}/password    |
|  Create platform                  >    Create Device + configure Service     |
|  Enable Dual Control              >    Enable Approval Workflow              |
|  Check-out/Check-in               >    Checkout workflow (if enabled)        |
|  Add to group                     >    Add to User Group or Target Group     |
|  Configure LDAP                   >    Configuration > Authentication        |
|  View audit logs                  >    Audit > Logs or SIEM                  |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  COMMON TASKS - QUICK COMPARISON                                              |
|  ===============================                                              |
|                                                                               |
|  Task: Grant user access to Linux root                                       |
|                                                                               |
|  CyberArk:                                                                    |
|  1. User added as Safe member to "Linux-Prod" Safe                          |
|  2. Permissions: Use, Retrieve (if needed)                                   |
|                                                                               |
|  WALLIX:                                                                      |
|  1. User in "Linux-Admins" User Group                                        |
|  2. Authorization: Linux-Admins > Linux-Prod-Root target group              |
|  3. Settings: Subprotocols, recording, time restrictions                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  Task: Connect to server via SSH                                             |
|                                                                               |
|  CyberArk:                                                                    |
|  PVWA > Accounts > Select > Connect > PSM-SSH                               |
|  Or: RDP to PSM server, use connector                                        |
|                                                                               |
|  WALLIX:                                                                      |
|  Access Manager (web) > Targets > Select > Connect                          |
|  Or: ssh user@wallix (select target interactively)                          |
|  Or: ssh user:target_account:target@wallix (direct)                         |
|                                                                               |
+==============================================================================+
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

**End of WALLIX PAM Professional Guide**

*Document Version: 1.0*
*Last Updated: 2024*
