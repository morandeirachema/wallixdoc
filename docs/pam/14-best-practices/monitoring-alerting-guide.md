# Monitoring and Alerting Guide

## Health Metrics, Dashboards, and Alert Configuration

This guide covers proactive monitoring of WALLIX Bastion to ensure high availability and rapid issue detection.

---

## Key Metrics to Monitor

```
+===============================================================================+
|                   WALLIX MONITORING METRICS                                   |
+===============================================================================+

  CRITICAL (Alert immediately)
  ============================
  - Service status (wabengine, MariaDB)
  - Disk space (< 10% free)
  - Database connectivity
  - Certificate expiration (< 14 days)
  - Cluster split-brain

  WARNING (Alert within hours)
  ============================
  - Active sessions (unusual spike/drop)
  - Failed login attempts (> threshold)
  - Password rotation failures
  - Disk space (< 20% free)
  - CPU sustained > 80%
  - Memory usage > 85%

  INFORMATIONAL (Dashboard only)
  ==============================
  - Total sessions per day
  - User activity patterns
  - Recording storage growth
  - API request rate

+===============================================================================+
```

---

## Monitoring Scripts

### Service Health Check

```bash
#!/bin/bash
# /opt/wallix/scripts/health-check.sh
# Run every 5 minutes via cron

OUTPUT_FILE="/var/log/wallix-health.json"
ALERT_FILE="/tmp/wallix-alerts.txt"

# Initialize
> "$ALERT_FILE"

check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo "\"$service\": \"ok\""
    else
        echo "\"$service\": \"failed\""
        echo "CRITICAL: Service $service is not running" >> "$ALERT_FILE"
    fi
}

check_port() {
    local port=$1
    local name=$2
    if ss -tuln | grep -q ":$port "; then
        echo "\"port_$port\": \"listening\""
    else
        echo "\"port_$port\": \"down\""
        echo "CRITICAL: Port $port ($name) not listening" >> "$ALERT_FILE"
    fi
}

check_disk() {
    local mount=$1
    local threshold=$2
    local usage=$(df "$mount" --output=pcent | tail -1 | tr -d ' %')
    echo "\"disk_${mount//\//_}\": $usage"
    if [ "$usage" -gt "$threshold" ]; then
        echo "WARNING: Disk $mount at ${usage}%" >> "$ALERT_FILE"
    fi
}

check_db() {
    if sudo mysql -e "SELECT 1" wabdb >/dev/null 2>&1; then
        echo "\"database\": \"ok\""
    else
        echo "\"database\": \"failed\""
        echo "CRITICAL: Database connection failed" >> "$ALERT_FILE"
    fi
}

# Build JSON output
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "services": {
    $(check_service wabengine),
    $(check_service mariadb)
  },
  "ports": {
    $(check_port 443 "HTTPS"),
    $(check_port 22 "SSH"),
    $(check_port 3389 "RDP")
  },
  "resources": {
    $(check_disk / 90),
    $(check_disk /var 80),
    "memory_percent": $(free | awk '/^Mem:/{printf "%.0f", $3/$2*100}'),
    "cpu_percent": $(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8}')
  },
  $(check_db),
  "active_sessions": $(wabsession list 2>/dev/null | wc -l || echo 0)
}
EOF

# Send alerts if any
if [ -s "$ALERT_FILE" ]; then
    # Send to monitoring system
    cat "$ALERT_FILE" | while read alert; do
        logger -p local0.err "WALLIX-HEALTH: $alert"
    done
fi
```

### Certificate Expiration Check

```bash
#!/bin/bash
# /opt/wallix/scripts/check-certs.sh
# Run daily

CERT_FILE="/etc/opt/wab/ssl/server.crt"
WARNING_DAYS=30
CRITICAL_DAYS=14

# Get expiration date
EXPIRY=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

echo "Certificate expires in ${DAYS_LEFT} days"

if [ "$DAYS_LEFT" -lt "$CRITICAL_DAYS" ]; then
    logger -p local0.crit "WALLIX: Certificate expires in ${DAYS_LEFT} days - CRITICAL"
    echo "CRITICAL: Certificate expires in ${DAYS_LEFT} days"
elif [ "$DAYS_LEFT" -lt "$WARNING_DAYS" ]; then
    logger -p local0.warning "WALLIX: Certificate expires in ${DAYS_LEFT} days - WARNING"
    echo "WARNING: Certificate expires in ${DAYS_LEFT} days"
else
    echo "OK: Certificate valid for ${DAYS_LEFT} days"
fi
```

### Session Monitoring

```bash
#!/bin/bash
# /opt/wallix/scripts/session-monitor.sh
# Monitor active sessions and alert on anomalies

BASELINE_FILE="/var/opt/wallix/session-baseline.txt"
CURRENT_SESSIONS=$(wabsession list 2>/dev/null | wc -l)

# Get baseline (average of last 7 days same time)
if [ -f "$BASELINE_FILE" ]; then
    BASELINE=$(cat "$BASELINE_FILE")
else
    BASELINE=10  # Default baseline
fi

# Calculate deviation
DEVIATION=$(( (CURRENT_SESSIONS - BASELINE) * 100 / (BASELINE + 1) ))

if [ "$DEVIATION" -gt 200 ]; then
    logger -p local0.warning "WALLIX: Unusual session count (${CURRENT_SESSIONS} vs baseline ${BASELINE})"
fi

# Output for monitoring
echo "wallix_active_sessions ${CURRENT_SESSIONS}"
echo "wallix_session_deviation ${DEVIATION}"
```

---

## Prometheus Integration

### Metrics Exporter

```python
#!/usr/bin/env python3
"""
/opt/wallix/scripts/prometheus-exporter.py
WALLIX metrics exporter for Prometheus
Run as service on port 9100
"""

from prometheus_client import start_http_server, Gauge, Counter
import subprocess
import time
import psutil
import mysql.connector

# Define metrics
ACTIVE_SESSIONS = Gauge('wallix_active_sessions', 'Number of active sessions')
TOTAL_USERS = Gauge('wallix_total_users', 'Total configured users')
TOTAL_DEVICES = Gauge('wallix_total_devices', 'Total configured devices')
DISK_USAGE = Gauge('wallix_disk_usage_percent', 'Disk usage percentage', ['mount'])
MEMORY_USAGE = Gauge('wallix_memory_usage_percent', 'Memory usage percentage')
CPU_USAGE = Gauge('wallix_cpu_usage_percent', 'CPU usage percentage')
SERVICE_UP = Gauge('wallix_service_up', 'Service status', ['service'])
FAILED_LOGINS = Counter('wallix_failed_logins_total', 'Total failed login attempts')
RECORDINGS_SIZE = Gauge('wallix_recordings_size_bytes', 'Total size of recordings')

def get_db_metric(query):
    """Execute query against WALLIX database"""
    try:
        conn = mysql.connector.connect(database="wabdb", user="wabadmin")
        cur = conn.cursor()
        cur.execute(query)
        result = cur.fetchone()[0]
        conn.close()
        return result
    except Exception:
        return 0

def collect_metrics():
    """Collect all metrics"""

    # Active sessions
    try:
        result = subprocess.run(['wabsession', 'list'],
                              capture_output=True, text=True, timeout=10)
        sessions = len(result.stdout.strip().split('\n')) - 1  # Minus header
        ACTIVE_SESSIONS.set(max(0, sessions))
    except Exception:
        ACTIVE_SESSIONS.set(0)

    # Database metrics
    TOTAL_USERS.set(get_db_metric("SELECT COUNT(*) FROM users"))
    TOTAL_DEVICES.set(get_db_metric("SELECT COUNT(*) FROM devices"))

    # System metrics
    MEMORY_USAGE.set(psutil.virtual_memory().percent)
    CPU_USAGE.set(psutil.cpu_percent(interval=1))

    # Disk usage
    for mount in ['/', '/var', '/var/wab/recorded']:
        try:
            usage = psutil.disk_usage(mount)
            DISK_USAGE.labels(mount=mount).set(usage.percent)
        except Exception:
            pass

    # Service status
    for service in ['wabengine', 'mariadb']:
        result = subprocess.run(['systemctl', 'is-active', service],
                              capture_output=True, text=True)
        status = 1 if result.stdout.strip() == 'active' else 0
        SERVICE_UP.labels(service=service).set(status)

    # Recording storage size
    try:
        result = subprocess.run(['du', '-sb', '/var/wab/recorded'],
                              capture_output=True, text=True)
        size = int(result.stdout.split()[0])
        RECORDINGS_SIZE.set(size)
    except Exception:
        pass

if __name__ == '__main__':
    # Start HTTP server
    start_http_server(9100)
    print("WALLIX Prometheus exporter running on port 9100")

    # Collect metrics every 30 seconds
    while True:
        collect_metrics()
        time.sleep(30)
```

### Prometheus Configuration

```yaml
# /etc/prometheus/prometheus.yml (snippet)

scrape_configs:
  - job_name: 'wallix'
    static_configs:
      - targets: ['wallix-wallix:9100']
    scrape_interval: 30s

  # If using WALLIX HA cluster
  - job_name: 'wallix-cluster'
    static_configs:
      - targets:
        - 'wallix-node1:9100'
        - 'wallix-node2:9100'
```

---

## Grafana Dashboard

### Dashboard JSON

```json
{
  "title": "WALLIX Bastion Health",
  "panels": [
    {
      "title": "Active Sessions",
      "type": "stat",
      "targets": [{"expr": "wallix_active_sessions"}],
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
    },
    {
      "title": "Service Status",
      "type": "stat",
      "targets": [{"expr": "wallix_service_up"}],
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0}
    },
    {
      "title": "CPU Usage",
      "type": "gauge",
      "targets": [{"expr": "wallix_cpu_usage_percent"}],
      "thresholds": {"steps": [
        {"value": 0, "color": "green"},
        {"value": 70, "color": "yellow"},
        {"value": 90, "color": "red"}
      ]},
      "gridPos": {"h": 4, "w": 4, "x": 12, "y": 0}
    },
    {
      "title": "Memory Usage",
      "type": "gauge",
      "targets": [{"expr": "wallix_memory_usage_percent"}],
      "thresholds": {"steps": [
        {"value": 0, "color": "green"},
        {"value": 80, "color": "yellow"},
        {"value": 95, "color": "red"}
      ]},
      "gridPos": {"h": 4, "w": 4, "x": 16, "y": 0}
    },
    {
      "title": "Sessions Over Time",
      "type": "timeseries",
      "targets": [{"expr": "wallix_active_sessions"}],
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4}
    },
    {
      "title": "Disk Usage",
      "type": "timeseries",
      "targets": [{"expr": "wallix_disk_usage_percent"}],
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4}
    }
  ]
}
```

---

## Alert Rules

### Prometheus Alert Rules

```yaml
# /etc/prometheus/rules/wallix-alerts.yml

groups:
  - name: wallix_critical
    rules:
      - alert: WallixServiceDown
        expr: wallix_service_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX service {{ $labels.service }} is down"
          description: "Service has been down for more than 1 minute"

      - alert: WallixDatabaseDown
        expr: wallix_service_up{service="mariadb"} == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "WALLIX database is down"
          description: "MariaDB service is not running"

      - alert: WallixDiskCritical
        expr: wallix_disk_usage_percent{mount="/var"} > 95
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "WALLIX disk space critical"
          description: "/var is {{ $value }}% full"

  - name: wallix_warning
    rules:
      - alert: WallixDiskWarning
        expr: wallix_disk_usage_percent{mount="/var"} > 80
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "WALLIX disk space warning"
          description: "/var is {{ $value }}% full"

      - alert: WallixHighCPU
        expr: wallix_cpu_usage_percent > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "WALLIX high CPU usage"
          description: "CPU usage is {{ $value }}%"

      - alert: WallixHighMemory
        expr: wallix_memory_usage_percent > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "WALLIX high memory usage"
          description: "Memory usage is {{ $value }}%"

      - alert: WallixNoSessions
        expr: wallix_active_sessions == 0 and hour() >= 9 and hour() <= 17 and day_of_week() >= 1 and day_of_week() <= 5
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "No active WALLIX sessions during business hours"
          description: "Possible connectivity issue"
```

---

## SNMP Monitoring

### SNMP Configuration

```bash
# Enable SNMP on WALLIX (if supported)
# /etc/snmp/snmpd.conf

# Community string (change in production!)
rocommunity wallix_monitor 10.0.0.0/8

# System information
sysLocation    "Data Center - Rack 42"
sysContact     "it-ops@company.com"

# WALLIX-specific OIDs (example)
# Consult WALLIX documentation for actual OIDs
```

### SNMP Monitoring Commands

```bash
# Test SNMP connectivity
snmpwalk -v2c -c wallix_monitor bastion.company.com .1.3.6.1.2.1.1.1

# Get system uptime
snmpget -v2c -c wallix_monitor bastion.company.com .1.3.6.1.2.1.1.3.0
```

---

## Syslog Alerting

### Rsyslog Configuration

```bash
# /etc/rsyslog.d/50-wallix-alerts.conf

# Forward critical messages to monitoring
if $programname == 'wabengine' and $syslogseverity <= 3 then {
    action(type="omfwd" target="siem.company.com" port="514" protocol="tcp")
}

# Send alerts to dedicated file
if $programname == 'WALLIX-HEALTH' then {
    action(type="omfile" file="/var/log/wallix-alerts.log")
}
```

### Log-Based Alerting Patterns

```bash
# Critical patterns to alert on:

# Service failures
grep -E "(CRITICAL|FATAL|ERROR.*failed to start)" /var/log/wabengine/*.log

# Authentication failures
grep "authentication failed" /var/log/wabaudit/audit.log

# Password rotation failures
grep "rotation failed" /var/log/wabengine/*.log

# Database errors
grep "database connection" /var/log/wabengine/*.log
```

---

## Cron Schedule for Monitoring

```bash
# /etc/cron.d/wallix-monitoring

# Health check every 5 minutes
*/5 * * * * root /opt/wallix/scripts/health-check.sh

# Certificate check daily at 6:00
0 6 * * * root /opt/wallix/scripts/check-certs.sh

# Session baseline update hourly
0 * * * * root /opt/wallix/scripts/session-monitor.sh >> /var/log/wallix-sessions.log

# Weekly health report
0 8 * * 1 root /opt/wallix/scripts/weekly-report.sh | mail -s "WALLIX Weekly Report" ops@company.com
```

---

## Alerting Quick Reference

| Metric | Warning | Critical | Check Interval |
|--------|---------|----------|----------------|
| Service status | - | Down > 1 min | 1 min |
| Disk /var | > 80% | > 95% | 5 min |
| CPU | > 80% (10 min) | > 95% (5 min) | 1 min |
| Memory | > 85% | > 95% | 1 min |
| Active sessions | Deviation > 200% | Zero during business | 5 min |
| Certificate | < 30 days | < 14 days | Daily |
| Password rotation | Any failure | 3+ consecutive | After each rotation |
| Failed logins | > 10/hour | > 50/hour | Real-time |

---

<p align="center">
  <a href="./README.md">Best Practices</a> •
  <a href="./backup-recovery-guide.md">Backup & Recovery</a> •
  <a href="../13-troubleshooting/README.md">Troubleshooting</a>
</p>
