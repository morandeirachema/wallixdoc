# 11 - Monitoring & Observability

## Table of Contents

1. [Monitoring Overview](#monitoring-overview)
2. [Health Checks](#health-checks)
3. [Prometheus Integration](#prometheus-integration)
4. [Grafana Dashboards](#grafana-dashboards)
5. [SNMP Monitoring](#snmp-monitoring)
6. [Syslog & Log Forwarding](#syslog--log-forwarding)
7. [Alerting](#alerting)
8. [Performance Metrics](#performance-metrics)

---

## Monitoring Overview

### Monitoring Architecture

```
+===============================================================================+
|                      WALLIX Bastion MONITORING ARCHITECTURE                           |
+===============================================================================+

  WALLIX Bastion Cluster                 Monitoring Stack              Visualization
  ==============                 ================              =============

  ┌─────────────┐               ┌─────────────┐              ┌─────────────┐
  │  WALLIX Bastion     │               │             │              │             │
  │  Node 1     │───metrics────>│  Prometheus │─────────────>│   Grafana   │
  │             │               │             │              │             │
  └─────────────┘               └──────┬──────┘              └─────────────┘
                                       │
  ┌─────────────┐               ┌──────▼──────┐              ┌─────────────┐
  │  WALLIX Bastion     │               │             │              │             │
  │  Node 2     │───metrics────>│ Alertmanager│─────────────>│ Slack/Teams │
  │             │               │             │              │  PagerDuty  │
  └─────────────┘               └─────────────┘              └─────────────┘
        │
        │                       ┌─────────────┐              ┌─────────────┐
        │                       │             │              │             │
        └─────────logs─────────>│   Syslog    │─────────────>│    SIEM     │
                                │   Server    │              │ Splunk/ELK  │
                                └─────────────┘              └─────────────┘

+===============================================================================+
```

### Monitoring Layers

| Layer | What to Monitor | Tools |
|-------|-----------------|-------|
| **Infrastructure** | CPU, memory, disk, network | Prometheus node_exporter |
| **Application** | Service status, sessions, auth | WALLIX Bastion metrics exporter |
| **Database** | Connections, replication, queries | MariaDB exporter |
| **Cluster** | Node status, resources, failover | Pacemaker metrics |
| **Security** | Auth failures, anomalies, threats | SIEM integration |

---

## Health Checks

### Built-in Health Endpoints

```bash
# Basic service health
curl -sk https://wallix.company.com/health
# Returns: {"status": "healthy", "version": "12.1.x"}

# Detailed health check
curl -sk https://wallix.company.com/api/health/detailed
# Returns component-level health status

# Readiness probe (for load balancers)
curl -sk https://wallix.company.com/health/ready
# Returns 200 if ready to accept traffic

# Liveness probe (for orchestrators)
curl -sk https://wallix.company.com/health/live
# Returns 200 if process is alive
```

### CLI Health Commands

```bash
# Overall system status
wabadmin status

# Detailed health check
wabadmin health-check

# Component-specific checks
wabadmin health-check --component database
wabadmin health-check --component auth
wabadmin health-check --component sessions

# Cluster health (HA deployments)
crm status
pcs status
```

### Health Check Script

```bash
#!/bin/bash
# /opt/wab/scripts/health-check.sh

echo "=== WALLIX Bastion Health Check ==="
echo "Date: $(date)"
echo ""

# Service status
echo "--- Service Status ---"
systemctl is-active wallix-bastion && echo "Service: OK" || echo "Service: FAILED"

# Database connectivity
echo "--- Database ---"
sudo mysql -e "SELECT 1;" > /dev/null 2>&1 && echo "MariaDB: OK" || echo "MariaDB: FAILED"

# Web interface
echo "--- Web Interface ---"
curl -sk -o /dev/null -w "%{http_code}" https://localhost/ | grep -q 200 && echo "HTTPS: OK" || echo "HTTPS: FAILED"

# Disk space
echo "--- Disk Space ---"
DISK_USAGE=$(df -h /var/wab | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "Disk: OK (${DISK_USAGE}% used)"
else
    echo "Disk: WARNING (${DISK_USAGE}% used)"
fi

# Memory
echo "--- Memory ---"
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
if [ "$MEM_USAGE" -lt 80 ]; then
    echo "Memory: OK (${MEM_USAGE}% used)"
else
    echo "Memory: WARNING (${MEM_USAGE}% used)"
fi

# Cluster status (if HA)
if command -v crm &> /dev/null; then
    echo "--- Cluster ---"
    crm status | grep -q "Online:" && echo "Cluster: OK" || echo "Cluster: DEGRADED"
fi

echo ""
echo "=== Health Check Complete ==="
```

---

## Prometheus Integration

### WALLIX Bastion Metrics Exporter

WALLIX Bastion exposes metrics in Prometheus format on port 9100.

```yaml
# /etc/prometheus/prometheus.yml

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # WALLIX Bastion application metrics
  - job_name: 'wallix'
    scheme: https
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets:
          - 'wallix-node1.company.com:9100'
          - 'wallix-node2.company.com:9100'
    metrics_path: /metrics

  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets:
          - 'wallix-node1.company.com:9100'
          - 'wallix-node2.company.com:9100'

  # MariaDB exporter
  - job_name: 'mariadb'
    static_configs:
      - targets:
          - 'wallix-node1.company.com:9104'
          - 'wallix-node2.company.com:9104'
```

### Key Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pam_sessions_active` | Gauge | Current active sessions |
| `pam_sessions_total` | Counter | Total sessions established |
| `pam_auth_success_total` | Counter | Successful authentications |
| `pam_auth_failure_total` | Counter | Failed authentications |
| `pam_password_rotations_total` | Counter | Password rotations performed |
| `pam_password_rotation_failures` | Counter | Failed password rotations |
| `pam_approvals_pending` | Gauge | Pending approval requests |
| `pam_license_usage_percent` | Gauge | License utilization |
| `pam_recording_storage_bytes` | Gauge | Session recording storage used |

### Custom Metrics Exporter

```python
#!/usr/bin/env python3
# /opt/wab/scripts/wallix_exporter.py

from prometheus_client import start_http_server, Gauge, Counter
import subprocess
import time
import json

# Define metrics
sessions_active = Gauge('pam_sessions_active', 'Active sessions')
auth_failures = Counter('pam_auth_failures_total', 'Authentication failures')
disk_usage = Gauge('pam_disk_usage_percent', 'Disk usage percentage', ['mount'])
replication_lag = Gauge('pam_replication_lag_bytes', 'MariaDB replication lag')

def collect_metrics():
    # Active sessions
    result = subprocess.run(['wabadmin', 'session', 'count'], capture_output=True, text=True)
    sessions_active.set(int(result.stdout.strip()))

    # Disk usage
    result = subprocess.run(['df', '/var/wab', '--output=pcent'], capture_output=True, text=True)
    usage = int(result.stdout.strip().split('\n')[1].replace('%', ''))
    disk_usage.labels(mount='/var/wab').set(usage)

    # Replication lag (if replica)
    try:
        result = subprocess.run([
            'sudo', 'mysql', '-N', '-e',
            "SHOW SLAVE STATUS\\G"
        ], capture_output=True, text=True)
        lag = int(result.stdout.strip() or 0)
        replication_lag.set(lag)
    except:
        pass

if __name__ == '__main__':
    start_http_server(9100)
    while True:
        collect_metrics()
        time.sleep(15)
```

---

## Grafana Dashboards

### WALLIX Bastion Overview Dashboard

```json
{
  "dashboard": {
    "title": "WALLIX Bastion Overview",
    "panels": [
      {
        "title": "Active Sessions",
        "type": "stat",
        "targets": [
          {"expr": "pam_sessions_active"}
        ]
      },
      {
        "title": "Sessions Over Time",
        "type": "graph",
        "targets": [
          {"expr": "rate(pam_sessions_total[5m])", "legendFormat": "Sessions/sec"}
        ]
      },
      {
        "title": "Authentication Success Rate",
        "type": "gauge",
        "targets": [
          {"expr": "rate(pam_auth_success_total[5m]) / (rate(pam_auth_success_total[5m]) + rate(pam_auth_failure_total[5m])) * 100"}
        ]
      },
      {
        "title": "License Usage",
        "type": "gauge",
        "targets": [
          {"expr": "pam_license_usage_percent"}
        ]
      }
    ]
  }
}
```

### Key Dashboard Panels

| Panel | Query | Purpose |
|-------|-------|---------|
| Active Sessions | `pam_sessions_active` | Current load |
| Auth Failures/min | `rate(pam_auth_failure_total[1m]) * 60` | Security monitoring |
| Replication Lag | `pam_replication_lag_bytes` | HA health |
| Disk Usage | `pam_disk_usage_percent{mount="/var/wab"}` | Capacity planning |
| CPU Usage | `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | Performance |
| Memory Usage | `(1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes) * 100` | Resource usage |

---

## SNMP Monitoring

### SNMP Configuration

```bash
# Install SNMP daemon
apt install snmpd snmp

# Configure SNMP
cat > /etc/snmp/snmpd.conf << 'EOF'
# Listen on all interfaces
agentAddress udp:161

# SNMPv3 user (recommended)
createUser wallixMonitor SHA "AuthPassword123" AES "PrivPassword123"
rouser wallixMonitor priv

# SNMPv2c community (legacy)
rocommunity public 10.10.1.0/24

# System information
sysLocation "Data Center A"
sysContact "ops@company.com"
sysName "wallix-node1"

# Extend with custom scripts
extend wallix-sessions /opt/wab/scripts/snmp-sessions.sh
extend wallix-health /opt/wab/scripts/snmp-health.sh
EOF

# Restart SNMP
systemctl restart snmpd
systemctl enable snmpd
```

### SNMP Extension Scripts

```bash
#!/bin/bash
# /opt/wab/scripts/snmp-sessions.sh
wabadmin session count 2>/dev/null || echo "0"
```

```bash
#!/bin/bash
# /opt/wab/scripts/snmp-health.sh
# Returns: 0=healthy, 1=degraded, 2=critical
systemctl is-active wallix-bastion > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "0"
else
    echo "2"
fi
```

### SNMP OIDs

| OID | Description |
|-----|-------------|
| `.1.3.6.1.4.1.xxxxx.1.1` | WALLIX Bastion version |
| `.1.3.6.1.4.1.xxxxx.1.2` | Active sessions |
| `.1.3.6.1.4.1.xxxxx.1.3` | Health status |
| `.1.3.6.1.4.1.xxxxx.1.4` | License usage % |

---

## Syslog & Log Forwarding

### Syslog Configuration

```bash
# /etc/rsyslog.d/50-wallix.conf

# Forward WALLIX Bastion logs to SIEM
if $programname == 'wallix-bastion' then {
    action(type="omfwd"
           target="siem.company.com"
           port="514"
           protocol="tcp"
           template="RSYSLOG_SyslogProtocol23Format")
    stop
}

# Forward audit logs with TLS
if $programname == 'wab-audit' then {
    action(type="omfwd"
           target="siem.company.com"
           port="6514"
           protocol="tcp"
           StreamDriver="gtls"
           StreamDriverMode="1"
           StreamDriverAuthMode="x509/name"
           template="CEFFormat")
    stop
}
```

### CEF Log Format

```
# CEF format for SIEM integration
template(name="CEFFormat" type="string"
  string="CEF:0|WALLIX|WALLIX Bastion|12.1|%msg:R,ERE,0,DFLT:event_id=([^,]+)--end%|%msg:R,ERE,0,DFLT:event_name=([^,]+)--end%|%msg:R,ERE,0,DFLT:severity=([^,]+)--end%|%msg%\n")
```

### Log Categories

| Log | Path | Forward To |
|-----|------|------------|
| Application | `/var/log/wab/application.log` | Optional |
| Audit | `/var/log/wab/audit.log` | Required (SIEM) |
| Authentication | `/var/log/wab/auth.log` | Required (SIEM) |
| Session | `/var/log/wab/session.log` | Required (SIEM) |
| API | `/var/log/wab/api.log` | Optional |

---

## Alerting

### Prometheus Alert Rules

```yaml
# /etc/prometheus/rules/wallix.yml

groups:
  - name: wallix_critical
    rules:
      - alert: WALLIX BastionServiceDown
        expr: up{job="wallix"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX Bastion service down on {{ $labels.instance }}"
          description: "WALLIX Bastion has been unreachable for more than 1 minute."
          runbook_url: "https://wiki.company.com/wallix/runbooks/service-down"

      - alert: WALLIX BastionHighAuthFailures
        expr: rate(pam_auth_failure_total[5m]) > 10
        for: 2m
        labels:
          severity: high
          category: security
        annotations:
          summary: "High authentication failure rate"
          description: "More than 10 auth failures per second for 2 minutes."

      - alert: WALLIX BastionDiskCritical
        expr: pam_disk_usage_percent{mount="/var/wab"} > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX Bastion disk usage critical"
          description: "Disk usage is {{ $value }}% on {{ $labels.instance }}"

  - name: wallix_warning
    rules:
      - alert: WALLIX BastionReplicationLag
        expr: pam_replication_lag_bytes > 10485760
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "MariaDB replication lag high"
          description: "Replication lag is {{ $value | humanize1024 }}B"

      - alert: WALLIX BastionLicenseWarning
        expr: pam_license_usage_percent > 80
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "License usage above 80%"
          description: "License utilization is {{ $value }}%"

      - alert: WALLIX BastionCertExpiring
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon"
          description: "Certificate expires in {{ $value }} days"
```

### Alertmanager Configuration

```yaml
# /etc/alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m

route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true
    - match:
        severity: critical
      receiver: 'slack-critical'
    - match:
        category: security
      receiver: 'security-team'

receivers:
  - name: 'default'
    email_configs:
      - to: 'ops@company.com'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
        severity: critical

  - name: 'slack-critical'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR_WORKSPACE/YOUR_CHANNEL/YOUR_TOKEN'
        channel: '#wallix-alerts'
        send_resolved: true

  - name: 'security-team'
    email_configs:
      - to: 'security@company.com'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR_WORKSPACE/YOUR_CHANNEL/YOUR_TOKEN'
        channel: '#security-alerts'
```

---

## Performance Metrics

### Key Performance Indicators

| KPI | Target | Warning | Critical |
|-----|--------|---------|----------|
| Session establishment time | < 2s | > 3s | > 5s |
| Authentication latency | < 500ms | > 1s | > 2s |
| API response time (p95) | < 200ms | > 500ms | > 1s |
| Password rotation success rate | > 99% | < 98% | < 95% |
| Service availability | > 99.9% | < 99.5% | < 99% |

### Performance Monitoring Queries

```promql
# Session establishment time (histogram)
histogram_quantile(0.95, rate(pam_session_establishment_seconds_bucket[5m]))

# Authentication latency
histogram_quantile(0.95, rate(pam_auth_duration_seconds_bucket[5m]))

# API response time
histogram_quantile(0.95, rate(pam_api_request_duration_seconds_bucket[5m]))

# Request rate
rate(pam_api_requests_total[5m])

# Error rate
rate(pam_api_errors_total[5m]) / rate(pam_api_requests_total[5m]) * 100
```

### Baseline Report Script

```bash
#!/bin/bash
# /opt/wab/scripts/performance-baseline.sh

echo "=== WALLIX Bastion Performance Baseline ==="
echo "Date: $(date)"
echo ""

# Response time test
echo "--- Response Time ---"
for i in {1..10}; do
    curl -sk -o /dev/null -w "%{time_total}\n" https://localhost/api/health
done | awk '{sum+=$1} END {print "Average: " sum/NR "s"}'

# Session count capacity
echo "--- Session Capacity ---"
wabadmin session count
wabadmin license-info | grep -i session

# Database performance
echo "--- Database Performance ---"
sudo mysql -e "SELECT COUNT(*) as connections FROM information_schema.processlist;"
sudo mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size (MB)' FROM information_schema.tables WHERE table_schema = 'wabdb';"

# System resources
echo "--- System Resources ---"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h /var/wab | tail -1 | awk '{print $2}')"
```

---

## Quick Reference

### Monitoring Checklist

```
MONITORING SETUP CHECKLIST
==========================

Infrastructure Monitoring:
[ ] Prometheus installed and configured
[ ] Node exporter on all WALLIX Bastion nodes
[ ] MariaDB exporter configured
[ ] Scrape targets verified

Application Monitoring:
[ ] WALLIX Bastion metrics endpoint enabled
[ ] Custom exporter deployed (if needed)
[ ] Health check endpoints tested

Alerting:
[ ] Alert rules defined
[ ] Alertmanager configured
[ ] Notification channels tested
[ ] Escalation paths documented

Log Forwarding:
[ ] Syslog configured
[ ] SIEM integration tested
[ ] CEF format verified
[ ] Log retention policy set

Dashboards:
[ ] Grafana installed
[ ] WALLIX Bastion dashboard imported
[ ] Team access configured
```

### Essential Commands

```bash
# Check metrics endpoint
curl -sk https://localhost:9100/metrics | head -50

# Test Prometheus scrape
curl -s http://prometheus:9090/api/v1/targets | jq '.data.activeTargets[] | {instance, health}'

# View active alerts
curl -s http://alertmanager:9093/api/v1/alerts | jq '.data[] | {alertname, status}'

# Test syslog forwarding
logger -p local0.info -t wallix "Test message"

# Check SNMP
snmpwalk -v3 -u wallixMonitor -l authPriv -a SHA -A "AuthPass" -x AES -X "PrivPass" localhost
```

---

## See Also

**Related Sections:**
- [26 - Performance Benchmarks](../26-performance-benchmarks/README.md) - Capacity planning and metrics
- [21 - Operational Runbooks](../21-operational-runbooks/README.md) - Daily operations procedures

**Related Documentation:**
- [Pre-Production Lab: Observability](/pre/11-observability.md) - Monitoring setup guide

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [12 - Troubleshooting](../13-troubleshooting/README.md) for diagnostics and common issues.
