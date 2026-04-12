# WALLIX Access Manager - Bastion-Side Integration Guide

> **SCOPE: CLIENT-MANAGED — We do NOT install or configure Access Manager.**
>
> Access Manager is installed and managed by the client's team. This guide
> covers the Bastion-side steps needed to register Bastion with the client's
> Access Manager. The original "quick install" content below is retained for
> reference only — do NOT follow those installation steps in our deployment.
>
> **Our deliverables to the client AM team (per site):**
> - Bastion API endpoint URL and API key
> - SAML Service Provider metadata URL
> - Health check URL
> - Firewall rule requirements (AM -> Bastion TCP/443)
>
> For the full Bastion-side integration procedure, see:
> [48 - Access Manager Bastion Connectivity](../48-access-manager-bastion-connectivity/README.md)

---

## Bastion-Side Registration Steps (OUR SCOPE)

### Step 1: Create API Integration User on Bastion

```bash
# Run on each WALLIX Bastion cluster (once per site)
wabadmin user add \
  --name am-integration \
  --email am-integration@company.com \
  --profile api-user \
  --api-key-enabled true

# Generate the API key — provide to client AM team
wabadmin user api-key generate am-integration
```

### Step 2: Verify Bastion API Endpoint is Reachable

```bash
# Test from AM network (client AM team performs this)
curl -sk -H "X-Auth-Token: <api-key>" \
  https://<bastion-vip>/api/version
# Expected: HTTP 200, JSON with product/version info
```

### Step 3: Provide Integration Details to Client AM Team

| Item | Value |
|------|-------|
| API endpoint | `https://<site-vip>/api/` |
| API user | `am-integration` |
| API key | (from Step 1 output) |
| SAML metadata URL | `https://<site-vip>/saml/metadata` |
| Health check URL | `https://<site-vip>/api/version` |

### Step 4: Confirm AM Registration

```bash
# After client AM team configures their side
wabadmin am-status
# Expected: Access Manager: Connected
```

---

## Client AM Team Quick Install Reference (REFERENCE ONLY)

> The following steps are performed by the client AM team on their servers.
> This content is retained for context only.

For comprehensive documentation, see [README.md](README.md).

---

## Prerequisites (5 minutes)

```bash
# Verify system meets requirements
cat /etc/os-release  # Ubuntu 22.04 LTS or RHEL 9
free -h              # Minimum 4 GB RAM
df -h                # Minimum 50 GB disk space
```

**Checklist:**
- [ ] Server with 2+ vCPU, 4+ GB RAM, 50+ GB disk
- [ ] Ubuntu 22.04 LTS or RHEL 9 installed
- [ ] Static IP address configured
- [ ] DNS record created (portal.company.com)
- [ ] SSL certificate ready (or use Let's Encrypt)
- [ ] Ports 80, 443 open in firewall

---

## Quick Install (10 minutes)

### Option A: Package Installation (Recommended)

```bash
# 1. Add WALLIX repository
wget -O - https://repo.wallix.com/gpg.key | sudo apt-key add -
echo "deb https://repo.wallix.com/apt/ubuntu jammy main" | \
  sudo tee /etc/apt/sources.list.d/wallix.list

# 2. Install Access Manager
sudo apt update
sudo apt install -y wallix-access-manager

# 3. Run initial setup
sudo wallix-am setup
```

**Setup Wizard will ask:**
```
Admin Email:          admin@company.com
Portal URL:           https://portal.company.com
Database Type:        PostgreSQL (default)
Database Host:        localhost (default)
SSL Certificate:      Let's Encrypt (auto) or Custom path
```

---

## Initial Configuration (15 minutes)

### 1. Access Web Interface

Open browser: `https://portal.company.com`

**First Login:**
- Username: `admin`
- Password: (set during installation)

### 2. Configure SSL Certificate (if not using Let's Encrypt)

```bash
sudo wallix-am cert install \
  --cert /path/to/certificate.crt \
  --key /path/to/private.key \
  --chain /path/to/ca-bundle.crt
```

### 3. Configure Email Notifications

```bash
sudo wallix-am config set --smtp-host smtp.company.com
sudo wallix-am config set --smtp-port 587
sudo wallix-am config set --smtp-user notifications@company.com
sudo wallix-am config set --smtp-password "smtp_password"
sudo wallix-am config set --smtp-from "WALLIX <noreply@company.com>"
sudo wallix-am config set --smtp-tls true

# Test email
sudo wallix-am test smtp --to admin@company.com
```

### 4. Configure Authentication

**Option A: LDAP/Active Directory**

```bash
sudo wallix-am auth ldap add \
  --name "Corporate AD" \
  --server ldaps://dc.company.com:636 \
  --base-dn "DC=company,DC=com" \
  --bind-dn "CN=svc-am,OU=Service Accounts,DC=company,DC=com" \
  --bind-password "service_password"

# Enable LDAP
sudo wallix-am auth ldap enable "Corporate AD"

# Test
sudo wallix-am auth ldap test "Corporate AD" --username testuser
```

**Option B: SAML SSO**

```bash
sudo wallix-am auth saml add \
  --name "Okta SSO" \
  --idp-url "https://company.okta.com/app/wallix/sso/saml" \
  --idp-certificate /path/to/okta-cert.crt

# Export SP metadata for IdP configuration
sudo wallix-am auth saml export-metadata > /tmp/wallix-sp-metadata.xml
```

### 5. Enable MFA (Recommended)

```bash
# Configure RADIUS MFA (FortiAuthenticator)
sudo wallix-am auth mfa add \
  --name "FortiAuthenticator" \
  --type radius \
  --server 10.10.0.60 \
  --port 1812 \
  --secret "shared_secret"

# Require MFA for all users
sudo wallix-am auth mfa require --for-all-users
```

---

## Add Your First Application (10 minutes)

### Web UI Method

1. Navigate to: **Applications** → **Add Application**

2. Fill in details:
   ```
   Application Name:    Internal Wiki
   Application URL:     http://wiki.internal.company.com
   Protocol:            HTTP
   Category:            Documentation
   Icon:                [Upload or select]

   Access Control:
   [✓] Require authentication
   [ ] Require approval
   [✓] Record sessions

   Who Can Access:
   Groups: [All Employees]
   ```

3. Click **Save**

### CLI Method

```bash
sudo wallix-am app add \
  --name "Internal Wiki" \
  --url "http://wiki.internal.company.com" \
  --protocol http \
  --category "Documentation" \
  --auth-required \
  --record-sessions \
  --groups "All Employees"
```

---

## Install Application Connector (Optional)

For applications behind firewall without direct network access.

### On Application Server

```bash
# 1. Download connector
wget https://portal.company.com/downloads/wallix-connector-linux-amd64.tar.gz

# 2. Install
tar -xzf wallix-connector-linux-amd64.tar.gz
cd wallix-connector
sudo ./install.sh

# 3. Get registration token from Access Manager
# Web UI: Settings → Connectors → Generate Token

# 4. Register connector
sudo wallix-connector register \
  --portal https://portal.company.com \
  --token <registration-token> \
  --name "AppServer-Connector-01"

# 5. Start connector
sudo systemctl start wallix-connector
sudo systemctl enable wallix-connector

# 6. Verify
sudo wallix-connector status
```

---

## Create Access Policy (10 minutes)

### Simple Policy (Auto-Approve)

```bash
sudo wallix-am policy create \
  --name "General Application Access" \
  --applications "Internal Wiki" \
  --groups "All Employees" \
  --auto-approve \
  --record-session
```

### Policy with Approval

```bash
sudo wallix-am policy create \
  --name "Production Database Access" \
  --applications "PostgreSQL Production" \
  --groups "DBA Team,DevOps Team" \
  --require-approval \
  --approvers "dba-managers" \
  --max-duration 14400 \
  --require-mfa \
  --record-session
```

---

## Verify Setup (5 minutes)

### Health Check

```bash
# Check system status
sudo wallix-am status

# Expected output:
# Service:        Running
# Database:       Connected
# SSL:            Valid (expires: 2027-02-04)
# Connectors:     1 active
# Applications:   2 configured
# Users:          450 (via LDAP)
# Active Sessions: 12
```

### Test User Access

1. **As End User:**
   - Navigate to `https://portal.company.com`
   - Login with AD credentials
   - Select application from dashboard
   - Verify access granted

2. **As Administrator:**
   - Check audit logs: `sudo wallix-am logs access --tail 10`
   - Verify session recorded
   - Test approval workflow (if configured)

---

## Common Commands Reference

```bash
# Service management
sudo systemctl status wallix-access-manager
sudo systemctl restart wallix-access-manager

# Configuration
sudo wallix-am config show
sudo wallix-am config set --key value

# Logs
sudo wallix-am logs access --tail 100 --follow
sudo wallix-am logs audit --last 24h

# Users and groups
sudo wallix-am users list
sudo wallix-am groups sync

# Applications
sudo wallix-am app list
sudo wallix-am app test "Application Name"

# Policies
sudo wallix-am policy list
sudo wallix-am policy test --user john@company.com --app "App Name"

# Metrics
sudo wallix-am metrics show

# Backup
sudo wallix-am backup create
sudo wallix-am backup list
sudo wallix-am backup restore --file backup.tar.gz
```

---

## Next Steps

✅ **Access Manager is now running!**

**Recommended next steps:**

1. **Configure additional applications** (see [README.md](README.md#application-connector-setup))
2. **Set up approval workflows** (see [README.md](README.md#approval-workflows))
3. **Integrate with WALLIX Bastion** (see [README.md](README.md#integration-with-wallix-bastion))
4. **Configure high availability** (see [README.md](README.md#best-practices))
5. **Set up monitoring** (see [README.md](README.md#monitoring-and-logging))

---

## Troubleshooting Quick Fixes

### Portal not accessible

```bash
sudo systemctl restart wallix-access-manager nginx
sudo ufw allow 443/tcp
curl -k https://localhost
```

### LDAP authentication fails

```bash
sudo wallix-am auth ldap test "Corporate AD" --username testuser --verbose
# Check credentials and certificate trust
```

### Connector offline

```bash
sudo systemctl restart wallix-connector
sudo journalctl -u wallix-connector -f
```

---

## Support

- **Documentation:** [Complete README](README.md)
- **Official Docs:** https://pam.wallix.one/documentation
- **Support Portal:** https://support.wallix.com

---

*Quick Setup Guide v1.0*
*For WALLIX Access Manager 5.2.x*
