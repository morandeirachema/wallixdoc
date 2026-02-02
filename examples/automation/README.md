# DevOps Automation Examples

## Infrastructure as Code for WALLIX WALLIX Bastion

This directory contains automation examples for deploying and managing WALLIX WALLIX Bastion using modern DevOps practices.

---

## Contents

1. [Ansible Playbooks](#ansible-playbooks)
2. [Terraform Examples](#terraform-examples)
3. [GitOps Patterns](#gitops-patterns)
4. [CI/CD Integration](#cicd-integration)
5. [Python SDK Examples](#python-sdk-examples)

---

## Ansible Playbooks

### Inventory Structure

```yaml
# inventory/production.yml

all:
  children:
    wallix:
      hosts:
        wallix-prod-01:
          ansible_host: 10.1.1.10
          wallix_role: primary
        wallix-prod-02:
          ansible_host: 10.1.1.11
          wallix_role: secondary
      vars:
        wallix_url: "https://bastion.company.com"
        wallix_api_user: "ansible-svc"
        # API key stored in Ansible Vault
```

### Device Onboarding Playbook

```yaml
# playbooks/onboard-devices.yml

---
- name: Onboard devices to WALLIX WALLIX Bastion
  hosts: localhost
  gather_facts: false

  vars_files:
    - ../vars/wallix-credentials.yml  # Ansible Vault encrypted

  vars:
    wallix_url: "https://bastion.company.com"
    devices:
      - name: srv-web-01
        host: 10.1.10.10
        domain: Linux-Production
        description: Production web server
        services:
          - protocol: SSH
            port: 22
        accounts:
          - name: root
            password: "{{ vault_srv_web_01_root_pass }}"

      - name: srv-db-01
        host: 10.1.10.20
        domain: Linux-Production
        description: Production database server
        services:
          - protocol: SSH
            port: 22
        accounts:
          - name: root
            password: "{{ vault_srv_db_01_root_pass }}"
          - name: mysql
            password: "{{ vault_srv_db_01_mysql_pass }}"

  tasks:
    - name: Authenticate to WALLIX API
      uri:
        url: "{{ wallix_url }}/api/auth"
        method: POST
        body_format: json
        body:
          user: "{{ wallix_api_user }}"
          password: "{{ wallix_api_password }}"
        validate_certs: yes
        status_code: 200
      register: auth_response
      no_log: true

    - name: Set API token
      set_fact:
        api_token: "{{ auth_response.json.token }}"
      no_log: true

    - name: Create devices
      uri:
        url: "{{ wallix_url }}/api/devices"
        method: POST
        headers:
          X-Auth-Token: "{{ api_token }}"
        body_format: json
        body:
          device_name: "{{ item.name }}"
          host: "{{ item.host }}"
          domain: "{{ item.domain }}"
          description: "{{ item.description }}"
        validate_certs: yes
        status_code: [200, 201, 409]  # 409 = already exists
      loop: "{{ devices }}"
      loop_control:
        label: "{{ item.name }}"

    - name: Add services to devices
      uri:
        url: "{{ wallix_url }}/api/devices/{{ item.0.name }}/services"
        method: POST
        headers:
          X-Auth-Token: "{{ api_token }}"
        body_format: json
        body:
          service_name: "{{ item.1.protocol | lower }}"
          protocol: "{{ item.1.protocol }}"
          port: "{{ item.1.port }}"
        validate_certs: yes
        status_code: [200, 201, 409]
      loop: "{{ devices | subelements('services') }}"
      loop_control:
        label: "{{ item.0.name }} - {{ item.1.protocol }}"

    - name: Add accounts to devices
      uri:
        url: "{{ wallix_url }}/api/devices/{{ item.0.name }}/accounts"
        method: POST
        headers:
          X-Auth-Token: "{{ api_token }}"
        body_format: json
        body:
          account_name: "{{ item.1.name }}"
          credentials:
            - type: password
              password: "{{ item.1.password }}"
          auto_change_password: true
        validate_certs: yes
        status_code: [200, 201, 409]
      loop: "{{ devices | subelements('accounts') }}"
      loop_control:
        label: "{{ item.0.name }} - {{ item.1.name }}"
      no_log: true  # Hide passwords in output
```

### User Management Playbook

```yaml
# playbooks/manage-users.yml

---
- name: Manage WALLIX users from LDAP groups
  hosts: localhost
  gather_facts: false

  vars_files:
    - ../vars/wallix-credentials.yml

  vars:
    ldap_groups_to_sync:
      - ldap_group: "CN=IT-Admins,OU=Groups,DC=corp,DC=com"
        wallix_group: "IT-Admins"
      - ldap_group: "CN=OT-Engineers,OU=Groups,DC=corp,DC=com"
        wallix_group: "OT-Engineers"

  tasks:
    - name: Get WALLIX user groups
      uri:
        url: "{{ wallix_url }}/api/usergroups"
        method: GET
        headers:
          X-Auth-Token: "{{ api_token }}"
        validate_certs: yes
      register: usergroups

    - name: Ensure user groups exist
      uri:
        url: "{{ wallix_url }}/api/usergroups"
        method: POST
        headers:
          X-Auth-Token: "{{ api_token }}"
        body_format: json
        body:
          group_name: "{{ item.wallix_group }}"
          description: "Synced from LDAP"
        validate_certs: yes
        status_code: [200, 201, 409]
      loop: "{{ ldap_groups_to_sync }}"
      loop_control:
        label: "{{ item.wallix_group }}"
```

### Password Rotation Playbook

```yaml
# playbooks/rotate-passwords.yml

---
- name: Trigger password rotation for all accounts
  hosts: localhost
  gather_facts: false

  vars_files:
    - ../vars/wallix-credentials.yml

  vars:
    target_domains:
      - Linux-Production
      - Windows-Production

  tasks:
    - name: Get all accounts in target domains
      uri:
        url: "{{ wallix_url }}/api/accounts?domain={{ item }}"
        method: GET
        headers:
          X-Auth-Token: "{{ api_token }}"
        validate_certs: yes
      loop: "{{ target_domains }}"
      register: accounts_response

    - name: Trigger rotation for each account
      uri:
        url: "{{ wallix_url }}/api/accounts/{{ item.account_name }}/password/change"
        method: POST
        headers:
          X-Auth-Token: "{{ api_token }}"
        validate_certs: yes
        status_code: [200, 202]
      loop: "{{ accounts_response.results | map(attribute='json') | flatten }}"
      loop_control:
        label: "{{ item.account_name }}"
      when: item.auto_change_password | default(false)
```

---

## Terraform Examples

### Provider Configuration

```hcl
# terraform/providers.tf

terraform {
  required_providers {
    wallix-wallix = {
      source  = "wallix/wallix-wallix"
      version = "~> 0.14.0"
    }
  }
}

provider "wallix-wallix" {
  ip        = var.wallix_host
  port      = 443
  user      = var.wallix_user
  password  = var.wallix_password
  api_version = "v3.12"
}
```

### Variables

```hcl
# terraform/variables.tf

variable "wallix_host" {
  description = "WALLIX WALLIX Bastion hostname or IP"
  type        = string
}

variable "wallix_user" {
  description = "API user"
  type        = string
}

variable "wallix_password" {
  description = "API password"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}
```

### Domain and Device Resources

```hcl
# terraform/main.tf

# Create domain
resource "wallix-wallix_domain" "linux_production" {
  domain_name = "Linux-Production"
  description = "Production Linux servers"
}

# Create device
resource "wallix-wallix_device" "web_server" {
  device_name = "srv-web-01"
  host        = "10.1.10.10"
  domain      = wallix-wallix_domain.linux_production.domain_name
  description = "Production web server"
}

# Add SSH service
resource "wallix-wallix_device_service" "web_server_ssh" {
  device_id     = wallix-wallix_device.web_server.id
  service_name  = "ssh"
  protocol      = "SSH"
  port          = 22
  subprotocols  = ["SSH_SHELL_SESSION", "SSH_SCP_UP", "SSH_SCP_DOWN", "SFTP_SESSION"]
}

# Add account
resource "wallix-wallix_device_local_account" "web_server_root" {
  device_id          = wallix-wallix_device.web_server.id
  account_name       = "root"
  account_login      = "root"
  auto_change_password = true

  credentials {
    type     = "password"
    password = var.initial_password
  }
}
```

### User Group and Authorization

```hcl
# terraform/authorizations.tf

# User group
resource "wallix-wallix_usergroup" "linux_admins" {
  group_name  = "Linux-Admins"
  description = "Linux system administrators"
}

# Target group
resource "wallix-wallix_targetgroup" "linux_root" {
  group_name  = "Linux-Prod-Root"
  description = "Root accounts on production Linux"
}

# Add device to target group
resource "wallix-wallix_targetgroup_member" "web_server_root" {
  targetgroup_id = wallix-wallix_targetgroup.linux_root.id
  member_type    = "account"
  member_id      = wallix-wallix_device_local_account.web_server_root.id
}

# Authorization
resource "wallix-wallix_authorization" "linux_admins_root" {
  authorization_name = "linux-admins-root-access"
  user_group         = wallix-wallix_usergroup.linux_admins.group_name
  target_group       = wallix-wallix_targetgroup.linux_root.group_name

  subprotocols = [
    "SSH_SHELL_SESSION",
    "SSH_SCP_UP",
    "SSH_SCP_DOWN",
    "SFTP_SESSION"
  ]

  is_recorded     = true
  is_critical     = false
  approval_required = false
}
```

### Multi-Environment Module

```hcl
# terraform/modules/wallix-environment/main.tf

variable "environment" {}
variable "devices" {}

resource "wallix-wallix_domain" "env_domain" {
  domain_name = "${var.environment}-servers"
  description = "${var.environment} environment servers"
}

resource "wallix-wallix_device" "servers" {
  for_each = { for d in var.devices : d.name => d }

  device_name = each.value.name
  host        = each.value.host
  domain      = wallix-wallix_domain.env_domain.domain_name
  description = each.value.description
}

# Usage:
# module "production" {
#   source      = "./modules/wallix-environment"
#   environment = "production"
#   devices     = var.production_devices
# }
```

---

## GitOps Patterns

### Repository Structure

```
wallix-config/
├── .github/
│   └── workflows/
│       └── apply-config.yml
├── environments/
│   ├── production/
│   │   ├── devices.yml
│   │   ├── users.yml
│   │   └── authorizations.yml
│   └── staging/
│       ├── devices.yml
│       ├── users.yml
│       └── authorizations.yml
├── templates/
│   └── authorization.yml.j2
└── scripts/
    └── apply-config.py
```

### GitHub Actions Workflow

```yaml
# .github/workflows/apply-config.yml

name: Apply WALLIX Configuration

on:
  push:
    branches: [main]
    paths:
      - 'environments/**'
  pull_request:
    branches: [main]
    paths:
      - 'environments/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate YAML
        run: |
          pip install yamllint
          yamllint environments/

      - name: Validate configuration schema
        run: |
          pip install jsonschema pyyaml
          python scripts/validate-config.py

  plan:
    needs: validate
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Generate plan
        env:
          WALLIX_URL: ${{ secrets.WALLIX_URL }}
          WALLIX_API_KEY: ${{ secrets.WALLIX_API_KEY }}
        run: |
          python scripts/apply-config.py --plan --environment staging

      - name: Comment PR with plan
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## WALLIX Configuration Plan\n```\n' + plan + '\n```'
            });

  apply:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Apply configuration
        env:
          WALLIX_URL: ${{ secrets.WALLIX_URL }}
          WALLIX_API_KEY: ${{ secrets.WALLIX_API_KEY }}
        run: |
          python scripts/apply-config.py --apply --environment production
```

### Configuration Apply Script

```python
#!/usr/bin/env python3
# scripts/apply-config.py

import argparse
import yaml
import requests
import os
import sys

class WallixClient:
    def __init__(self, url, api_key):
        self.url = url.rstrip('/')
        self.headers = {
            'X-Auth-Token': api_key,
            'Content-Type': 'application/json'
        }

    def get_devices(self):
        r = requests.get(f"{self.url}/api/devices", headers=self.headers)
        r.raise_for_status()
        return {d['device_name']: d for d in r.json()}

    def create_device(self, device):
        r = requests.post(f"{self.url}/api/devices",
                         headers=self.headers, json=device)
        return r.status_code in [200, 201, 409]

    def update_device(self, name, device):
        r = requests.put(f"{self.url}/api/devices/{name}",
                        headers=self.headers, json=device)
        return r.status_code == 200

def load_config(environment):
    """Load configuration from YAML files"""
    config = {}
    env_dir = f"environments/{environment}"

    for config_file in ['devices.yml', 'users.yml', 'authorizations.yml']:
        path = f"{env_dir}/{config_file}"
        if os.path.exists(path):
            with open(path) as f:
                config[config_file.replace('.yml', '')] = yaml.safe_load(f)

    return config

def plan_changes(client, config):
    """Generate plan of changes"""
    existing_devices = client.get_devices()
    plan = []

    for device in config.get('devices', []):
        if device['name'] in existing_devices:
            plan.append(f"UPDATE device: {device['name']}")
        else:
            plan.append(f"CREATE device: {device['name']}")

    return plan

def apply_changes(client, config, dry_run=False):
    """Apply configuration changes"""
    results = {'created': 0, 'updated': 0, 'failed': 0}

    for device in config.get('devices', []):
        device_data = {
            'device_name': device['name'],
            'host': device['host'],
            'domain': device.get('domain', 'Default'),
            'description': device.get('description', '')
        }

        if dry_run:
            print(f"Would create/update: {device['name']}")
            continue

        if client.create_device(device_data):
            results['created'] += 1
            print(f"Created: {device['name']}")
        else:
            results['failed'] += 1
            print(f"Failed: {device['name']}")

    return results

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--environment', required=True)
    parser.add_argument('--plan', action='store_true')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    client = WallixClient(
        os.environ['WALLIX_URL'],
        os.environ['WALLIX_API_KEY']
    )

    config = load_config(args.environment)

    if args.plan:
        plan = plan_changes(client, config)
        with open('plan.txt', 'w') as f:
            f.write('\n'.join(plan))
        print('\n'.join(plan))

    if args.apply:
        results = apply_changes(client, config)
        print(f"Results: {results}")
        if results['failed'] > 0:
            sys.exit(1)

if __name__ == '__main__':
    main()
```

---

## CI/CD Integration

### Jenkins Pipeline

```groovy
// Jenkinsfile

pipeline {
    agent any

    environment {
        WALLIX_URL = credentials('wallix-url')
        WALLIX_API_KEY = credentials('wallix-api-key')
    }

    stages {
        stage('Validate') {
            steps {
                sh 'pip install yamllint'
                sh 'yamllint environments/'
            }
        }

        stage('Plan') {
            steps {
                sh 'python scripts/apply-config.py --plan --environment ${ENVIRONMENT}'
                archiveArtifacts artifacts: 'plan.txt'
            }
        }

        stage('Approval') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Apply WALLIX configuration?', ok: 'Apply'
            }
        }

        stage('Apply') {
            when {
                branch 'main'
            }
            steps {
                sh 'python scripts/apply-config.py --apply --environment ${ENVIRONMENT}'
            }
        }
    }

    post {
        failure {
            emailext (
                subject: "WALLIX Config Failed: ${currentBuild.fullDisplayName}",
                body: "Check console output at ${BUILD_URL}",
                recipientProviders: [requestor()]
            )
        }
    }
}
```

### GitLab CI

```yaml
# .gitlab-ci.yml

stages:
  - validate
  - plan
  - apply

variables:
  ENVIRONMENT: production

validate:
  stage: validate
  image: python:3.11
  script:
    - pip install yamllint
    - yamllint environments/
  rules:
    - changes:
        - environments/**

plan:
  stage: plan
  image: python:3.11
  script:
    - pip install requests pyyaml
    - python scripts/apply-config.py --plan --environment $ENVIRONMENT
  artifacts:
    paths:
      - plan.txt
  rules:
    - if: $CI_MERGE_REQUEST_ID

apply:
  stage: apply
  image: python:3.11
  script:
    - pip install requests pyyaml
    - python scripts/apply-config.py --apply --environment $ENVIRONMENT
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  when: manual
```

---

## Python SDK Examples

### Simple Device Management

```python
#!/usr/bin/env python3
"""
wallix_sdk_example.py - Simple WALLIX management
"""

import os
import requests

class WallixSDK:
    """Simple WALLIX API client"""

    def __init__(self, url, api_key):
        self.base_url = url.rstrip('/') + '/api'
        self.session = requests.Session()
        self.session.headers.update({
            'X-Auth-Token': api_key,
            'Content-Type': 'application/json'
        })
        self.session.verify = True

    def list_devices(self, domain=None):
        """List all devices"""
        params = {'domain': domain} if domain else {}
        r = self.session.get(f"{self.base_url}/devices", params=params)
        r.raise_for_status()
        return r.json()

    def get_device(self, name):
        """Get device by name"""
        r = self.session.get(f"{self.base_url}/devices/{name}")
        r.raise_for_status()
        return r.json()

    def create_device(self, name, host, domain, description=""):
        """Create a new device"""
        data = {
            'device_name': name,
            'host': host,
            'domain': domain,
            'description': description
        }
        r = self.session.post(f"{self.base_url}/devices", json=data)
        r.raise_for_status()
        return r.json()

    def list_active_sessions(self):
        """List active sessions"""
        r = self.session.get(f"{self.base_url}/sessions/current")
        r.raise_for_status()
        return r.json()

    def terminate_session(self, session_id):
        """Terminate an active session"""
        r = self.session.delete(f"{self.base_url}/sessions/current/{session_id}")
        r.raise_for_status()
        return True

    def rotate_password(self, account_name):
        """Trigger password rotation"""
        r = self.session.post(f"{self.base_url}/accounts/{account_name}/password/change")
        r.raise_for_status()
        return r.json()

# Example usage
if __name__ == '__main__':
    wallix = WallixSDK(
        url=os.environ['WALLIX_URL'],
        api_key=os.environ['WALLIX_API_KEY']
    )

    # List all devices
    devices = wallix.list_devices()
    print(f"Total devices: {len(devices)}")

    # List active sessions
    sessions = wallix.list_active_sessions()
    print(f"Active sessions: {len(sessions)}")
    for session in sessions:
        print(f"  - {session['user']} -> {session['target']}")
```

---

## Quick Reference

### Environment Variables

```bash
# Required for all automation
export WALLIX_URL="https://bastion.company.com"
export WALLIX_API_KEY="your-api-key"

# For Ansible
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# For Terraform
export TF_VAR_wallix_host="bastion.company.com"
export TF_VAR_wallix_user="terraform-svc"
export TF_VAR_wallix_password="secure-password"
```

### Common API Endpoints

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List devices | GET | /api/devices |
| Create device | POST | /api/devices |
| Get device | GET | /api/devices/{name} |
| Update device | PUT | /api/devices/{name} |
| Delete device | DELETE | /api/devices/{name} |
| List accounts | GET | /api/accounts |
| Rotate password | POST | /api/accounts/{name}/password/change |
| Active sessions | GET | /api/sessions/current |
| Kill session | DELETE | /api/sessions/current/{id} |

---

<p align="center">
  <a href="../labs/README.md">Hands-On Labs</a> •
  <a href="../../docs/10-api-automation/README.md">API Documentation</a> •
  <a href="../../docs/16-cloud-deployment/README.md">Cloud Deployment</a>
</p>
