#!/bin/bash
# provision-vms.sh
# VM Provisioning Script for PAM4OT Pre-Production Lab
# This script generates cloud-init configurations and provides guidance

set -e

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

LAB_DOMAIN="lab.local"
DNS_SERVER="10.10.1.10"
GATEWAY_MGMT="10.10.1.1"
GATEWAY_IT="10.10.2.1"
GATEWAY_OT="10.10.3.1"

# Output directory
OUTPUT_DIR="./vm-configs"

#------------------------------------------------------------------------------
# VM Definitions
#------------------------------------------------------------------------------

declare -A VMS=(
    # Management VLAN
    ["dc-lab"]="10.10.1.10|4|8192|100|Windows Server 2022|Active Directory Domain Controller"
    ["pam4ot-node1"]="10.10.1.11|4|8192|150|Debian 12|PAM4OT Primary Node"
    ["pam4ot-node2"]="10.10.1.12|4|8192|150|Debian 12|PAM4OT Secondary Node"
    ["siem-lab"]="10.10.1.50|4|8192|200|Ubuntu 22.04|SIEM (Splunk/ELK)"
    ["monitoring-lab"]="10.10.1.60|2|4096|100|Ubuntu 22.04|Prometheus/Grafana"

    # IT Test VLAN
    ["linux-test"]="10.10.2.10|2|2048|50|Ubuntu 22.04|SSH Test Target"
    ["windows-test"]="10.10.2.20|2|4096|50|Windows Server 2022|RDP Test Target"
    ["network-test"]="10.10.2.30|1|1024|10|VyOS|Network Device Test"

    # OT Test VLAN
    ["plc-sim"]="10.10.3.10|2|2048|50|Ubuntu 22.04|PLC/Modbus Simulator"
)

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

print_header() {
    echo ""
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

generate_cloud_init() {
    local name=$1
    local ip=$2
    local gateway=$3
    local os=$4
    local description=$5

    if [[ "$os" == *"Windows"* ]]; then
        # Skip cloud-init for Windows
        return
    fi

    local config_file="$OUTPUT_DIR/${name}-cloud-init.yaml"

    cat > "$config_file" << EOF
#cloud-config
# Cloud-init configuration for: $name
# Description: $description

hostname: $name
fqdn: ${name}.${LAB_DOMAIN}
manage_etc_hosts: true

# User configuration
users:
  - name: pam4ot-admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... # Add your SSH public key here

# Set password (change this!)
chpasswd:
  list: |
    pam4ot-admin:Pam4otLab123!
    root:RootLab123!
  expire: false

# Package updates
package_update: true
package_upgrade: true

# Install common packages
packages:
  - curl
  - wget
  - vim
  - net-tools
  - dnsutils
  - htop
  - chrony

# Network configuration
write_files:
  - path: /etc/netplan/00-installer-config.yaml
    content: |
      network:
        version: 2
        ethernets:
          ens192:
            addresses: [$ip/24]
            routes:
              - to: default
                via: $gateway
            nameservers:
              addresses: [$DNS_SERVER]
              search: [$LAB_DOMAIN]

# Run commands
runcmd:
  - netplan apply
  - timedatectl set-timezone UTC
  - systemctl enable chrony
  - systemctl start chrony
  - echo "$name setup complete" > /var/log/cloud-init-complete.log

# Final message
final_message: "Cloud-init completed for $name after \$UPTIME seconds"
EOF

    echo "  Generated: $config_file"
}

generate_terraform() {
    print_header "Generating Terraform Configuration"

    local tf_file="$OUTPUT_DIR/main.tf"

    cat > "$tf_file" << 'EOF'
# main.tf - PAM4OT Lab Infrastructure
# Provider: VMware vSphere (adjust for your environment)

terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

variable "vsphere_server" {
  description = "vSphere server address"
}

variable "vsphere_user" {
  description = "vSphere username"
}

variable "vsphere_password" {
  description = "vSphere password"
  sensitive   = true
}

provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = true
}

# Data sources
data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Cluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "mgmt_network" {
  name          = "VLAN-Management"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "it_network" {
  name          = "VLAN-IT-Test"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "ot_network" {
  name          = "VLAN-OT-Test"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# VM definitions
locals {
  vms = {
    "pam4ot-node1" = {
      ip       = "10.10.1.11"
      cpu      = 4
      memory   = 8192
      disk     = 150
      network  = data.vsphere_network.mgmt_network.id
      template = "debian-12-template"
    }
    "pam4ot-node2" = {
      ip       = "10.10.1.12"
      cpu      = 4
      memory   = 8192
      disk     = 150
      network  = data.vsphere_network.mgmt_network.id
      template = "debian-12-template"
    }
    "siem-lab" = {
      ip       = "10.10.1.50"
      cpu      = 4
      memory   = 8192
      disk     = 200
      network  = data.vsphere_network.mgmt_network.id
      template = "ubuntu-22.04-template"
    }
    "monitoring-lab" = {
      ip       = "10.10.1.60"
      cpu      = 2
      memory   = 4096
      disk     = 100
      network  = data.vsphere_network.mgmt_network.id
      template = "ubuntu-22.04-template"
    }
    "linux-test" = {
      ip       = "10.10.2.10"
      cpu      = 2
      memory   = 2048
      disk     = 50
      network  = data.vsphere_network.it_network.id
      template = "ubuntu-22.04-template"
    }
    "plc-sim" = {
      ip       = "10.10.3.10"
      cpu      = 2
      memory   = 2048
      disk     = 50
      network  = data.vsphere_network.ot_network.id
      template = "ubuntu-22.04-template"
    }
  }
}

# Create VMs
resource "vsphere_virtual_machine" "vm" {
  for_each = local.vms

  name             = each.key
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = each.value.cpu
  memory   = each.value.memory

  network_interface {
    network_id = each.value.network
  }

  disk {
    label            = "disk0"
    size             = each.value.disk
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template[each.value.template].id
  }

  # cloud-init
  extra_config = {
    "guestinfo.userdata"          = base64encode(file("${each.key}-cloud-init.yaml"))
    "guestinfo.userdata.encoding" = "base64"
  }
}

output "vm_ips" {
  value = {
    for name, vm in vsphere_virtual_machine.vm : name => vm.default_ip_address
  }
}
EOF

    echo "  Generated: $tf_file"
}

generate_ansible_inventory() {
    print_header "Generating Ansible Inventory"

    local inv_file="$OUTPUT_DIR/inventory.yml"

    cat > "$inv_file" << EOF
# inventory.yml - PAM4OT Lab Ansible Inventory
all:
  vars:
    ansible_user: pam4ot-admin
    ansible_ssh_private_key_file: ~/.ssh/pam4ot-lab
    ansible_python_interpreter: /usr/bin/python3

  children:
    pam4ot:
      hosts:
        pam4ot-node1:
          ansible_host: 10.10.1.11
        pam4ot-node2:
          ansible_host: 10.10.1.12
      vars:
        pam4ot_vip: 10.10.1.100
        pam4ot_cluster_name: pam4ot-cluster

    infrastructure:
      hosts:
        siem-lab:
          ansible_host: 10.10.1.50
        monitoring-lab:
          ansible_host: 10.10.1.60

    test_targets:
      children:
        linux_targets:
          hosts:
            linux-test:
              ansible_host: 10.10.2.10
        ot_targets:
          hosts:
            plc-sim:
              ansible_host: 10.10.3.10

    windows:
      hosts:
        dc-lab:
          ansible_host: 10.10.1.10
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
        windows-test:
          ansible_host: 10.10.2.20
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_winrm_server_cert_validation: ignore
EOF

    echo "  Generated: $inv_file"
}

generate_vagrant() {
    print_header "Generating Vagrant Configuration"

    local vf_file="$OUTPUT_DIR/Vagrantfile"

    cat > "$vf_file" << 'EOF'
# Vagrantfile - PAM4OT Lab (for local development/testing)
# Note: This is for testing purposes. Production should use proper VMs.

Vagrant.configure("2") do |config|

  # Common settings
  config.vm.box_check_update = false

  # PAM4OT Node 1
  config.vm.define "pam4ot-node1" do |node|
    node.vm.box = "debian/bookworm64"
    node.vm.hostname = "pam4ot-node1"
    node.vm.network "private_network", ip: "10.10.1.11"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end
    node.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y curl wget
    SHELL
  end

  # PAM4OT Node 2
  config.vm.define "pam4ot-node2" do |node|
    node.vm.box = "debian/bookworm64"
    node.vm.hostname = "pam4ot-node2"
    node.vm.network "private_network", ip: "10.10.1.12"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end
  end

  # Linux Test Target
  config.vm.define "linux-test" do |node|
    node.vm.box = "ubuntu/jammy64"
    node.vm.hostname = "linux-test"
    node.vm.network "private_network", ip: "10.10.2.10"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
    node.vm.provision "shell", inline: <<-SHELL
      # Enable root SSH for testing
      sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      systemctl restart sshd
      echo "root:LinuxRoot123!" | chpasswd
    SHELL
  end

  # Monitoring
  config.vm.define "monitoring-lab" do |node|
    node.vm.box = "ubuntu/jammy64"
    node.vm.hostname = "monitoring-lab"
    node.vm.network "private_network", ip: "10.10.1.60"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end

end
EOF

    echo "  Generated: $vf_file"
}

print_vm_summary() {
    print_header "VM Summary"

    printf "%-20s %-15s %-5s %-8s %-6s %-25s %s\n" \
        "Name" "IP" "vCPU" "Memory" "Disk" "OS" "Description"
    printf "%-20s %-15s %-5s %-8s %-6s %-25s %s\n" \
        "--------------------" "---------------" "-----" "--------" "------" \
        "-------------------------" "-------------------------"

    for name in "${!VMS[@]}"; do
        IFS='|' read -r ip cpu mem disk os desc <<< "${VMS[$name]}"
        printf "%-20s %-15s %-5s %-8s %-6s %-25s %s\n" \
            "$name" "$ip" "$cpu" "${mem}MB" "${disk}GB" "$os" "$desc"
    done | sort
}

print_network_summary() {
    print_header "Network Configuration"

    echo "VLANs:"
    echo "  Management VLAN: 10.10.1.0/24 (Gateway: $GATEWAY_MGMT)"
    echo "  IT-Test VLAN:    10.10.2.0/24 (Gateway: $GATEWAY_IT)"
    echo "  OT-Test VLAN:    10.10.3.0/24 (Gateway: $GATEWAY_OT)"
    echo ""
    echo "DNS Server: $DNS_SERVER"
    echo "Domain: $LAB_DOMAIN"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "============================================================"
    echo "  PAM4OT Pre-Production Lab - VM Provisioning"
    echo "============================================================"
    echo ""

    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    echo "Output directory: $OUTPUT_DIR"

    # Print summaries
    print_vm_summary
    print_network_summary

    # Generate configurations
    print_header "Generating Cloud-Init Configurations"

    for name in "${!VMS[@]}"; do
        IFS='|' read -r ip cpu mem disk os desc <<< "${VMS[$name]}"

        # Determine gateway based on IP
        if [[ "$ip" == 10.10.1.* ]]; then
            gateway=$GATEWAY_MGMT
        elif [[ "$ip" == 10.10.2.* ]]; then
            gateway=$GATEWAY_IT
        elif [[ "$ip" == 10.10.3.* ]]; then
            gateway=$GATEWAY_OT
        fi

        generate_cloud_init "$name" "$ip" "$gateway" "$os" "$desc"
    done

    # Generate other configs
    generate_terraform
    generate_ansible_inventory
    generate_vagrant

    print_header "Next Steps"

    echo "1. Review generated configurations in: $OUTPUT_DIR/"
    echo ""
    echo "2. For VMware vSphere:"
    echo "   cd $OUTPUT_DIR"
    echo "   terraform init"
    echo "   terraform plan"
    echo "   terraform apply"
    echo ""
    echo "3. For Vagrant (local testing):"
    echo "   cd $OUTPUT_DIR"
    echo "   vagrant up"
    echo ""
    echo "4. For Ansible provisioning:"
    echo "   ansible-playbook -i $OUTPUT_DIR/inventory.yml site.yml"
    echo ""
    echo "5. Manual VM creation:"
    echo "   - Create VMs matching specs above"
    echo "   - Apply cloud-init configs during provisioning"
    echo "   - Or configure network/packages manually"
    echo ""

    print_header "Files Generated"
    ls -la "$OUTPUT_DIR/"
}

# Run
main "$@"
