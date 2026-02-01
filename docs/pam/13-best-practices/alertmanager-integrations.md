# Alertmanager Webhook Integrations

## Configuring Slack, Microsoft Teams, and PagerDuty Notifications

This guide covers integrating Alertmanager with common notification platforms.

---

## Integration Architecture

```
+===============================================================================+
|                    ALERTMANAGER NOTIFICATION FLOW                             |
+===============================================================================+

  Prometheus               Alertmanager               Notification Channels
  ==========               ============               =====================

  +-------------+         +----------------+         +------------------+
  | Alert Rules |  --->   |  Alertmanager  |  --->   |     Slack        |
  | Fire        |         |                |         +------------------+
  +-------------+         |  - Grouping    |         +------------------+
                          |  - Routing     |  --->   | Microsoft Teams  |
                          |  - Silencing   |         +------------------+
                          |  - Inhibition  |         +------------------+
                          +----------------+  --->   |   PagerDuty      |
                                 |                   +------------------+
                                 |                   +------------------+
                                 +---------------->  |   Email          |
                                                     +------------------+

+===============================================================================+
```

---

## Slack Integration

### Step 1: Create Slack Webhook

1. Go to https://api.slack.com/apps
2. Click "Create New App" > "From scratch"
3. Name: "PAM4OT Alerts", Workspace: [Your workspace]
4. Go to "Incoming Webhooks" > Enable
5. Click "Add New Webhook to Workspace"
6. Select channel: #pam4ot-alerts
7. Copy webhook URL

### Step 2: Configure Alertmanager

```yaml
# /etc/alertmanager/alertmanager.yml

global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR_WORKSPACE/YOUR_CHANNEL/YOUR_WEBHOOK_TOKEN'

route:
  receiver: 'slack-default'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: 'slack-critical'
      group_wait: 0s

    - match:
        severity: high
      receiver: 'slack-high'

receivers:
  - name: 'slack-default'
    slack_configs:
      - channel: '#pam4ot-alerts'
        send_resolved: true
        title: '{{ .Status | toUpper }}: {{ .CommonLabels.alertname }}'
        text: |
          *Alert:* {{ .CommonLabels.alertname }}
          *Severity:* {{ .CommonLabels.severity }}
          *Description:* {{ .CommonAnnotations.description }}
          *Runbook:* {{ .CommonAnnotations.runbook_url }}

  - name: 'slack-critical'
    slack_configs:
      - channel: '#pam4ot-critical'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
        title: ':rotating_light: CRITICAL: {{ .CommonLabels.alertname }}'
        text: |
          *Instance:* {{ .CommonLabels.instance }}
          *Description:* {{ .CommonAnnotations.description }}
          *Started:* {{ .StartsAt.Format "2006-01-02 15:04:05" }}

          <{{ .CommonAnnotations.runbook_url }}|View Runbook>
        actions:
          - type: button
            text: 'View in Grafana'
            url: 'https://grafana.company.com/d/pam4ot'
          - type: button
            text: 'Silence Alert'
            url: 'https://alertmanager.company.com/#/silences/new'

  - name: 'slack-high'
    slack_configs:
      - channel: '#pam4ot-alerts'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}warning{{ else }}good{{ end }}'
        title: ':warning: HIGH: {{ .CommonLabels.alertname }}'
        text: |
          *Instance:* {{ .CommonLabels.instance }}
          *Description:* {{ .CommonAnnotations.description }}
```

### Step 3: Test Slack Integration

```bash
# Restart Alertmanager
systemctl restart alertmanager

# Send test alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "critical",
      "instance": "pam4ot-node1:9100"
    },
    "annotations": {
      "description": "This is a test alert",
      "runbook_url": "https://wiki.company.com/runbooks/test"
    }
  }]'

# Should see message in #pam4ot-critical channel
```

---

## Microsoft Teams Integration

### Step 1: Create Teams Webhook

1. In Microsoft Teams, go to the channel
2. Click "..." > "Connectors"
3. Search for "Incoming Webhook"
4. Click "Configure"
5. Name: "PAM4OT Alerts"
6. Copy webhook URL

### Step 2: Configure Alertmanager with Webhook

Teams requires a specific JSON format. Use the webhook receiver:

```yaml
# /etc/alertmanager/alertmanager.yml

receivers:
  - name: 'teams-critical'
    webhook_configs:
      - url: 'http://localhost:8089/teams'  # Teams adapter
        send_resolved: true

  - name: 'teams-default'
    webhook_configs:
      - url: 'http://localhost:8089/teams'
        send_resolved: true
```

### Step 3: Deploy Teams Adapter

Use prometheus-msteams adapter:

```bash
# Download adapter
wget https://github.com/prometheus-msteams/prometheus-msteams/releases/download/v1.5.2/prometheus-msteams-linux-amd64

chmod +x prometheus-msteams-linux-amd64
mv prometheus-msteams-linux-amd64 /usr/local/bin/prometheus-msteams

# Create config
cat > /etc/prometheus-msteams/config.yml << 'EOF'
connectors:
  - teams: "https://YOUR_TENANT.webhook.office.com/webhookb2/YOUR_WEBHOOK_ID"

templates_file: /etc/prometheus-msteams/card.tmpl
EOF

# Create card template
cat > /etc/prometheus-msteams/card.tmpl << 'EOF'
{{ define "teams.card" }}
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "{{- if eq .Status "resolved" -}}2DC72D
                 {{- else if eq .CommonLabels.severity "critical" -}}FF0000
                 {{- else if eq .CommonLabels.severity "high" -}}FFA500
                 {{- else -}}0076D7{{- end -}}",
  "summary": "{{ .CommonLabels.alertname }}",
  "sections": [{
    "activityTitle": "{{ .Status | toUpper }}: {{ .CommonLabels.alertname }}",
    "facts": [
      {
        "name": "Severity",
        "value": "{{ .CommonLabels.severity }}"
      },
      {
        "name": "Instance",
        "value": "{{ .CommonLabels.instance }}"
      },
      {
        "name": "Description",
        "value": "{{ .CommonAnnotations.description }}"
      }
    ],
    "markdown": true
  }],
  "potentialAction": [
    {
      "@type": "OpenUri",
      "name": "View Runbook",
      "targets": [
        { "os": "default", "uri": "{{ .CommonAnnotations.runbook_url }}" }
      ]
    },
    {
      "@type": "OpenUri",
      "name": "View in Grafana",
      "targets": [
        { "os": "default", "uri": "https://grafana.company.com/d/pam4ot" }
      ]
    }
  ]
}
{{ end }}
EOF

# Create systemd service
cat > /etc/systemd/system/prometheus-msteams.service << 'EOF'
[Unit]
Description=Prometheus MS Teams Adapter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/prometheus-msteams -config-file /etc/prometheus-msteams/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus-msteams
systemctl start prometheus-msteams
```

### Step 4: Test Teams Integration

```bash
# Send test alert (same as Slack test above)
# Should see card in Teams channel
```

---

## PagerDuty Integration

### Step 1: Create PagerDuty Service

1. Login to PagerDuty
2. Go to Services > New Service
3. Name: "PAM4OT Production"
4. Integration: "Events API v2"
5. Copy Integration Key (routing key)

### Step 2: Configure Alertmanager

```yaml
# /etc/alertmanager/alertmanager.yml

receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR-INTEGRATION-KEY-HERE'
        severity: critical
        description: '{{ .CommonLabels.alertname }}: {{ .CommonAnnotations.description }}'
        details:
          firing: '{{ .Alerts.Firing | len }}'
          resolved: '{{ .Alerts.Resolved | len }}'
          instance: '{{ .CommonLabels.instance }}'
          severity: '{{ .CommonLabels.severity }}'

  - name: 'pagerduty-high'
    pagerduty_configs:
      - service_key: 'YOUR-INTEGRATION-KEY-HERE'
        severity: error
        description: '{{ .CommonLabels.alertname }}: {{ .CommonAnnotations.description }}'
        details:
          instance: '{{ .CommonLabels.instance }}'
```

### Step 3: Configure Routing

```yaml
route:
  receiver: 'slack-default'
  routes:
    # Critical alerts go to PagerDuty AND Slack
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true  # Also send to next matching route

    - match:
        severity: critical
      receiver: 'slack-critical'

    # High alerts during business hours: Slack only
    # High alerts after hours: PagerDuty
    - match:
        severity: high
      receiver: 'pagerduty-high'
      active_time_intervals:
        - after-hours

time_intervals:
  - name: after-hours
    time_intervals:
      - weekdays: ['saturday', 'sunday']
      - times:
          - start_time: '18:00'
            end_time: '09:00'
```

---

## Email Integration

### Basic Email Configuration

```yaml
global:
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alertmanager@company.com'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'
  smtp_require_tls: true

receivers:
  - name: 'email-ops'
    email_configs:
      - to: 'ops-team@company.com'
        send_resolved: true
        headers:
          Subject: '{{ .Status | toUpper }}: {{ .CommonLabels.alertname }}'
        html: |
          <h2>{{ .Status | toUpper }}: {{ .CommonLabels.alertname }}</h2>
          <p><strong>Severity:</strong> {{ .CommonLabels.severity }}</p>
          <p><strong>Instance:</strong> {{ .CommonLabels.instance }}</p>
          <p><strong>Description:</strong> {{ .CommonAnnotations.description }}</p>
          {{ if .CommonAnnotations.runbook_url }}
          <p><a href="{{ .CommonAnnotations.runbook_url }}">View Runbook</a></p>
          {{ end }}

  - name: 'email-security'
    email_configs:
      - to: 'security@company.com'
        send_resolved: true
```

---

## Complete Configuration Example

```yaml
# /etc/alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR_WORKSPACE/YOUR_CHANNEL/YOUR_TOKEN'
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alertmanager@company.com'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  receiver: 'slack-default'
  group_by: ['alertname', 'severity', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    # Critical - PagerDuty + Slack + Email
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true
    - match:
        severity: critical
      receiver: 'slack-critical'
      continue: true
    - match:
        severity: critical
      receiver: 'email-ops'

    # Security alerts - Security team
    - match:
        category: security
      receiver: 'slack-security'
      continue: true
    - match:
        category: security
      receiver: 'email-security'

    # High - Slack during business hours, PagerDuty after hours
    - match:
        severity: high
      receiver: 'slack-high'
      active_time_intervals:
        - business-hours
    - match:
        severity: high
      receiver: 'pagerduty-high'
      active_time_intervals:
        - after-hours

    # Teams for OT team
    - match:
        team: ot
      receiver: 'teams-ot'

inhibit_rules:
  - source_match:
      severity: critical
    target_match:
      severity: high
    equal: ['alertname', 'instance']
  - source_match:
      alertname: PAM4OTNodeDown
    target_match:
      alertname: HighCPU
    equal: ['instance']

receivers:
  - name: 'slack-default'
    slack_configs:
      - channel: '#pam4ot-alerts'
        send_resolved: true

  - name: 'slack-critical'
    slack_configs:
      - channel: '#pam4ot-critical'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'

  - name: 'slack-high'
    slack_configs:
      - channel: '#pam4ot-alerts'
        send_resolved: true
        color: 'warning'

  - name: 'slack-security'
    slack_configs:
      - channel: '#security-alerts'
        send_resolved: true

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'xxx'
        severity: critical

  - name: 'pagerduty-high'
    pagerduty_configs:
      - service_key: 'xxx'
        severity: error

  - name: 'teams-ot'
    webhook_configs:
      - url: 'http://localhost:8089/teams'

  - name: 'email-ops'
    email_configs:
      - to: 'ops@company.com'

  - name: 'email-security'
    email_configs:
      - to: 'security@company.com'

time_intervals:
  - name: business-hours
    time_intervals:
      - weekdays: ['monday:friday']
        times:
          - start_time: '09:00'
            end_time: '18:00'
  - name: after-hours
    time_intervals:
      - weekdays: ['saturday', 'sunday']
      - times:
          - start_time: '18:00'
            end_time: '09:00'
```

---

## Testing and Validation

### Test All Receivers

```bash
# Create test script
cat > /tmp/test-alerts.sh << 'EOF'
#!/bin/bash

# Test critical alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestCritical",
      "severity": "critical",
      "instance": "pam4ot-node1:9100"
    },
    "annotations": {
      "description": "Test critical alert",
      "runbook_url": "https://wiki.company.com/runbooks/test"
    }
  }]'

sleep 5

# Test high alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestHigh",
      "severity": "high",
      "instance": "pam4ot-node1:9100"
    },
    "annotations": {
      "description": "Test high alert"
    }
  }]'

sleep 5

# Test security alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestSecurity",
      "severity": "high",
      "category": "security",
      "instance": "pam4ot-node1:9100"
    },
    "annotations": {
      "description": "Test security alert"
    }
  }]'

echo "Test alerts sent. Check your notification channels."
EOF

chmod +x /tmp/test-alerts.sh
/tmp/test-alerts.sh
```

### Verify Alert Routing

```bash
# Check active alerts
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | {alertname: .labels.alertname, status: .status.state}'

# Check silences
curl -s http://localhost:9093/api/v1/silences | jq '.data[] | {id: .id, matchers: .matchers}'

# View Alertmanager status
curl -s http://localhost:9093/api/v1/status | jq
```

---

<p align="center">
  <a href="./README.md">← Back to Best Practices</a>
</p>
