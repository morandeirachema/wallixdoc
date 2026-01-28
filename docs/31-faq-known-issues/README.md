# Frequently Asked Questions & Known Issues

This section provides answers to common questions and documents known limitations of WALLIX Bastion 12.x.

---

## Table of Contents

1. [End-User FAQs](#end-user-faqs)
2. [Administrator FAQs](#administrator-faqs)
3. [Integration FAQs](#integration-faqs)
4. [Performance FAQs](#performance-faqs)
5. [Licensing FAQs](#licensing-faqs)
6. [Known Issues](#known-issues)
7. [Known Limitations](#known-limitations)
8. [Compatibility Matrix](#compatibility-matrix)
9. [Common Mistakes](#common-mistakes)

---

## End-User FAQs

### Access & Authentication

**Q: Why can't I see any targets in my portal?**

A: This typically occurs because:
1. No authorizations have been assigned to your user or groups
2. Your authorization has a time window that doesn't include the current time
3. Your authorization requires approval that hasn't been granted
4. LDAP/AD group sync hasn't completed yet

**Resolution:** Contact your PAM administrator to verify your authorizations.

---

**Q: Why does my session fail with "Authorization denied"?**

A: Check the following:
1. Verify the target is included in your authorized target group
2. Check if approval is required and has been granted
3. Verify the time window allows access at this time
4. Ensure your authorization hasn't been disabled or expired

---

**Q: How do I request access to a target I can't see?**

A: Depending on your organization's policy:
1. Submit an access request via the WALLIX portal (if self-service enabled)
2. Contact your manager to request authorization
3. Open a ticket with your IT helpdesk
4. For emergency access, contact the PAM administrator directly

---

**Q: My session is very slow. What can I do?**

A: Try these steps:
1. **RDP Sessions:** Reduce color depth and disable visual effects
2. **SSH Sessions:** Check network latency to the Bastion
3. **All Sessions:** Verify your local internet connection
4. If persistent, report to your administrator with session ID

---

**Q: Can I copy/paste into my session?**

A: Copy/paste capabilities depend on configuration:
- **RDP:** Clipboard may be disabled by policy. Contact your administrator.
- **SSH:** Copy/paste typically works but may require specific key combinations
- **Web Sessions:** Use browser copy/paste functionality

---

**Q: How do I transfer files through WALLIX?**

A: File transfer methods:
- **RDP:** If enabled, use clipboard or drive redirection
- **SSH/SFTP:** Use the SFTP subsystem if authorized
- **SCP:** If enabled, use standard SCP commands through the Bastion
- **Note:** File transfers may be logged and recorded

---

**Q: Why was my session disconnected unexpectedly?**

A: Common causes:
1. **Idle timeout:** Sessions may disconnect after inactivity
2. **Maximum duration:** Sessions may have a time limit
3. **Administrator action:** An admin may have terminated the session
4. **Network issues:** Check your local connection
5. **Target unavailable:** The target system may have become unreachable

---

**Q: How do I view my session history?**

A: To view your session history:
1. Log into the WALLIX portal
2. Navigate to "My Sessions" or "Session History"
3. You can see connection times, durations, and targets
4. Note: You can only view your own sessions

---

**Q: I lost my MFA device. What do I do?**

A: Follow your organization's MFA recovery procedure:
1. Contact your PAM administrator or IT helpdesk
2. You may need to verify your identity through alternative means
3. Administrator can reset your MFA and you'll re-enroll
4. Consider enrolling a backup MFA method once recovered

---

**Q: Can I access WALLIX from my mobile device?**

A: Mobile access depends on configuration:
- **HTML5 Gateway:** Works on modern mobile browsers
- **Native clients:** May work with VPN access
- **Note:** Mobile access may be restricted by policy

---

### Session Features

**Q: Are my sessions being recorded?**

A: Session recording depends on policy configuration:
- Recording is typically enabled for privileged access
- You'll usually see an indicator when recording is active
- Recordings are used for audit and compliance purposes
- Contact your administrator for specific policy details

---

**Q: Can I reconnect to a disconnected session?**

A: Session reconnection depends on:
- Whether the session is still active on the target
- Your authorization still being valid
- Session timeout settings
- Some sessions may be resumable; others will start fresh

---

**Q: What keyboard shortcuts work in sessions?**

A: Common shortcuts:

| Action | RDP Session | SSH Session |
|--------|-------------|-------------|
| Copy | Ctrl+C | Ctrl+Shift+C |
| Paste | Ctrl+V | Ctrl+Shift+V |
| Disconnect | Varies | `exit` or Ctrl+D |
| Full screen | Varies by client | N/A |

---

## Administrator FAQs

### User Management

**Q: How do I grant emergency access to a user?**

A: For emergency access:
```bash
# Create temporary authorization
wabadmin authorization add \
  --user emergency_user \
  --target-group critical_systems \
  --duration 4h \
  --approval-required false \
  --comment "Emergency access: Incident #12345"

# After emergency, revoke
wabadmin authorization remove <authorization_id>
```

---

**Q: Why aren't LDAP/AD users syncing?**

A: Check the following:
1. **Connectivity:** Verify network access to LDAP/AD server
2. **Credentials:** Confirm bind DN and password are correct
3. **Search base:** Verify the search base DN includes target users
4. **Filter:** Check that LDAP filter matches expected users
5. **Sync schedule:** Verify sync is enabled and scheduled

```bash
# Test LDAP connectivity
wabadmin ldap-test --domain <domain_name>

# Force sync
wabadmin ldap-sync --run --verbose

# Check sync status
wabadmin ldap-sync --status
```

---

**Q: How do I handle a compromised user account?**

A: Immediate actions:
```bash
# 1. Disable the user account
wabadmin user disable <username>

# 2. Terminate all active sessions
wabadmin sessions --filter "user=<username>" --kill-all

# 3. Review recent activity
wabadmin audit --filter "user=<username>" --last 7d

# 4. Rotate any passwords the user may have accessed
wabadmin accounts --accessed-by <username> --last 7d

# 5. Reset the user's authentication
wabadmin user reset-auth <username>
```

---

**Q: How do I bulk import users?**

A: Use CSV import:
```bash
# Create CSV file with headers:
# username,email,first_name,last_name,groups

# Import users
wabadmin users import --file users.csv --dry-run  # Preview
wabadmin users import --file users.csv            # Execute

# Verify import
wabadmin users --filter "created_date < 1d"
```

---

### Target Management

**Q: Why can't WALLIX connect to a target?**

A: Troubleshooting steps:
```bash
# 1. Test network connectivity
wabadmin connectivity-test --device <device_id>

# 2. Verify credentials
wabadmin account checkout <account_id> --verify-only

# 3. Check firewall rules
# Ensure Bastion IP can reach target on required ports

# 4. Verify target service is running
# SSH: Port 22, RDP: Port 3389, etc.

# 5. Check connection policy
wabadmin connection-policy show <policy_name>
```

---

**Q: How do I rotate passwords for all accounts on a target?**

A: Bulk rotation:
```bash
# Rotate all accounts on a device
wabadmin rotation --device <device_id> --execute

# Rotate all accounts in a target group
wabadmin rotation --target-group <group_name> --execute

# Dry run first
wabadmin rotation --device <device_id> --dry-run
```

---

**Q: Why is password rotation failing?**

A: Common causes and solutions:

| Cause | Solution |
|-------|----------|
| Wrong current password | Manually update vault with correct password |
| Target unreachable | Check network connectivity and firewall |
| Insufficient privileges | Verify account has password change rights |
| Password policy mismatch | Align generated password with target policy |
| Service account locked | Unlock account on target system |

---

### Session Management

**Q: How do I view live sessions?**

A: To monitor active sessions:
```bash
# List active sessions
wabadmin sessions --status active

# View session details
wabadmin session show <session_id>

# Shadow a session (if permitted)
wabadmin session shadow <session_id>
```

---

**Q: How long are session recordings retained?**

A: Retention depends on configuration:
- Default: 90 days (configurable)
- Compliance requirements may require longer retention
- Storage capacity affects practical retention
- Archival to external storage extends retention

```bash
# Check retention policy
wabadmin config get recording.retention_days

# View storage usage
wabadmin recordings --storage-stats
```

---

**Q: Can I export session recordings?**

A: Yes, recordings can be exported:
```bash
# Export specific recording
wabadmin recording export <session_id> --output /path/to/export/

# Export with specific format
wabadmin recording export <session_id> --format mp4

# Bulk export
wabadmin recordings export --filter "date > 2024-01-01" --output /path/
```

---

### High Availability

**Q: How do I perform maintenance on an HA cluster?**

A: Use rolling maintenance procedure:
```bash
# 1. Check cluster status
crm status

# 2. Put secondary node in standby
crm node standby node-b

# 3. Perform maintenance on secondary
# (updates, restarts, etc.)

# 4. Return secondary to service
crm node online node-b

# 5. Verify sync complete
crm status
wabadmin sync-status

# 6. Repeat for primary node
crm node standby node-a
# ... maintenance ...
crm node online node-a
```

---

**Q: What happens if both HA nodes fail?**

A: Recovery procedure:
1. Identify node with latest data (check PostgreSQL WAL position)
2. Bring that node up first as standalone
3. Restore second node from first or from backup
4. Re-establish replication
5. Rejoin cluster

See: [Disaster Recovery Procedures](../32-incident-response/README.md)

---

## Integration FAQs

### LDAP/Active Directory

**Q: How do I troubleshoot LDAP authentication failures?**

A: Diagnostic steps:
```bash
# 1. Test LDAP connectivity
ldapsearch -H ldaps://dc.example.com:636 \
  -D "CN=wallix-svc,OU=Service,DC=example,DC=com" \
  -W -b "DC=example,DC=com" "(sAMAccountName=testuser)"

# 2. Check WALLIX LDAP configuration
wabadmin ldap-test --domain <domain_name> --user testuser

# 3. Review authentication logs
wabadmin audit --filter "event_type=authentication" --last 1h

# 4. Check LDAP sync status
wabadmin ldap-sync --status
```

---

**Q: How do I map AD groups to WALLIX groups?**

A: Group mapping configuration:
```bash
# Add group mapping
wabadmin group-mapping add \
  --ldap-group "CN=PAM-Admins,OU=Groups,DC=example,DC=com" \
  --local-group "wallix-admins"

# List mappings
wabadmin group-mapping list

# Sync groups
wabadmin ldap-sync --groups --run
```

---

### SIEM Integration

**Q: Why aren't logs appearing in my SIEM?**

A: Troubleshooting steps:
1. **Verify syslog configuration:**
   ```bash
   wabadmin config get syslog.server
   wabadmin config get syslog.port
   wabadmin config get syslog.protocol
   ```

2. **Test syslog connectivity:**
   ```bash
   logger -n siem.example.com -P 514 "WALLIX test message"
   ```

3. **Check for network issues:**
   ```bash
   nc -vz siem.example.com 514
   ```

4. **Verify log format matches SIEM parser**

---

**Q: What log formats does WALLIX support?**

A: Supported formats:
- CEF (Common Event Format)
- LEEF (Log Event Extended Format)
- Syslog (RFC 5424)
- JSON
- Custom templates

---

### API

**Q: How do I authenticate to the REST API?**

A: API authentication methods:

```bash
# Method 1: API Key (recommended)
curl -H "Authorization: Basic $(echo -n 'user:apikey' | base64)" \
  https://bastion.example.com/api/v3.12/status

# Method 2: Session token
TOKEN=$(curl -X POST https://bastion.example.com/api/v3.12/auth \
  -d '{"user":"admin","password":"pass"}' | jq -r '.token')
curl -H "Authorization: Bearer $TOKEN" \
  https://bastion.example.com/api/v3.12/devices
```

---

**Q: What's the API rate limit?**

A: Default rate limits:
- 100 requests per minute per API key
- 1000 requests per hour per API key
- Configurable by administrator
- Returns HTTP 429 when exceeded

---

## Performance FAQs

**Q: How many concurrent sessions can WALLIX handle?**

A: Capacity depends on hardware and session types:

| Deployment Size | SSH Sessions | RDP Sessions | Mixed |
|-----------------|--------------|--------------|-------|
| Small (4 vCPU, 8GB) | 100 | 50 | 75 |
| Medium (8 vCPU, 16GB) | 250 | 100 | 175 |
| Large (16 vCPU, 32GB) | 500 | 200 | 350 |
| Enterprise (32 vCPU, 64GB) | 1000 | 400 | 700 |

RDP sessions consume more resources due to video encoding.

---

**Q: Why are sessions slow during peak hours?**

A: Optimization steps:
1. **Check resource utilization:**
   ```bash
   top -bn1 | head -20
   free -h
   iostat -x 1 5
   ```

2. **Review session distribution:**
   - Consider load balancing across multiple nodes

3. **Optimize recording:**
   - Reduce recording quality if acceptable
   - Use faster storage for recordings

4. **Scale horizontally:**
   - Add additional Bastion nodes

---

**Q: How much storage do I need for recordings?**

A: Storage estimation:

| Session Type | Average Size/Hour | 1000 Sessions/Day |
|--------------|-------------------|-------------------|
| SSH | 1-5 MB | 1-5 GB |
| RDP (low quality) | 50-100 MB | 50-100 GB |
| RDP (high quality) | 200-500 MB | 200-500 GB |

Formula: `Daily sessions × Avg duration (hours) × Size/hour × Retention days`

---

## Licensing FAQs

**Q: How is WALLIX licensed?**

A: Licensing models:
- **Named users:** Fixed number of individual users
- **Concurrent sessions:** Maximum simultaneous sessions
- **Targets:** Number of managed devices/accounts
- **Hybrid:** Combination of the above

---

**Q: How do I check my license usage?**

A: License commands:
```bash
# View license details
wabadmin license-info

# Check current usage
wabadmin license-usage

# Generate usage report
wabadmin license-report --period 30d
```

---

**Q: What happens when I exceed my license?**

A: Behavior depends on license type:
- **Soft limit:** Warning messages, continued operation
- **Hard limit:** New sessions/users may be blocked
- **Grace period:** Temporary overage allowed
- Contact WALLIX sales for license expansion

---

## Known Issues

### Version 12.1.x

| Issue ID | Description | Workaround | Status |
|----------|-------------|------------|--------|
| WAB-12345 | RDP clipboard may fail with certain Unicode characters | Use file transfer instead | Fixed in 12.1.2 |
| WAB-12346 | LDAP sync may timeout with >50,000 users | Increase sync timeout, use pagination | Under investigation |
| WAB-12347 | Session recording playback slow on Firefox | Use Chrome or Edge | Fixed in 12.1.2 |
| WAB-12348 | API rate limiting not applied to health endpoints | N/A (by design) | Won't fix |
| WAB-12349 | HA failover may take >30s under heavy load | Pre-scale resources | Improved in 12.2 |

### Version 12.0.x

| Issue ID | Description | Workaround | Status |
|----------|-------------|------------|--------|
| WAB-12100 | Database migration slow for large deployments | Schedule extended maintenance window | Fixed in 12.1 |
| WAB-12101 | OIDC token refresh may fail silently | Re-authenticate if session expires | Fixed in 12.0.3 |
| WAB-12102 | Audit log search slow for date ranges >90 days | Use smaller date ranges | Improved in 12.1 |

---

## Known Limitations

### Platform Limitations

| Limitation | Details |
|------------|---------|
| Maximum users | 100,000 local users |
| Maximum targets | 50,000 devices |
| Maximum accounts | 500,000 credentials |
| Maximum concurrent sessions | Hardware dependent (see Performance FAQ) |
| Maximum recording size | 10 GB per session |
| Maximum authorization rules | 10,000 |

### Protocol Limitations

| Protocol | Limitation |
|----------|------------|
| SSH | Key sizes > 4096 bits may impact performance |
| RDP | NLA required for Windows Server 2016+ |
| VNC | Only VNC authentication supported |
| HTTP/HTTPS | WebSocket proxy limitations apply |
| Telnet | Not recommended for security reasons |

### Browser Compatibility

| Browser | HTML5 Gateway | Admin Console |
|---------|---------------|---------------|
| Chrome 90+ | Full support | Full support |
| Firefox 90+ | Full support | Full support |
| Edge 90+ | Full support | Full support |
| Safari 14+ | Partial (clipboard issues) | Full support |
| IE 11 | Not supported | Not supported |

### Database Limitations

| Aspect | Limitation |
|--------|------------|
| PostgreSQL version | 15+ required (14 deprecated) |
| Maximum database size | Limited by storage |
| Replication lag | Should stay < 10 MB |
| Connection pool | 100 default (configurable) |

---

## Compatibility Matrix

### Operating System Compatibility

| OS | Version | Bastion Install | Target Support |
|----|---------|-----------------|----------------|
| Debian | 12 (Bookworm) | ✓ Recommended | ✓ |
| Debian | 11 (Bullseye) | ✓ Supported | ✓ |
| Ubuntu | 22.04 LTS | ✗ | ✓ Target only |
| RHEL | 8.x, 9.x | ✗ | ✓ Target only |
| Windows Server | 2016+ | ✗ | ✓ Target only |

### WALLIX Version Compatibility

| From Version | To Version | Direct Upgrade | Notes |
|--------------|------------|----------------|-------|
| 12.0.x | 12.1.x | ✓ Yes | Recommended |
| 11.x | 12.1.x | ✓ Yes | See migration guide |
| 10.x | 12.1.x | ✗ No | Upgrade to 11.x first |
| 9.x | 12.1.x | ✗ No | Upgrade to 10.x, then 11.x |

### API Version Compatibility

| API Version | Bastion Version | Status |
|-------------|-----------------|--------|
| v3.12 | 12.x | Current |
| v3.6 | 11.x, 12.x | Supported |
| v3.3 | 10.x, 11.x | Deprecated |
| v2.x | < 10.x | Removed |

### Terraform Provider Compatibility

| Provider Version | API Version | Terraform Version |
|------------------|-------------|-------------------|
| 0.14.x | v3.12 | >= 1.0 |
| 0.13.x | v3.6 | >= 0.14 |
| 0.12.x | v3.3 | >= 0.13 |

---

## Common Mistakes

### Configuration Mistakes

**1. Overly permissive authorizations**
```
❌ Wrong: Single authorization granting access to all targets
✓ Right: Granular authorizations based on roles and responsibilities
```

**2. Not enabling approval for critical systems**
```
❌ Wrong: Direct access to production databases
✓ Right: Require approval for Tier-1 systems
```

**3. Weak password policies for vault**
```
❌ Wrong: 8-character passwords
✓ Right: 24+ character passwords with complexity
```

**4. Missing backup procedures**
```
❌ Wrong: No regular backups configured
✓ Right: Daily config backup, weekly full backup, tested restores
```

### Deployment Mistakes

**1. Undersized hardware**
```
❌ Wrong: 2 vCPU, 4GB RAM for production
✓ Right: Size based on expected session count (see Performance FAQ)
```

**2. Single point of failure**
```
❌ Wrong: Single Bastion node for critical access
✓ Right: HA cluster with multiple nodes
```

**3. Recording storage on system disk**
```
❌ Wrong: /var/lib/wallix on root partition
✓ Right: Separate storage volume for recordings
```

### Operational Mistakes

**1. Not monitoring license usage**
```
❌ Wrong: Discover license exceeded during incident
✓ Right: Proactive monitoring with alerts at 80%
```

**2. Skipping backup verification**
```
❌ Wrong: Backups running but never tested
✓ Right: Monthly restore tests to staging
```

**3. Ignoring security updates**
```
❌ Wrong: Never updating "because it works"
✓ Right: Regular security patch assessment and application
```

---

## Getting Help

### Before Contacting Support

1. Check this FAQ document
2. Review relevant documentation sections
3. Search the knowledge base
4. Collect diagnostic information:
   ```bash
   wabadmin support-bundle --output /tmp/support.tar.gz
   ```

### Support Channels

| Channel | Use Case | SLA |
|---------|----------|-----|
| Support Portal | Non-urgent issues | Business hours |
| Email | Documentation requests | 48 hours |
| Phone | Urgent/critical issues | 4 hours |
| Emergency | System down | 1 hour |

### Required Information

When contacting support, provide:
- WALLIX version (`wabadmin version`)
- Issue description and steps to reproduce
- Error messages and log excerpts
- Support bundle (`wabadmin support-bundle`)
- Impact assessment (users/systems affected)

---

*Document Version: 1.0*
*Last Updated: January 2026*
