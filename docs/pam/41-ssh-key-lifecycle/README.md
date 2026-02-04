# SSH Key Lifecycle Management

This guide provides comprehensive coverage of SSH key management in WALLIX Bastion, including generation, distribution, rotation, revocation, and compliance requirements for enterprise PAM deployments.

---

## Table of Contents

1. [SSH Key Overview](#ssh-key-overview)
2. [Key Architecture](#key-architecture)
3. [Key Generation](#key-generation)
4. [Key Distribution](#key-distribution)
5. [Key Rotation](#key-rotation)
6. [Key Revocation](#key-revocation)
7. [SSH Certificate Authority](#ssh-certificate-authority)
8. [Key Storage Security](#key-storage-security)
9. [Key Audit and Compliance](#key-audit-and-compliance)
10. [Troubleshooting](#troubleshooting)

---

## SSH Key Overview

### SSH Key Types

WALLIX Bastion supports multiple SSH key algorithms for authentication:

```
+==============================================================================+
|                    SSH KEY TYPES AND CHARACTERISTICS                          |
+==============================================================================+

  +------------------------------------------------------------------------+
  | Algorithm   | Key Size      | Security | Performance | Recommendation   |
  +-------------+---------------+----------+-------------+------------------+
  | RSA         | 2048-4096 bit | High     | Slower      | Legacy compat.   |
  | ECDSA       | 256-521 bit   | High     | Fast        | Modern systems   |
  | Ed25519     | 256 bit       | Very High| Very Fast   | RECOMMENDED      |
  | DSA         | 1024 bit      | Low      | Medium      | DO NOT USE       |
  +-------------+---------------+----------+-------------+------------------+

  KEY PAIR STRUCTURE
  ==================

  +------------------------------------------------------------------------+
  |   PRIVATE KEY                         PUBLIC KEY                        |
  |   +---------------------------+       +---------------------------+     |
  |   | -----BEGIN OPENSSH        |       | ssh-ed25519 AAAAC3NzaC1l  |     |
  |   | PRIVATE KEY-----          |       | ZDI1NTE5AAAAILxr8Jgq+bY   |     |
  |   | b3BlbnNzaC1rZXktdjEAA... |       | x9X...user@host            |     |
  |   | -----END OPENSSH          |       +---------------------------+     |
  |   | PRIVATE KEY-----          |                  |                      |
  |   +---------------------------+                  |                      |
  |              |                                   |                      |
  |              | Stored in WALLIX Vault            | Deployed to targets  |
  |              v                                   v                      |
  |   +---------------------------+       +---------------------------+     |
  |   | Credential Vault          |       | ~/.ssh/authorized_keys    |     |
  |   | (Encrypted AES-256-GCM)   |       +---------------------------+     |
  |   +---------------------------+                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Key Lifecycle Stages

| Stage | Description | WALLIX Feature |
|-------|-------------|----------------|
| Generation | Create new key pairs | Built-in key generator |
| Storage | Secure private key storage | Encrypted vault |
| Distribution | Deploy public keys to targets | Automated deployment |
| Usage | Authenticate to target systems | Transparent injection |
| Rotation | Replace old keys with new | Scheduled/on-demand |
| Revocation | Remove compromised keys | Emergency revocation |
| Archival | Retain keys for compliance | Audit retention |

---

## Key Architecture

### SSH Key Flow in WALLIX Bastion

```
+==============================================================================+
|                    SSH KEY ARCHITECTURE IN WALLIX BASTION                     |
+==============================================================================+

                              +------------------+
                              |    WALLIX        |
                              |    BASTION       |
                              +--------+---------+
                                       |
         +-----------------------------+-----------------------------+
         |                             |                             |
         v                             v                             v
  +--------------+            +--------------+            +--------------+
  |   KEY        |            |   SESSION    |            |   TARGET     |
  |   VAULT      |            |   MANAGER    |            |   CONNECTOR  |
  |              |            |              |            |              |
  | * Private    |----------->| * Retrieve   |----------->| * Connect    |
  |   keys       |  Request   |   key from   |  Inject    |   to target  |
  | * Encrypted  |            |   vault      |  Key       | * Authenti-  |
  | * HSM-backed |            | * Session    |            |   cate       |
  |   (optional) |            |   recording  |            |              |
  +--------------+            +--------------+            +--------------+
         |                             |                             |
         v                             v                             v
  +--------------+            +--------------+            +--------------+
  |   KEY        |            |   AUDIT      |            |   TARGET     |
  |   ROTATION   |            |   LOG        |            |   SYSTEM     |
  |   ENGINE     |            | * Key usage  |            | * Linux/Unix |
  | * Scheduled  |            | * Rotation   |            | * Network    |
  | * On-demand  |            |   events     |            | * Cloud      |
  +--------------+            +--------------+            +--------------+

+==============================================================================+
```

### Key Types by Use Case

| Use Case | Key Type | Rotation | Notes |
|----------|----------|----------|-------|
| Service accounts | Ed25519 | 90-180 days | Automated access |
| Human admin access | Ed25519/RSA | 30-90 days | With MFA |
| Emergency access | RSA 4096 | Annual | Break-glass only |
| Network devices | RSA 2048+ | 90-180 days | Legacy compat. |
| Cloud instances | Ed25519 | 30-90 days | Cloud provider |
| OT/ICS systems | RSA 4096 | 180-365 days | Stability needed |

---

## Key Generation

### Generating Keys in WALLIX Bastion

**Via Web Interface:**
```
Configuration > Devices > [Select Device] > Accounts > [Select Account]
    > Credentials > Add New Credential > SSH Key
```

**Via REST API:**

```bash
# Generate Ed25519 key for account
curl -X POST "https://bastion.company.com/api/v2/accounts/acc_12345/credentials" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "ssh_key",
    "ssh_key": {
      "algorithm": "ed25519",
      "comment": "WALLIX managed key - srv-prod-01 root",
      "auto_deploy": true
    }
  }'
```

**Via wabadmin CLI:**

```bash
# Generate SSH key for account
wabadmin ssh-key generate \
    --account "root@srv-prod-01" \
    --algorithm ed25519 \
    --comment "WALLIX managed - Production server"

# Generate RSA key with specific size
wabadmin ssh-key generate \
    --account "admin@switch-core-01" \
    --algorithm rsa \
    --bits 4096 \
    --comment "WALLIX managed - Core switch admin"

# Generate key with passphrase protection
wabadmin ssh-key generate \
    --account "root@srv-secure-01" \
    --algorithm ed25519 \
    --passphrase-protected \
    --comment "High-security server access"
```

### Key Size and Algorithm Recommendations

| Environment | System Type | Algorithm | Size | Rotation |
|-------------|-------------|-----------|------|----------|
| Enterprise | Linux servers | Ed25519 | 256 (fixed) | 90 days |
| Enterprise | Cloud instances | Ed25519 | 256 (fixed) | 30-60 days |
| Enterprise | Legacy network | RSA | 4096 bits | 180 days |
| High-Security | Critical servers | Ed25519 | 256 (fixed) | 30 days |
| High-Security | Financial systems | Ed25519 | 256 (fixed) | 30 days |
| OT/Industrial | Jump hosts | Ed25519 | 256 (fixed) | 90 days |
| OT/Industrial | PLCs (SSH capable) | RSA | 2048 bits | 365 days |

---

## Key Distribution

### Deploying Public Keys to Targets

```
+==============================================================================+
|                    SSH KEY DISTRIBUTION WORKFLOW                              |
+==============================================================================+

  1. KEY GENERATED               2. DEPLOYMENT INITIATED
  +-------------------+          +-------------------+
  | WALLIX Vault      |          | Deployment Engine |
  | +---------------+ |          | * Use bootstrap   |
  | | Private Key   | |--------->|   credentials     |
  | | Public Key    | |          | * Connect to      |
  | +---------------+ |          |   target          |
  +-------------------+          +--------+----------+
                                          |
                                          v
                                 3. KEY DEPLOYED
                                 +-------------------+
                                 | Target System     |
                                 | ~/.ssh/           |
                                 | authorized_keys   |
                                 |                   |
                                 | ssh-ed25519 AAAA..|
                                 | ..WALLIX managed  |
                                 +-------------------+

+==============================================================================+
```

**Deploy Key via API:**

```bash
curl -X POST "https://bastion.company.com/api/v2/accounts/acc_12345/credentials/cred_67890/deploy" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "deployment_method": "ssh",
    "bootstrap_credential": "cred_bootstrap_001",
    "options": { "backup_existing": true, "verify_after_deploy": true }
  }'
```

**Deploy via wabadmin:**

```bash
# Deploy single key
wabadmin ssh-key deploy \
    --account "root@srv-prod-01" \
    --credential-id cred_67890 \
    --verify
```

### Bulk Deployment Procedures

```bash
#!/bin/bash
# bulk-key-deploy.sh - Bulk SSH key deployment

ACCOUNTS_FILE="/tmp/accounts-to-deploy.txt"
LOG_FILE="/var/log/wallix/bulk-deploy-$(date +%Y%m%d).log"

while IFS=',' read -r account_id credential_id; do
    echo "Deploying key for account ${account_id}..." | tee -a ${LOG_FILE}
    wabadmin ssh-key deploy \
        --account-id "${account_id}" \
        --credential-id "${credential_id}" \
        --verify 2>&1 | tee -a ${LOG_FILE}
done < "${ACCOUNTS_FILE}"
```

### authorized_keys Management

```bash
# View current authorized_keys on target
wabadmin ssh-key list-deployed --account "root@srv-prod-01"

# Expected output:
# Authorized Keys for root@srv-prod-01:
# +--------+-------------+-------------------+----------------------+
# | Index  | Algorithm   | Fingerprint       | Comment              |
# +--------+-------------+-------------------+----------------------+
# | 1      | ed25519     | SHA256:xxxx...    | WALLIX managed       |
# | 2      | rsa         | SHA256:yyyy...    | legacy-key (manual)  |
# +--------+-------------+-------------------+----------------------+

# Remove non-WALLIX managed keys (cleanup)
wabadmin ssh-key cleanup \
    --account "root@srv-prod-01" \
    --remove-unmanaged \
    --backup

# Sync authorized_keys with WALLIX
wabadmin ssh-key sync --account "root@srv-prod-01"
```

### Python Bulk Deployment Script

```python
#!/usr/bin/env python3
"""Bulk SSH key deployment script."""

import requests
import json
import time

API_URL = "https://bastion.company.com/api/v2"
API_TOKEN = "your-api-token"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# List of accounts to deploy keys
accounts = [
    {"account_id": "acc_001", "credential_id": "cred_001"},
    {"account_id": "acc_002", "credential_id": "cred_002"},
    {"account_id": "acc_003", "credential_id": "cred_003"},
]

results = []

for account in accounts:
    print(f"Deploying key for {account['account_id']}...")

    response = requests.post(
        f"{API_URL}/accounts/{account['account_id']}/credentials/{account['credential_id']}/deploy",
        headers=headers,
        json={
            "deployment_method": "ssh",
            "options": {"backup_existing": True, "verify_after_deploy": True}
        }
    )

    result = {
        "account_id": account["account_id"],
        "status": response.json().get("status"),
        "message": response.json().get("data", {}).get("status", "unknown")
    }
    results.append(result)
    time.sleep(1)  # Rate limiting

# Print summary
print("\nDeployment Summary:")
for r in results:
    print(f"{r['account_id']}: {r['status']} - {r['message']}")
```

---

## Key Rotation

### Automated Rotation Policies

```bash
# Create SSH key rotation policy via API
curl -X POST "https://bastion.company.com/api/v2/policies/ssh-key-rotation" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "high-security-rotation",
    "enabled": true,
    "scope": {
      "domains": ["Production-Linux", "Critical-Systems"],
      "account_patterns": ["root", "admin", "svc_*"]
    },
    "schedule": {
      "frequency_days": 30,
      "window": { "start": "02:00", "end": "06:00", "timezone": "UTC" },
      "preferred_day": "sunday"
    },
    "options": {
      "zero_downtime": true,
      "verify_after_rotation": true,
      "retry_count": 3
    }
  }'
```

### Zero-Downtime Rotation Workflow

```
+==============================================================================+
|                    ZERO-DOWNTIME SSH KEY ROTATION                             |
+==============================================================================+

  PHASE 1: PREPARATION
  +-----------------------------------------------------------+
  | 1. Generate new key pair                                  |
  | 2. Store new private key in vault (marked as "pending")   |
  +-----------------------------------------------------------+
                         |
                         v
  PHASE 2: PARALLEL KEY DEPLOYMENT
  +-----------------------------------------------------------+
  | 3. Add NEW public key to authorized_keys                  |
  |    (OLD key remains active)                               |
  |                                                           |
  |    authorized_keys:                                       |
  |    ssh-ed25519 AAAA...OLD_KEY... (current)                |
  |    ssh-ed25519 AAAA...NEW_KEY... (pending)  <-- ADDED     |
  +-----------------------------------------------------------+
                         |
                         v
  PHASE 3: VERIFICATION
  +-----------------------------------------------------------+
  | 4. Test authentication with NEW key                       |
  | 5. Verify successful login                                |
  +-----------------------------------------------------------+
                         |
               +---------+---------+
               |                   |
          SUCCESS              FAILURE
               |                   |
               v                   v
  PHASE 4a: COMMIT          PHASE 4b: ROLLBACK
  +-------------------+     +-------------------+
  | 6a. Remove OLD    |     | 6b. Remove NEW    |
  |     key           |     |     key           |
  | 7a. Mark NEW key  |     | 7b. Keep OLD key  |
  |     as "active"   |     |     as "active"   |
  +-------------------+     | 8b. Alert admin   |
                            +-------------------+

+==============================================================================+
```

**Execute Manual Rotation:**

```bash
# Rotate single key with zero-downtime
wabadmin ssh-key rotate \
    --account "root@srv-prod-01" \
    --zero-downtime \
    --verify

# List scheduled rotations
wabadmin ssh-key rotation-schedule list

# Force immediate rotation
wabadmin ssh-key rotate \
    --account "root@srv-prod-01" \
    --force \
    --reason "Security incident response"
```

---

## Key Revocation

### Immediate Revocation Procedures

| Scenario | Urgency | Action |
|----------|---------|--------|
| Key compromised | CRITICAL | Immediate revoke + rotate |
| Employee termination | HIGH | Revoke within 1 hour |
| Role change | MEDIUM | Revoke within 24 hours |
| Orphaned key discovered | MEDIUM | Review and revoke |

**Revoke Key via CLI:**

```bash
# Immediate revocation
wabadmin ssh-key revoke \
    --account "root@srv-prod-01" \
    --credential-id cred_67890 \
    --reason "Key compromised - security incident INC-2026-001" \
    --remove-from-target \
    --force

# Revoke and replace
wabadmin ssh-key revoke \
    --account "root@srv-prod-01" \
    --credential-id cred_67890 \
    --replace \
    --reason "Scheduled key replacement"
```

### Emergency Key Revocation Script

```bash
#!/bin/bash
# emergency-key-revoke.sh

ACCOUNT="$1"
REASON="${2:-Emergency revocation}"
INCIDENT_ID="INC-$(date +%Y%m%d%H%M%S)"

echo "EMERGENCY SSH KEY REVOCATION"
echo "Account: ${ACCOUNT}"
echo "Incident ID: ${INCIDENT_ID}"

# Get all credentials for account
credentials=$(wabadmin ssh-key list --account "${ACCOUNT}" --format json | jq -r '.[].credential_id')

for cred_id in ${credentials}; do
    wabadmin ssh-key revoke \
        --account "${ACCOUNT}" \
        --credential-id "${cred_id}" \
        --reason "${REASON} - ${INCIDENT_ID}" \
        --remove-from-target \
        --force
done

# Generate replacement key
wabadmin ssh-key generate --account "${ACCOUNT}" --algorithm ed25519
wabadmin ssh-key deploy --account "${ACCOUNT}" --verify

logger -p auth.crit "SSH Key Emergency Revocation: ${ACCOUNT} - ${INCIDENT_ID}"
```

### Orphaned Key Cleanup

```bash
# Discover orphaned keys
wabadmin ssh-key audit --discover-orphaned

# Remove orphaned keys with backup
wabadmin ssh-key cleanup-orphaned \
    --target "srv-prod-01" \
    --user "root" \
    --fingerprint "SHA256:unknown1" \
    --reason "Orphaned key cleanup" \
    --backup
```

---

## SSH Certificate Authority

### Using WALLIX as SSH CA

```
+==============================================================================+
|                    SSH CERTIFICATE AUTHORITY FLOW                             |
+==============================================================================+

  +---------------+          +---------------+          +-------------+
  |    USER       |          |   WALLIX      |          |   TARGET    |
  |               |          |   SSH CA      |          |   SYSTEM    |
  +-------+-------+          +-------+-------+          +------+------+
          |                          |                         |
          | 1. Request session       |                         |
          |------------------------->|                         |
          |                          |                         |
          |          2. Generate short-lived certificate       |
          |          +-------------------+                     |
          |          | User: jsmith      |                     |
          |          | Principals: root  |                     |
          |          | Valid: 8 hours    |                     |
          |          | Signed by: CA     |                     |
          |          +-------------------+                     |
          |                          |                         |
          |          3. Connect with certificate               |
          |                          |------------------------>|
          |                          |                         |
          |                          |     4. Verify CA sig    |
          |                          |     5. Check validity   |
          |                          |                         |
          |          6. Session established                    |
          |<----------------------------------------------------|

+==============================================================================+
```

**Configure SSH CA:**

```bash
# Initialize SSH CA
wabadmin ssh-ca init --key-type ed25519 --validity-years 10

# Export CA public key for targets
wabadmin ssh-ca export-public > /tmp/wallix-ssh-ca.pub

# On target systems:
cat /tmp/wallix-ssh-ca.pub >> /etc/ssh/ca_keys
echo "TrustedUserCAKeys /etc/ssh/ca_keys" >> /etc/ssh/sshd_config
systemctl restart sshd
```

**Generate User Certificates:**

```bash
wabadmin ssh-ca sign-user \
    --user "jsmith" \
    --principals "root,admin" \
    --validity "8h" \
    --extensions "permit-pty,permit-port-forwarding"
```

### Certificate Validity Periods

| Certificate Type | Validity | Use Case |
|-----------------|----------|----------|
| Interactive session | 1-8 hours | User access |
| Automated task | 15-60 minutes | CI/CD, scripts |
| Service account | 24-72 hours | Long-running services |
| Emergency access | 1-4 hours | Break-glass |

### Host Certificates

WALLIX can also sign host certificates for target systems:

```bash
# Sign host key certificate
wabadmin ssh-ca sign-host \
    --hostname "srv-prod-01.company.com" \
    --host-key /etc/ssh/ssh_host_ed25519_key.pub \
    --validity "365d" \
    --principals "srv-prod-01,srv-prod-01.company.com,10.100.1.50"

# Deploy host certificate to target
# On target system:
# 1. Copy certificate to /etc/ssh/ssh_host_ed25519_key-cert.pub
# 2. Add to sshd_config: HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
# 3. Restart sshd

# List active host certificates
wabadmin ssh-ca list-host-certs --status active
```

### Certificate Revocation

```bash
# Revoke a user certificate
wabadmin ssh-ca revoke-cert --serial 1234567890 --reason "User terminated"

# Generate Key Revocation List (KRL)
wabadmin ssh-ca generate-krl --output /etc/ssh/revoked_keys

# Configure sshd to use KRL
# Add to sshd_config: RevokedKeys /etc/ssh/revoked_keys

# Distribute KRL to all targets
wabadmin ssh-ca distribute-krl --targets-file /tmp/all-targets.txt
```

---

## Key Storage Security

### Vault Storage for Private Keys

```
+==============================================================================+
|                    SSH KEY STORAGE SECURITY                                   |
+==============================================================================+

  ENCRYPTION LAYERS
  =================

  LAYER 1: Database Encryption
  +-----------------------------------------------------------+
  | PostgreSQL with TDE (Transparent Data Encryption)         |
  +-----------------------------------------------------------+
                              |
                              v
  LAYER 2: Credential Encryption
  +-----------------------------------------------------------+
  | Each SSH private key encrypted with AES-256-GCM           |
  | Unique IV per encryption operation                        |
  +-----------------------------------------------------------+
                              |
                              v
  LAYER 3: Master Key Protection
  +-----------------------------------------------------------+
  | Master encryption key derived using Argon2ID              |
  | Options: Software-protected or HSM-protected              |
  +-----------------------------------------------------------+

+==============================================================================+
```

### HSM Integration

```bash
# Configure HSM for SSH key storage
wabadmin hsm configure \
    --type thales-luna \
    --slot 1 \
    --pin-file /etc/wallix/hsm/pin.enc

# Migrate existing keys to HSM protection
wabadmin hsm migrate-keys --key-types ssh --batch-size 100

# Verify HSM-protected keys
wabadmin ssh-key list --hsm-protected
```

### Key Encryption at Rest

```bash
# View key encryption status
wabadmin vault-status --key-encryption

# Expected output:
# Vault Key Encryption Status
# ===========================
# Encryption Algorithm: AES-256-GCM
# Key Derivation: Argon2ID
# Master Key Storage: HSM (slot 1)
#
# Credential Encryption Stats:
# +------------------+---------+------------+
# | Credential Type  | Count   | Encrypted  |
# +------------------+---------+------------+
# | SSH Keys         | 1,247   | 100%       |
# | Passwords        | 3,891   | 100%       |
# | Certificates     | 156     | 100%       |
# +------------------+---------+------------+

# Re-encrypt keys with new master key
wabadmin vault rekey --new-key-from-hsm --backup-before-rekey
```

### Private Key Backup Procedures

```bash
#!/bin/bash
# key-backup.sh - Secure backup of SSH private keys

BACKUP_DIR="/var/backup/wallix/keys"
DATE=$(date +%Y%m%d)
GPG_RECIPIENT="security@company.com"

mkdir -p ${BACKUP_DIR}

# Export and encrypt all SSH keys
wabadmin ssh-key export-all \
    --format encrypted \
    --output ${BACKUP_DIR}/ssh-keys-${DATE}.enc

# Or use GPG for additional encryption
wabadmin ssh-key export-all --format json | \
    gpg --encrypt --recipient ${GPG_RECIPIENT} \
    --output ${BACKUP_DIR}/ssh-keys-${DATE}.gpg

# Set restrictive permissions
chmod 600 ${BACKUP_DIR}/*.gpg ${BACKUP_DIR}/*.enc

# Log backup
logger -t key-backup "SSH key backup created: ssh-keys-${DATE}"

# Cleanup old backups (keep last 7)
ls -t ${BACKUP_DIR}/ssh-keys-*.gpg 2>/dev/null | tail -n +8 | xargs -r rm -f
```

---

## Key Audit and Compliance

### Key Inventory Reporting

```bash
# Generate SSH key inventory report
wabadmin ssh-key report inventory \
    --format csv \
    --output /var/reports/ssh-key-inventory-$(date +%Y%m%d).csv

# Key rotation compliance check
wabadmin ssh-key audit rotation-compliance --max-age-days 90 --format json
```

### Compliance Evidence (SOC2, PCI-DSS)

| SOC2 Control | SSH Key Requirement | WALLIX Feature |
|--------------|---------------------|----------------|
| CC6.1 - Logical Access | Unique keys per account | Per-account keys |
| CC6.2 - Access Registration | Key lifecycle management | Rotation policies |
| CC6.3 - Access Removal | Key deprovisioning | Revocation process |
| CC6.6 - Encryption | Key encryption at rest | AES-256-GCM vault |

| PCI-DSS Requirement | SSH Key Requirement | WALLIX Feature |
|---------------------|---------------------|----------------|
| 8.2.4 - Strong Auth | Minimum key strength | Algorithm policy |
| 8.3.1 - MFA for Admin | Key + second factor | MFA integration |
| 8.3.4 - Key Management | Key rotation every 90 days | Rotation policies |
| 10.2 - Audit Logs | Key usage logging | Session audit |

```bash
# Generate compliance reports
wabadmin ssh-key report compliance --framework soc2 --period "2025-01-01:2025-12-31"
wabadmin ssh-key report compliance --framework pci-dss --period "2025-10-01:2025-12-31"
```

### Key Age Tracking

```bash
# List keys by age
wabadmin ssh-key list --sort-by age --order desc

# Expected output:
# SSH Keys by Age:
# +----------------------+-------------+--------------+---------+------------+
# | Account              | Algorithm   | Created      | Age     | Status     |
# +----------------------+-------------+--------------+---------+------------+
# | svc_legacy@srv-old   | rsa         | 2024-06-15   | 580d    | WARNING    |
# | admin@srv-dev-01     | ed25519     | 2025-03-20   | 300d    | WARNING    |
# | root@srv-prod-01     | ed25519     | 2025-10-15   | 92d     | OK         |
# | admin@srv-prod-02    | ed25519     | 2026-01-10   | 5d      | OK         |
# +----------------------+-------------+--------------+---------+------------+

# Set up age-based alerts
wabadmin alert-create \
    --name "ssh-key-age-warning" \
    --type ssh_key_age \
    --threshold-days 75 \
    --severity warning \
    --action "email:security@company.com"

wabadmin alert-create \
    --name "ssh-key-age-critical" \
    --type ssh_key_age \
    --threshold-days 90 \
    --severity critical \
    --action "email:security@company.com,syslog:siem.company.com"
```

### Key Usage Audit

```bash
# View key usage history
wabadmin ssh-key audit usage \
    --account "root@srv-prod-01" \
    --period "30d"

# Expected output:
# SSH Key Usage for root@srv-prod-01 (last 30 days):
# +---------------------+-----------+------------------+----------+
# | Timestamp           | User      | Source IP        | Duration |
# +---------------------+-----------+------------------+----------+
# | 2026-01-15 14:30:00 | jsmith    | 10.100.1.50      | 45m      |
# | 2026-01-14 09:15:00 | mjones    | 10.100.1.51      | 2h 15m   |
# | 2026-01-13 16:45:00 | jsmith    | 10.100.1.50      | 30m      |
# +---------------------+-----------+------------------+----------+

# Export audit log for compliance
wabadmin ssh-key audit export \
    --period "2025-01-01:2025-12-31" \
    --format csv \
    --output /var/reports/ssh-key-audit-2025.csv
```

---

## Troubleshooting

### Key Authentication Failures

```
+==============================================================================+
|                    SSH KEY TROUBLESHOOTING GUIDE                              |
+==============================================================================+

  ERROR: PERMISSION DENIED (PUBLICKEY)
  ====================================

  Diagnostic Steps:
  +------------------------------------------------------------------------+
  | # 1. Verify key exists in WALLIX vault                                  |
  | wabadmin ssh-key list --account "root@srv-prod-01"                     |
  |                                                                         |
  | # 2. Check key is deployed to target                                    |
  | wabadmin ssh-key verify-deployment --account "root@srv-prod-01"        |
  |                                                                         |
  | # 3. Test direct SSH with verbose output                                |
  | ssh -vvv -i /tmp/test-key root@srv-prod-01 2>&1 | grep -i auth         |
  |                                                                         |
  | # 4. Check target authorized_keys permissions                           |
  | # On target: ls -la ~/.ssh/ (expect drwx------ and -rw-------)         |
  +------------------------------------------------------------------------+

  Common Causes and Solutions:
  +-------------------------------+-----------------------------------------+
  | Cause                         | Solution                                |
  +-------------------------------+-----------------------------------------+
  | Key not deployed              | wabadmin ssh-key deploy                 |
  | Wrong key deployed            | Verify fingerprints match               |
  | authorized_keys permissions   | chmod 600 ~/.ssh/authorized_keys        |
  | .ssh directory permissions    | chmod 700 ~/.ssh                        |
  | SELinux context               | restorecon -R ~/.ssh                    |
  | Key algorithm not supported   | Use RSA for older systems               |
  +-------------------------------+-----------------------------------------+

  ERROR: HOST KEY VERIFICATION FAILED
  ====================================

  Resolution:
  +------------------------------------------------------------------------+
  | # If host key legitimately changed:                                     |
  | wabadmin ssh host-key update \                                         |
  |     --target "srv-prod-01" \                                           |
  |     --accept-new \                                                     |
  |     --reason "OS reinstallation - ticket CHANGE-12345"                 |
  |                                                                         |
  | # WARNING: Never blindly accept changed host keys                       |
  +------------------------------------------------------------------------+

  ERROR: KEY FORMAT NOT RECOGNIZED
  =================================

  Resolution:
  +------------------------------------------------------------------------+
  | # Convert PEM to OpenSSH format                                         |
  | ssh-keygen -p -m PEM -f /tmp/key.pem -N "" -P ""                       |
  |                                                                         |
  | # Verify key after conversion                                           |
  | ssh-keygen -lf /tmp/key.pem                                            |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Permission Issues

```bash
# Check and fix target SSH permissions
wabadmin ssh-key diagnose-permissions --account "root@srv-prod-01" --fix

# Expected output:
# SSH Permission Diagnostic for root@srv-prod-01
# ==============================================
#
# Checking /root/.ssh:
#   Current: drwxr-xr-x (755)
#   Required: drwx------ (700)
#   Status: NEEDS FIX
#   Action: chmod 700 /root/.ssh
#
# Checking /root/.ssh/authorized_keys:
#   Current: -rw-r--r-- (644)
#   Required: -rw------- (600)
#   Status: NEEDS FIX
#   Action: chmod 600 /root/.ssh/authorized_keys
#
# Applying fixes...
# All permissions corrected.
```

### Comprehensive Diagnostics

```bash
# Full diagnostic report
wabadmin ssh-key diagnose --account "root@srv-prod-01"

# Expected output:
# SSH Key Diagnostic Report for root@srv-prod-01
# ===============================================
#
# VAULT STATUS
# ------------
# Key exists in vault: YES
# Key ID: cred_67890
# Algorithm: Ed25519
# Created: 2025-10-15
# Last rotated: 2026-01-15
# Passphrase protected: NO
# HSM protected: YES
#
# DEPLOYMENT STATUS
# -----------------
# Target reachable: YES (latency: 15ms)
# Key deployed: YES
# Fingerprint match: YES
#
# TARGET CONFIGURATION
# --------------------
# SSHD running: YES
# PubkeyAuthentication: yes
# AuthorizedKeysFile: .ssh/authorized_keys
#
# PERMISSION CHECK
# ----------------
# ~/.ssh: 700 (OK)
# ~/.ssh/authorized_keys: 600 (OK)
#
# TEST CONNECTION
# ---------------
# Authentication test: SUCCESS
#
# OVERALL STATUS: HEALTHY

# Check rotation health
wabadmin ssh-key rotation-health

# Expected output:
# SSH Key Rotation Health
# =======================
#
# Rotation Engine: RUNNING
# Last rotation: 2026-01-15 03:15:00
# Next scheduled: 2026-01-22 03:00:00
#
# Rotation Statistics (last 30 days):
# +---------------+---------+
# | Metric        | Value   |
# +---------------+---------+
# | Total rotated | 412     |
# | Successful    | 408     |
# | Failed        | 4       |
# | Success rate  | 99.0%   |
# +---------------+---------+
```

### Key Import Issues

```bash
# Import existing key with format detection
wabadmin ssh-key import \
    --account "root@srv-legacy-01" \
    --file /tmp/existing-key \
    --auto-detect-format

# Import with explicit passphrase
wabadmin ssh-key import \
    --account "root@srv-secure-01" \
    --file /tmp/encrypted-key \
    --passphrase-file /tmp/passphrase.txt

# Validate key before import
wabadmin ssh-key validate --file /tmp/key-to-check

# Expected output:
# SSH Key Validation
# ==================
# File: /tmp/key-to-check
# Type: Private Key
# Algorithm: Ed25519
# Format: OpenSSH
# Passphrase: None
# Fingerprint: SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Status: VALID
```

---

## Quick Reference

### SSH Key Commands Cheat Sheet

| Task | Command |
|------|---------|
| Generate key | `wabadmin ssh-key generate --account "user@host" --algorithm ed25519` |
| Deploy key | `wabadmin ssh-key deploy --account "user@host" --verify` |
| List keys | `wabadmin ssh-key list --account "user@host"` |
| Rotate key | `wabadmin ssh-key rotate --account "user@host" --zero-downtime` |
| Revoke key | `wabadmin ssh-key revoke --account "user@host" --remove-from-target` |
| Export public | `wabadmin ssh-key export-public --account "user@host"` |
| Diagnose | `wabadmin ssh-key diagnose --account "user@host"` |

### Key Algorithm Quick Reference

| Algorithm | Key Size | Security Level | Use Case |
|-----------|----------|----------------|----------|
| Ed25519 | 256 bits | 128-bit equivalent | Modern (recommended) |
| ECDSA P-384 | 384 bits | 192-bit equivalent | FIPS compliance |
| RSA | 4096 bits | ~140-bit equivalent | Legacy compatibility |
| RSA | 2048 bits | ~112-bit equivalent | Minimum acceptable |

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [OpenSSH Key Types](https://www.openssh.com/manual.html)
- [NIST SP 800-57 Key Management Guidelines](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
- [SSH Certificate Authority](https://man.openbsd.org/ssh-keygen#CERTIFICATES)

---

## See Also

**Related Sections:**
- [08 - Password Management](../08-password-management/README.md) - Credential management overview
- [42 - Service Account Lifecycle](../42-service-account-lifecycle/README.md) - Service account governance

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: February 2026*
