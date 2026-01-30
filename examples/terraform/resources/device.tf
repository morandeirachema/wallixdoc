# WALLIX Bastion Device Configuration Examples
# Manages target devices and their services

# -----------------------------------------------------------------------------
# Linux Server with SSH
# -----------------------------------------------------------------------------
resource "wallix-bastion_device" "linux_server" {
  device_name = "linux-prod-01"
  description = "Production Linux Server"
  host        = "192.168.1.100"
  alias       = "linux-prod-01.example.com"
}

resource "wallix-bastion_device_service" "linux_ssh" {
  device_id       = wallix-bastion_device.linux_server.id
  service_name    = "SSH"
  protocol        = "SSH"
  port            = 22
  connection_policy = "default"
}

# Local account on the device
resource "wallix-bastion_device_localdomain_account" "linux_root" {
  device_id    = wallix-bastion_device.linux_server.id
  domain_id    = wallix-bastion_device_localdomain.linux_local.id
  account_name = "root"
  account_login = "root"
  auto_change_password = true
}

resource "wallix-bastion_device_localdomain" "linux_local" {
  device_id   = wallix-bastion_device.linux_server.id
  domain_name = "local"
}

# -----------------------------------------------------------------------------
# Windows Server with RDP
# -----------------------------------------------------------------------------
resource "wallix-bastion_device" "windows_server" {
  device_name = "windows-prod-01"
  description = "Production Windows Server"
  host        = "192.168.1.101"
  alias       = "windows-prod-01.example.com"
}

resource "wallix-bastion_device_service" "windows_rdp" {
  device_id       = wallix-bastion_device.windows_server.id
  service_name    = "RDP"
  protocol        = "RDP"
  port            = 3389
  connection_policy = "default"
}

# -----------------------------------------------------------------------------
# Network Device with SSH
# -----------------------------------------------------------------------------
resource "wallix-bastion_device" "network_switch" {
  device_name = "switch-core-01"
  description = "Core Network Switch"
  host        = "192.168.1.1"
}

resource "wallix-bastion_device_service" "switch_ssh" {
  device_id       = wallix-bastion_device.network_switch.id
  service_name    = "SSH"
  protocol        = "SSH"
  port            = 22
  connection_policy = "default"
}

# -----------------------------------------------------------------------------
# Database Server
# -----------------------------------------------------------------------------
resource "wallix-bastion_device" "database_server" {
  device_name = "db-prod-01"
  description = "Production MariaDB Database"
  host        = "192.168.1.50"
}

resource "wallix-bastion_device_service" "db_ssh" {
  device_id       = wallix-bastion_device.database_server.id
  service_name    = "SSH"
  protocol        = "SSH"
  port            = 22
  connection_policy = "default"
}

# -----------------------------------------------------------------------------
# OT/Industrial Device (PLC)
# -----------------------------------------------------------------------------
resource "wallix-bastion_device" "plc_device" {
  device_name = "plc-line-01"
  description = "Production Line PLC - Zone 2"
  host        = "10.20.1.100"
}

resource "wallix-bastion_device_service" "plc_http" {
  device_id       = wallix-bastion_device.plc_device.id
  service_name    = "HTTPS"
  protocol        = "HTTPS"
  port            = 443
  connection_policy = "default"
}

# -----------------------------------------------------------------------------
# Target Group for organizing devices
# -----------------------------------------------------------------------------
resource "wallix-bastion_targetgroup" "production_servers" {
  group_name  = "production-servers"
  description = "All production server targets"
}

resource "wallix-bastion_targetgroup" "ot_devices" {
  group_name  = "ot-devices"
  description = "Industrial/OT devices"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "linux_server_id" {
  description = "ID of the Linux server device"
  value       = wallix-bastion_device.linux_server.id
}

output "windows_server_id" {
  description = "ID of the Windows server device"
  value       = wallix-bastion_device.windows_server.id
}
