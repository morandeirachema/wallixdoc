# WALLIX Bastion Ansible Automation

> Production-ready Ansible playbooks for automating WALLIX Bastion PAM operations.

---

## Overview

This collection provides playbooks for common WALLIX Bastion automation tasks:

| Playbook | Description |
|----------|-------------|
| `provision_devices.yml` | Bulk device onboarding from inventory or CMDB |
| `provision_users.yml` | User lifecycle management (create/update/disable) |
| `manage_accounts.yml` | Privileged account management and rotation |
| `manage_authorizations.yml` | Authorization policies and access control |
| `health_check.yml` | System health monitoring and alerting |
| `backup_config.yml` | Configuration export and backup |
| `sync_from_cmdb.yml` | Synchronize with ServiceNow/external CMDB |

---

## Quick Start

### 1. Install Requirements

```bash
# Ansible 2.12+ required
pip install ansible>=2.12

# Install collection dependencies
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure Inventory

```bash
cp inventory/hosts.example.yml inventory/hosts.yml
# Edit with your WALLIX Bastion details
```

### 3. Set Credentials

```bash
# Option 1: Environment variables (recommended)
export WALLIX_HOST="bastion.company.com"
export WALLIX_API_KEY="your-api-key"
export WALLIX_USER="api-user"

# Option 2: Ansible Vault
ansible-vault create group_vars/all/vault.yml
```

### 4. Run Playbook

```bash
# Dry run (check mode)
ansible-playbook playbooks/provision_devices.yml --check

# Execute
ansible-playbook playbooks/provision_devices.yml
```

---

## Directory Structure

```
ansible/
├── README.md                      # This file
├── requirements.yml               # Collection dependencies
├── ansible.cfg                    # Ansible configuration
│
├── inventory/
│   ├── hosts.example.yml          # Example inventory
│   ├── group_vars/
│   │   └── all/
│   │       ├── wallix.yml         # WALLIX connection settings
│   │       └── vault.yml          # Encrypted credentials
│   └── host_vars/                 # Per-host variables
│
├── roles/
│   └── wallix_bastion/            # Reusable role
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── auth.yml           # Authentication
│       │   ├── devices.yml        # Device operations
│       │   ├── accounts.yml       # Account operations
│       │   ├── users.yml          # User operations
│       │   └── authorizations.yml # Authorization operations
│       ├── defaults/main.yml      # Default variables
│       └── vars/main.yml          # Role variables
│
├── playbooks/
│   ├── provision_devices.yml      # Device provisioning
│   ├── provision_users.yml        # User provisioning
│   ├── manage_accounts.yml        # Account management
│   ├── manage_authorizations.yml  # Authorization management
│   ├── health_check.yml           # Health monitoring
│   ├── backup_config.yml          # Configuration backup
│   └── sync_from_cmdb.yml         # CMDB synchronization
│
├── files/
│   └── csv/                       # Sample CSV imports
│       ├── devices.csv
│       ├── users.csv
│       └── accounts.csv
│
└── templates/
    └── reports/                   # Report templates
        └── health_report.html.j2
```

---

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WALLIX_HOST` | Yes | WALLIX Bastion hostname |
| `WALLIX_API_KEY` | Yes | API key for authentication |
| `WALLIX_USER` | Yes | API username |
| `WALLIX_VERIFY_SSL` | No | SSL verification (default: true) |
| `WALLIX_API_VERSION` | No | API version (default: v3.12) |

### Inventory Variables

```yaml
# group_vars/all/wallix.yml
wallix_host: "{{ lookup('env', 'WALLIX_HOST') }}"
wallix_api_key: "{{ lookup('env', 'WALLIX_API_KEY') }}"
wallix_user: "{{ lookup('env', 'WALLIX_USER') }}"
wallix_verify_ssl: true
wallix_api_version: "v3.12"
wallix_base_url: "https://{{ wallix_host }}/api/{{ wallix_api_version }}"
```

---

## Playbook Examples

### Provision Devices from CSV

```bash
# devices.csv format:
# device_name,host,domain,description,services
# srv-web-01,192.168.1.10,Production,Web Server,SSH:22;HTTPS:443

ansible-playbook playbooks/provision_devices.yml \
  -e "csv_file=files/csv/devices.csv" \
  -e "domain=Production"
```

### Bulk User Provisioning

```bash
# From LDAP/AD sync
ansible-playbook playbooks/provision_users.yml \
  -e "source=ldap" \
  -e "ldap_group=PAM-Users"

# From CSV
ansible-playbook playbooks/provision_users.yml \
  -e "source=csv" \
  -e "csv_file=files/csv/users.csv"
```

### Password Rotation

```bash
# Rotate all accounts in a domain
ansible-playbook playbooks/manage_accounts.yml \
  -e "action=rotate" \
  -e "domain=Production"

# Rotate specific accounts
ansible-playbook playbooks/manage_accounts.yml \
  -e "action=rotate" \
  -e "accounts=['root@srv-web-01','admin@srv-db-01']"
```

### Health Check with Alerting

```bash
ansible-playbook playbooks/health_check.yml \
  -e "alert_email=pam-admins@company.com" \
  -e "slack_webhook=https://hooks.slack.com/services/xxx"
```

---

## Role Reference

### wallix_bastion Role

#### Variables

```yaml
# Required
wallix_host: ""
wallix_api_key: ""
wallix_user: ""

# Optional
wallix_verify_ssl: true
wallix_api_version: "v3.12"
wallix_timeout: 30
wallix_retries: 3

# Operation modes
wallix_check_mode: false      # Dry run
wallix_ignore_errors: false   # Continue on errors
```

#### Tasks

| Task | Description |
|------|-------------|
| `auth` | Authenticate and get session token |
| `devices` | CRUD operations on devices |
| `accounts` | Account management and rotation |
| `users` | User lifecycle management |
| `authorizations` | Authorization policy management |

---

## Integration Examples

### ServiceNow CMDB Sync

```yaml
# sync_from_cmdb.yml excerpt
- name: Query ServiceNow for servers
  servicenow.itsm.api:
    resource: cmdb_ci_server
    query:
      operational_status: "1"  # Operational
      u_pam_managed: "true"
  register: servicenow_servers

- name: Sync servers to WALLIX
  include_role:
    name: wallix_bastion
    tasks_from: devices
  vars:
    wallix_devices: "{{ servicenow_servers.records | map('wallix_device_format') }}"
```

### CI/CD Pipeline (GitLab)

```yaml
# .gitlab-ci.yml
provision-pam:
  stage: deploy
  image: ansible/ansible:latest
  script:
    - ansible-playbook playbooks/provision_devices.yml
  variables:
    WALLIX_HOST: $PAM_HOST
    WALLIX_API_KEY: $PAM_API_KEY
  only:
    - main
```

### AWX/Tower Job Template

```yaml
# Job Template Configuration
name: "WALLIX - Provision Devices"
job_type: "run"
inventory: "PAM Inventory"
project: "PAM Automation"
playbook: "playbooks/provision_devices.yml"
credentials:
  - "WALLIX API Credential"
extra_vars:
  domain: "Production"
  dry_run: false
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| SSL certificate errors | Set `wallix_verify_ssl: false` or add CA cert |
| 401 Unauthorized | Verify API key and username |
| 403 Forbidden | Check API key permissions |
| Connection timeout | Increase `wallix_timeout` |
| Rate limiting (429) | Playbooks auto-retry with backoff |

### Debug Mode

```bash
# Verbose output
ansible-playbook playbooks/provision_devices.yml -vvv

# Debug specific task
ANSIBLE_DEBUG=true ansible-playbook playbooks/health_check.yml
```

### Log Files

```bash
# Playbook logs
/var/log/ansible/wallix_automation.log

# WALLIX API audit (on bastion)
/var/log/wab/wabengine/api.log
```

---

## Security Considerations

| Practice | Implementation |
|----------|----------------|
| Credential storage | Use Ansible Vault or external secrets manager |
| API key rotation | Rotate keys quarterly; use separate keys per environment |
| Network security | Restrict API access by source IP |
| Audit logging | All API calls logged on WALLIX Bastion |
| Least privilege | Create API keys with minimal required permissions |

### Vault Example

```bash
# Create encrypted vault
ansible-vault create group_vars/all/vault.yml

# Content:
vault_wallix_api_key: "your-secret-key"
vault_wallix_password: "your-password"

# Run with vault
ansible-playbook playbooks/provision_devices.yml --ask-vault-pass
```

---

## Resources

| Resource | URL |
|----------|-----|
| WALLIX REST API | https://github.com/wallix/wbrest_samples |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |
| Ansible URI Module | https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html |
| Ansible Vault | https://docs.ansible.com/ansible/latest/vault_guide/index.html |

---

## Version Compatibility

| Ansible | WALLIX Bastion | API Version | Status |
|---------|----------------|-------------|--------|
| 2.12+ | 12.x | v3.12 | Current |
| 2.10+ | 11.x | v3.6 | Supported |
| 2.9 | 10.x | v3.3 | Legacy |
