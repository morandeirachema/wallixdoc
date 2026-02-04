# 47 - WALLIX Access Manager Setup and Configuration

## Table of Contents

1. [Access Manager Overview](#access-manager-overview)
2. [Architecture and Components](#architecture-and-components)
3. [System Requirements](#system-requirements)
4. [Installation](#installation)
5. [Initial Configuration](#initial-configuration)
6. [Integration with WALLIX Bastion](#integration-with-wallix-bastion)
7. [User Portal Configuration](#user-portal-configuration)
8. [Application Connector Setup](#application-connector-setup)
9. [Authentication Configuration](#authentication-configuration)
10. [Authorization Policies](#authorization-policies)
11. [Monitoring and Logging](#monitoring-and-logging)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)

---

## Access Manager Overview

### What is WALLIX Access Manager?

WALLIX Access Manager is a complementary component to WALLIX Bastion that provides:
- **Web-based user portal** for self-service access requests
- **Application connectivity** without VPN or direct network access
- **Just-In-Time (JIT) access** with approval workflows
- **Zero Trust Network Access (ZTNA)** capabilities
- **Session recording** for web applications

```
+===============================================================================+
|                    WALLIX ACCESS MANAGER OVERVIEW                             |
+===============================================================================+
|                                                                               |
|  End User                    Access Manager              Target Applications |
|     |                              |                              |            |
|     |  1. Request Access           |                              |            |
|     |---------------------------->|                              |            |
|     |                              |                              |            |
|     |  2. Approval Workflow        |                              |            |
|     |<-----------------------------|                              |            |
|     |                              |                              |            |
|     |  3. Access Granted           |                              |            |
|     |                              |  4. Establish Tunnel         |            |
|     |                              |----------------------------->|            |
|     |                              |                              |            |
|     |  5. Secure Connection        |                              |            |
|     |<-----------------------------|<-----------------------------|            |
|     |                              |                              |            |
|     |           All traffic proxied through Access Manager        |            |
|     |           Session recorded and monitored                    |            |
|                                                                               |
+===============================================================================+
```

### Key Capabilities

| Feature | Description |
|---------|-------------|
| **Self-Service Portal** | Users request access through web interface |
| **JIT Access** | Time-limited access with automatic revocation |
| **Approval Workflows** | Multi-level approval for sensitive resources |
| **Application Connector** | Secure tunnel to applications without VPN |
| **Session Recording** | Record web application sessions |
| **MFA Integration** | Integrate with existing MFA solutions |
| **RBAC** | Role-based access control for applications |

### Access Manager vs Bastion

| Aspect | WALLIX Bastion | WALLIX Access Manager |
|--------|----------------|----------------------|
| **Primary Use** | Infrastructure access (SSH, RDP, databases) | Application access (web apps, SaaS) |
| **Access Method** | Direct protocol proxy | Web portal + connector |
| **Target Audience** | System administrators, DBAs | End users, developers, contractors |
| **Deployment** | On-premises (bare metal/VM) | On-premises or cloud |
| **Session Types** | SSH, RDP, VNC, Telnet, databases | HTTPS, web applications |

---

## Architecture and Components

### Access Manager Architecture

```
+===============================================================================+
|                  WALLIX ACCESS MANAGER ARCHITECTURE                           |
+===============================================================================+
|                                                                               |
|  +-------------------------+                                                  |
|  |      End Users          |                                                  |
|  | (Browser-based access)  |                                                  |
|  +----------+--------------+                                                  |
|             |                                                                 |
|             | HTTPS (443)                                                     |
|             |                                                                 |
|  +----------v--------------+                                                  |
|  |  Access Manager Portal  |                                                  |
|  |  (Web Interface)        |                                                  |
|  |  - User authentication  |                                                  |
|  |  - Access requests      |                                                  |
|  |  - Approval workflows   |                                                  |
|  +----------+--------------+                                                  |
|             |                                                                 |
|             | API/Database                                                    |
|             |                                                                 |
|  +----------v--------------+                                                  |
|  |  Access Manager Core    |                                                  |
|  |  - Policy engine        |                                                  |
|  |  - Session manager      |                                                  |
|  |  - Audit logging        |                                                  |
|  +----------+--------------+                                                  |
|             |                                                                 |
|             | Control/Data Plane                                              |
|             |                                                                 |
|  +----------v--------------+       +---------------------------+              |
|  |  Application Connector  |<----->|  WALLIX Bastion (Optional)|              |
|  |  - Tunnel to apps       |       |  - Infrastructure access  |              |
|  |  - Protocol translation |       +---------------------------+              |
|  +----------+--------------+                                                  |
|             |                                                                 |
|             | Application Protocols                                           |
|             |                                                                 |
|  +----------v--------------+                                                  |
|  |   Target Applications   |                                                  |
|  |  - Web applications     |                                                  |
|  |  - SaaS platforms       |                                                  |
|  |  - Internal tools       |                                                  |
|  +-------------------------+                                                  |
|                                                                               |
+===============================================================================+
```

### Core Components

1. **Access Manager Portal**
   - Web-based user interface
   - Built on modern web stack
   - Responsive design for mobile access
   - Single Sign-On (SSO) integration

2. **Access Manager Core**
   - Policy decision engine
   - Session orchestration
   - Audit trail and compliance logging
   - Integration APIs

3. **Application Connector**
   - Lightweight agent for application access
   - Reverse proxy capabilities
   - TLS termination
   - Protocol translation

4. **Database**
   - PostgreSQL or MySQL
   - Stores configuration, policies, audit logs
   - High availability support

---

## System Requirements

### Hardware Requirements

| Deployment Size | vCPU | RAM | Disk | Sessions |
|----------------|------|-----|------|----------|
| **Small** | 2 | 4 GB | 50 GB | Up to 50 concurrent |
| **Medium** | 4 | 8 GB | 100 GB | Up to 200 concurrent |
| **Large** | 8 | 16 GB | 200 GB | Up to 500 concurrent |
| **Enterprise** | 16 | 32 GB | 500 GB | 1000+ concurrent |

### Software Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Ubuntu 22.04 LTS, RHEL 9, Debian 12 |
| **Database** | PostgreSQL 14+ or MySQL 8.0+ |
| **Web Server** | Nginx or Apache (included) |
| **TLS Certificates** | Valid SSL certificate (Let's Encrypt supported) |
| **Network** | Static IP address, DNS resolution |

### Network Ports

```
+===============================================================================+
|                    ACCESS MANAGER PORT REQUIREMENTS                           |
+===============================================================================+

INBOUND (To Access Manager)
============================

+-----------------------------------------------------------------------------+
| Port     | Protocol | Source          | Purpose               | Required |
+----------+----------+-----------------+-----------------------+----------+
| 443      | TCP      | End Users       | HTTPS Web Portal      | Yes      |
| 80       | TCP      | End Users       | HTTP redirect to HTTPS| Optional |
| 22       | TCP      | Administrators  | SSH management        | Yes      |
| 5432     | TCP      | Database (ext)  | PostgreSQL (if remote)| Optional |
| 3306     | TCP      | Database (ext)  | MySQL (if remote)     | Optional |
+----------+----------+-----------------+-----------------------+----------+

OUTBOUND (From Access Manager)
===============================

+-----------------------------------------------------------------------------+
| Port     | Protocol | Destination     | Purpose               | Required |
+----------+----------+-----------------+-----------------------+----------+
| 443      | TCP      | Target Apps     | HTTPS to applications | Yes      |
| 389/636  | TCP      | LDAP/AD         | Authentication        | Optional |
| 1812/1813| UDP      | RADIUS          | MFA authentication    | Optional |
| 25/587   | TCP      | SMTP            | Email notifications   | Optional |
| 443      | TCP      | WALLIX Bastion  | Bastion integration   | Optional |
+----------+----------+-----------------+-----------------------+----------+

+===============================================================================+
```

---

## Installation

### Pre-Installation Checklist

- [ ] Server meets hardware requirements
- [ ] Operating system installed and updated
- [ ] Static IP address configured
- [ ] DNS records created (portal.company.com)
- [ ] SSL certificate obtained
- [ ] Database server ready (PostgreSQL or MySQL)
- [ ] Firewall rules configured
- [ ] NTP configured for time synchronization

### Installation Methods

#### Method 1: Package Installation (Recommended)

```bash
# 1. Add WALLIX repository
wget -O - https://repo.wallix.com/gpg.key | sudo apt-key add -
echo "deb https://repo.wallix.com/apt/ubuntu jammy main" | \
  sudo tee /etc/apt/sources.list.d/wallix.list

# 2. Update package index
sudo apt update

# 3. Install Access Manager
sudo apt install wallix-access-manager

# 4. Verify installation
wallix-am version
```

#### Method 2: Docker Deployment

```bash
# 1. Pull Access Manager image
docker pull wallix/access-manager:latest

# 2. Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  access-manager:
    image: wallix/access-manager:latest
    container_name: wallix-am
    ports:
      - "443:443"
      - "80:80"
    environment:
      - AM_DB_HOST=postgres
      - AM_DB_PORT=5432
      - AM_DB_NAME=accessmanager
      - AM_DB_USER=am_user
      - AM_DB_PASSWORD=secure_password
      - AM_ADMIN_EMAIL=admin@company.com
    volumes:
      - am-data:/var/lib/access-manager
      - am-logs:/var/log/access-manager
      - ./certs:/etc/access-manager/certs
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:14
    container_name: wallix-am-db
    environment:
      - POSTGRES_DB=accessmanager
      - POSTGRES_USER=am_user
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  am-data:
  am-logs:
  postgres-data:
EOF

# 3. Start services
docker-compose up -d

# 4. Check status
docker-compose ps
```

#### Method 3: Manual Installation

```bash
# 1. Download installation package
wget https://downloads.wallix.com/access-manager/wallix-am-5.2.1.tar.gz

# 2. Extract package
tar -xzf wallix-am-5.2.1.tar.gz
cd wallix-am-5.2.1

# 3. Run installation script
sudo ./install.sh

# 4. Follow interactive prompts
#    - Database configuration
#    - Admin credentials
#    - Network settings
#    - SSL certificate paths
```

### Post-Installation Steps

```bash
# 1. Start Access Manager service
sudo systemctl start wallix-access-manager
sudo systemctl enable wallix-access-manager

# 2. Verify service is running
sudo systemctl status wallix-access-manager

# 3. Check logs for any errors
sudo journalctl -u wallix-access-manager -f

# 4. Verify web interface is accessible
curl -k https://localhost
```

---

## Initial Configuration

### First-Time Setup Wizard

Access the web interface: `https://portal.company.com`

#### Step 1: Administrator Account

```
+===============================================================================+
|  INITIAL ADMINISTRATOR SETUP                                                  |
+===============================================================================+

1. Navigate to: https://portal.company.com/setup

2. Create Administrator Account:
   Username:        admin
   Email:           admin@company.com
   Password:        [Strong password with 12+ characters]
   Confirm Password:[Same password]

3. Security Questions:
   Question 1:      [Select from dropdown]
   Answer 1:        [Your answer]
   Question 2:      [Select from dropdown]
   Answer 2:        [Your answer]

4. Click: [Create Administrator]
```

#### Step 2: System Configuration

```bash
# Configure via CLI
sudo wallix-am config set --admin-email admin@company.com
sudo wallix-am config set --portal-url https://portal.company.com
sudo wallix-am config set --session-timeout 3600
sudo wallix-am config set --max-concurrent-sessions 1000

# Configure database connection (if not done during install)
sudo wallix-am config set --db-type postgresql
sudo wallix-am config set --db-host localhost
sudo wallix-am config set --db-port 5432
sudo wallix-am config set --db-name accessmanager
sudo wallix-am config set --db-user am_user
sudo wallix-am config set --db-password secure_password

# Apply configuration
sudo wallix-am config apply
```

#### Step 3: SSL Certificate Configuration

```bash
# Option A: Use Let's Encrypt (Recommended)
sudo wallix-am cert install-letsencrypt \
  --domain portal.company.com \
  --email admin@company.com

# Option B: Use existing certificate
sudo wallix-am cert install \
  --cert /path/to/certificate.crt \
  --key /path/to/private.key \
  --chain /path/to/ca-bundle.crt

# Verify certificate
sudo wallix-am cert verify
```

#### Step 4: Email (SMTP) Configuration

```bash
# Configure SMTP for notifications
sudo wallix-am config set --smtp-host smtp.company.com
sudo wallix-am config set --smtp-port 587
sudo wallix-am config set --smtp-user notifications@company.com
sudo wallix-am config set --smtp-password smtp_password
sudo wallix-am config set --smtp-from "WALLIX Access Manager <noreply@company.com>"
sudo wallix-am config set --smtp-tls true

# Test SMTP configuration
sudo wallix-am test smtp --to admin@company.com
```

---

## Integration with WALLIX Bastion

### Bastion Integration Architecture

```
+===============================================================================+
|            ACCESS MANAGER + BASTION INTEGRATION                               |
+===============================================================================+
|                                                                               |
|  User Request Flow:                                                           |
|                                                                               |
|  +--------+     1. Web Access       +---------------+                         |
|  |  User  |------------------------>| Access Manager |                        |
|  +--------+                          +-------+-------+                        |
|                                              |                                |
|                         2. Infrastructure    |                                |
|                            Access Request    |                                |
|                                              v                                |
|                                      +-------+-------+                        |
|                                      | WALLIX Bastion|                        |
|                                      +-------+-------+                        |
|                                              |                                |
|                         3. Proxied           |                                |
|                            Connection        |                                |
|                                              v                                |
|                                      +---------------+                        |
|                                      | Target Servers|                        |
|                                      +---------------+                        |
|                                                                               |
|  Benefits:                                                                    |
|  - Unified access portal                                                      |
|  - Consistent approval workflows                                              |
|  - Centralized audit logging                                                  |
|  - Single MFA authentication                                                  |
|                                                                               |
+===============================================================================+
```

### Integration Configuration

#### Step 1: Configure Bastion Connection

```bash
# On Access Manager server
sudo wallix-am bastion add \
  --name "Primary Bastion" \
  --host bastion.company.com \
  --port 443 \
  --api-user am-integration \
  --api-key $(cat /etc/access-manager/bastion-api-key)

# Verify connection
sudo wallix-am bastion test "Primary Bastion"

# Expected output:
# ✓ Connection successful
# ✓ API authentication verified
# ✓ Version: WALLIX Bastion 12.1.1
# ✓ Status: Healthy
```

#### Step 2: Create API User on Bastion

```bash
# On WALLIX Bastion server
wabadmin user add \
  --name am-integration \
  --email am-integration@company.com \
  --profile api-user \
  --api-key-enabled true

# Generate API key
wabadmin user api-key generate am-integration

# Copy the API key and save to Access Manager
```

#### Step 3: Configure Single Sign-On

```bash
# Enable SSO between Access Manager and Bastion
sudo wallix-am bastion sso enable \
  --bastion "Primary Bastion" \
  --method saml

# Configure SAML settings
sudo wallix-am bastion sso configure \
  --bastion "Primary Bastion" \
  --idp-url https://portal.company.com/saml/idp \
  --sp-url https://bastion.company.com/saml/sp \
  --certificate /etc/access-manager/saml/certificate.crt
```

#### Step 4: Sync Users and Groups

```bash
# Enable user synchronization
sudo wallix-am bastion sync users \
  --bastion "Primary Bastion" \
  --direction bidirectional \
  --interval 3600

# Trigger immediate sync
sudo wallix-am bastion sync now "Primary Bastion"

# View sync status
sudo wallix-am bastion sync status "Primary Bastion"
```

---

## User Portal Configuration

### Portal Branding

```bash
# Upload company logo
sudo wallix-am portal branding \
  --logo /path/to/company-logo.png \
  --favicon /path/to/favicon.ico

# Set color scheme
sudo wallix-am portal branding \
  --primary-color "#003366" \
  --secondary-color "#0066CC" \
  --accent-color "#FF6600"

# Custom welcome message
sudo wallix-am portal message set \
  --type welcome \
  --content "Welcome to Secure Application Access"

# Terms of service
sudo wallix-am portal message set \
  --type terms \
  --file /path/to/terms-of-service.html
```

### Dashboard Configuration

Web UI Configuration: `https://portal.company.com/admin/dashboard`

```
Dashboard Widgets:
┌─────────────────────────────────────────────────────────────────┐
│ [✓] My Active Sessions                                          │
│ [✓] Pending Access Requests                                     │
│ [✓] Recent Activity                                             │
│ [✓] Available Applications                                      │
│ [ ] System Status (admin only)                                  │
│ [✓] Quick Access Links                                          │
│ [ ] Usage Statistics (admin only)                               │
└─────────────────────────────────────────────────────────────────┘

Session Settings:
  Session Timeout:     60 minutes
  Idle Timeout:        15 minutes
  Max Sessions/User:   3
  [✓] Enable session keep-alive
```

---

## Application Connector Setup

### Installing Application Connector

The Application Connector enables secure access to applications behind firewalls without VPN.

#### Linux Connector Installation

```bash
# 1. Download connector package
wget https://portal.company.com/downloads/wallix-connector-linux-amd64.tar.gz

# 2. Extract and install
tar -xzf wallix-connector-linux-amd64.tar.gz
cd wallix-connector
sudo ./install.sh

# 3. Register connector with Access Manager
sudo wallix-connector register \
  --portal https://portal.company.com \
  --token $(cat /tmp/connector-registration-token.txt) \
  --name "AppServer-Connector-01"

# 4. Start connector
sudo systemctl start wallix-connector
sudo systemctl enable wallix-connector

# 5. Verify status
sudo wallix-connector status
```

#### Windows Connector Installation

```powershell
# 1. Download connector installer
Invoke-WebRequest -Uri "https://portal.company.com/downloads/wallix-connector-windows-x64.msi" `
  -OutFile "wallix-connector.msi"

# 2. Install silently
msiexec /i wallix-connector.msi /quiet /qn

# 3. Register connector
& "C:\Program Files\WALLIX\Connector\wallix-connector.exe" register `
  --portal https://portal.company.com `
  --token <registration-token> `
  --name "AppServer-Connector-02"

# 4. Start service
Start-Service -Name "WallixConnector"

# 5. Verify
& "C:\Program Files\WALLIX\Connector\wallix-connector.exe" status
```

### Connector Configuration

```bash
# Configure connector settings
sudo wallix-connector config set --listen-port 8443
sudo wallix-connector config set --log-level info
sudo wallix-connector config set --health-check-interval 30
sudo wallix-connector config set --reconnect-interval 10

# Configure application mappings
sudo wallix-connector app add \
  --name "Internal-Wiki" \
  --url http://localhost:8080 \
  --protocol http \
  --health-check /health

sudo wallix-connector app add \
  --name "Dev-Portal" \
  --url https://localhost:3000 \
  --protocol https \
  --tls-verify false

# List configured applications
sudo wallix-connector app list

# Test application connectivity
sudo wallix-connector app test "Internal-Wiki"
```

---

## Authentication Configuration

### LDAP/Active Directory Integration

```bash
# Configure LDAP authentication
sudo wallix-am auth ldap add \
  --name "Corporate AD" \
  --server ldaps://dc.company.com:636 \
  --base-dn "DC=company,DC=com" \
  --bind-dn "CN=svc-accessmanager,OU=Service Accounts,DC=company,DC=com" \
  --bind-password "service_account_password" \
  --user-filter "(&(objectClass=user)(sAMAccountName={username}))" \
  --group-filter "(&(objectClass=group)(member={dn}))"

# Test LDAP connection
sudo wallix-am auth ldap test "Corporate AD" --username testuser

# Enable LDAP authentication
sudo wallix-am auth ldap enable "Corporate AD"
```

### SAML SSO Configuration

```bash
# Configure SAML IdP
sudo wallix-am auth saml add \
  --name "Okta SSO" \
  --idp-url "https://company.okta.com/app/wallix/sso/saml" \
  --idp-certificate /path/to/okta-certificate.crt \
  --sp-entity-id "https://portal.company.com/saml/sp" \
  --attribute-mapping "email:email,name:displayName,groups:groups"

# Download SP metadata for IdP configuration
sudo wallix-am auth saml export-metadata > /tmp/wallix-sp-metadata.xml
```

### MFA Configuration

```bash
# Configure RADIUS MFA (FortiAuthenticator)
sudo wallix-am auth mfa add \
  --name "FortiAuthenticator MFA" \
  --type radius \
  --server 10.10.0.60 \
  --port 1812 \
  --secret "shared_secret" \
  --timeout 10

# Configure TOTP (Time-based OTP)
sudo wallix-am auth mfa add \
  --name "Authenticator App" \
  --type totp \
  --issuer "WALLIX Access Manager" \
  --digits 6 \
  --interval 30

# Enable MFA requirement
sudo wallix-am auth mfa require --for-all-users
sudo wallix-am auth mfa require --for-admin-users
```

---

## Authorization Policies

### Creating Application Access Policies

#### Web UI Configuration

Navigate to: `https://portal.company.com/admin/policies`

```
Create New Policy:
┌─────────────────────────────────────────────────────────────────┐
│ Policy Name: Production Database Access                         │
│                                                                  │
│ Applications:                                                    │
│   [✓] PostgreSQL Production DB                                  │
│   [✓] MySQL Production DB                                       │
│                                                                  │
│ Who Can Access:                                                  │
│   Groups: [DBA Team] [DevOps Team]                              │
│   Users:  [john.doe@company.com]                                │
│                                                                  │
│ Access Conditions:                                               │
│   [✓] Require approval                                          │
│   Approvers: [dba-managers] [security-team]                     │
│   [✓] Time-limited access                                       │
│   Default Duration: 4 hours                                      │
│   Maximum Duration: 24 hours                                     │
│   [✓] Business hours only (Mon-Fri, 9AM-6PM)                    │
│   [✓] MFA required                                              │
│   [ ] Source IP restriction                                     │
│                                                                  │
│ Session Controls:                                                │
│   [✓] Record all sessions                                       │
│   [✓] Monitor in real-time                                      │
│   [✓] Terminate after idle 15 minutes                           │
│                                                                  │
│ [Create Policy] [Cancel]                                         │
└─────────────────────────────────────────────────────────────────┘
```

#### CLI Configuration

```bash
# Create policy via CLI
sudo wallix-am policy create \
  --name "Production DB Access" \
  --applications "PostgreSQL Production,MySQL Production" \
  --groups "DBA Team,DevOps Team" \
  --require-approval \
  --approvers "dba-managers,security-team" \
  --max-duration 86400 \
  --business-hours "Mon-Fri 09:00-18:00" \
  --require-mfa \
  --record-session \
  --monitor-realtime

# List all policies
sudo wallix-am policy list

# Test policy for specific user
sudo wallix-am policy test \
  --user john.doe@company.com \
  --application "PostgreSQL Production"
```

### Approval Workflows

```bash
# Configure multi-level approval
sudo wallix-am workflow create \
  --name "High-Risk Access Approval" \
  --steps "manager,security,compliance" \
  --timeout 4h \
  --escalation "auto-deny"

# Assign workflow to policy
sudo wallix-am policy update "Production DB Access" \
  --workflow "High-Risk Access Approval"

# Configure notifications
sudo wallix-am workflow notify \
  --workflow "High-Risk Access Approval" \
  --email "security-team@company.com" \
  --slack "#access-requests"
```

---

## Monitoring and Logging

### Access Logs

```bash
# View access logs
sudo wallix-am logs access --tail 100 --follow

# Export logs to file
sudo wallix-am logs access --since "2026-02-01" --format json > /tmp/access-logs.json

# Query specific user activity
sudo wallix-am logs access --user john.doe@company.com --last 7d

# Filter by application
sudo wallix-am logs access --application "PostgreSQL Production" --last 24h
```

### Audit Logs

```bash
# View audit trail
sudo wallix-am logs audit --tail 50

# Export audit logs for compliance
sudo wallix-am logs audit \
  --since "2026-01-01" \
  --until "2026-01-31" \
  --format csv > /tmp/audit-january-2026.csv

# Filter by event type
sudo wallix-am logs audit --event-type "policy_change,user_create,approval_granted"
```

### Metrics and Dashboards

```bash
# View system metrics
sudo wallix-am metrics show

# Expected output:
# Active Sessions:       45
# Peak Sessions (24h):   120
# Total Users:           450
# Active Connectors:     8
# Pending Approvals:     3
# Average Response Time: 125ms
# CPU Usage:             35%
# Memory Usage:          12 GB / 32 GB
# Disk Usage:            180 GB / 500 GB

# Export metrics for Prometheus
sudo wallix-am metrics export --format prometheus > /tmp/metrics.prom
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Cannot Access Portal

**Symptoms:**
- Portal URL not loading
- Connection timeout
- SSL certificate errors

**Diagnosis:**
```bash
# Check service status
sudo systemctl status wallix-access-manager

# Check nginx/apache status
sudo systemctl status nginx  # or apache2

# Verify ports are listening
sudo netstat -tlnp | grep -E ':(80|443)'

# Check SSL certificate
sudo wallix-am cert verify

# Test local connectivity
curl -k https://localhost
```

**Resolution:**
```bash
# Restart service
sudo systemctl restart wallix-access-manager

# Reinstall certificate
sudo wallix-am cert install --cert /path/to/cert.crt --key /path/to/key.key

# Check firewall
sudo ufw status
sudo ufw allow 443/tcp
```

#### Issue 2: LDAP Authentication Fails

**Symptoms:**
- Users cannot login with AD credentials
- LDAP bind errors in logs

**Diagnosis:**
```bash
# Test LDAP connection
sudo wallix-am auth ldap test "Corporate AD" --username testuser --verbose

# Check LDAP configuration
sudo wallix-am auth ldap show "Corporate AD"

# Test LDAP bind manually
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc-accessmanager,OU=Service Accounts,DC=company,DC=com" \
  -W \
  -b "DC=company,DC=com" \
  "(sAMAccountName=testuser)"
```

**Resolution:**
```bash
# Update LDAP configuration
sudo wallix-am auth ldap update "Corporate AD" \
  --bind-dn "CN=svc-accessmanager,OU=Service Accounts,DC=company,DC=com" \
  --bind-password "new_password"

# Verify certificate trust
sudo wallix-am auth ldap update "Corporate AD" --tls-verify true
```

#### Issue 3: Application Connector Offline

**Symptoms:**
- Applications not accessible through portal
- Connector shows offline in dashboard

**Diagnosis:**
```bash
# Check connector status
sudo wallix-connector status

# View connector logs
sudo journalctl -u wallix-connector -f

# Test network connectivity to portal
ping portal.company.com
telnet portal.company.com 443
```

**Resolution:**
```bash
# Restart connector
sudo systemctl restart wallix-connector

# Re-register connector
sudo wallix-connector register --force

# Check firewall allows outbound 443
sudo iptables -L OUTPUT -n -v | grep 443
```

---

## Best Practices

### Security Best Practices

1. **Enable MFA for All Users**
   ```bash
   sudo wallix-am auth mfa require --for-all-users
   ```

2. **Use Time-Limited Access**
   - Set maximum session duration
   - Require re-approval for extended access
   - Auto-revoke access after expiration

3. **Implement Least Privilege**
   - Grant minimal necessary access
   - Use role-based policies
   - Regular access reviews

4. **Enable Session Recording**
   ```bash
   sudo wallix-am config set --record-all-sessions true
   sudo wallix-am config set --recording-retention 90d
   ```

5. **Regular Security Audits**
   ```bash
   # Generate security report
   sudo wallix-am audit report --type security --last 30d
   ```

### Operational Best Practices

1. **High Availability Setup**
   - Deploy 2+ Access Manager nodes
   - Use external PostgreSQL cluster
   - Configure load balancer (HAProxy/Nginx)

2. **Backup Configuration**
   ```bash
   # Automated daily backup
   sudo wallix-am backup create --include-db --encrypt

   # Restore from backup
   sudo wallix-am backup restore --file /backup/wallix-am-2026-02-04.tar.gz.enc
   ```

3. **Monitor System Health**
   ```bash
   # Configure health check alerts
   sudo wallix-am alert add \
     --metric cpu_usage \
     --threshold 80 \
     --notify admin@company.com
   ```

4. **Regular Updates**
   ```bash
   # Check for updates
   sudo wallix-am update check

   # Apply updates
   sudo wallix-am update apply --backup-first
   ```

5. **Log Management**
   - Forward logs to SIEM
   - Retain audit logs for compliance period
   - Archive old logs to cold storage

---

## See Also

**Related Sections:**
- [25 - JIT Access](../25-jit-access/README.md) - Just-In-Time access workflows
- [06 - Authentication](../06-authentication/README.md) - Authentication methods
- [07 - Authorization](../07-authorization/README.md) - RBAC and policies
- [44 - User Self-Service](../44-user-self-service/README.md) - Self-service portal
- [11 - High Availability](../11-high-availability/README.md) - HA deployment

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site installation
- [Pre-Production Lab](/pre/README.md) - Lab environment setup

**Official Resources:**
- [WALLIX Access Manager Documentation](https://pam.wallix.one/documentation/admin-doc/am-admin-guide_en.pdf)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Applies to: WALLIX Access Manager 5.2.x*
