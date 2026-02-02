# Debian 12 Installation with LUKS Full Disk Encryption

## Complete Guide for WALLIX Bastion 12.x Infrastructure

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Pre-Installation Preparation](#pre-installation-preparation)
- [BIOS/UEFI Configuration](#biosuefi-configuration)
- [Booting the Installer](#booting-the-installer)
- [Installation Walkthrough](#installation-walkthrough)
  - [Language and Location](#step-1-language-and-location)
  - [Network Configuration](#step-2-network-configuration)
  - [User Setup](#step-3-user-setup)
  - [Disk Partitioning with LUKS](#step-4-disk-partitioning-with-luks)
  - [Base System Installation](#step-5-base-system-installation)
  - [Package Selection](#step-6-package-selection)
  - [Bootloader Installation](#step-7-bootloader-installation)
- [Post-Installation Configuration](#post-installation-configuration)
- [LUKS Management](#luks-management)
- [Partitioning Schemes](#partitioning-schemes)
- [Advanced LUKS Configuration](#advanced-luks-configuration)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

---

## Overview

This guide provides step-by-step instructions for installing **Debian 12 (Bookworm)** with **LUKS full disk encryption** as the foundation for WALLIX Bastion 12.x deployment.

### Why LUKS Encryption?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    LUKS ENCRYPTION BENEFITS                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SECURITY                              COMPLIANCE                           │
│  ════════                              ══════════                           │
│  • Data at rest protection             • IEC 62443 requirement              │
│  • Protection against physical         • NIST 800-82 recommended            │
│    theft                               • NIS2 Directive aligned             │
│  • Secure decommissioning              • ISO 27001 control                  │
│  • Tamper evidence                     • GDPR data protection               │
│                                                                             │
│  OPERATIONAL                           WALLIX 12.x                          │
│  ═══════════                           ═══════════                          │
│  • Transparent to applications         • Required for new installs          │
│  • No performance impact on            • Protects credential vault          │
│    modern hardware (AES-NI)            • Secures session recordings         │
│  • Standard Linux tooling              • Complements Argon2ID               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### LUKS2 vs LUKS1

| Feature | LUKS1 | LUKS2 (Recommended) |
|---------|-------|---------------------|
| **Header Size** | 2 MB | 16 MB (more metadata) |
| **Key Derivation** | PBKDF2 | Argon2id (default) |
| **Authenticated Encryption** | No | Yes (AEAD) |
| **Token Support** | No | Yes (TPM2, FortiToken) |
| **Online Reencryption** | Limited | Full support |
| **Debian 12 Default** | No | Yes |

---

## Prerequisites

### Virtual Machine Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **vCPU** | 4 vCPU | 8 vCPU | Enable AES-NI passthrough |
| **RAM** | 8 GB | 16+ GB | Reserve memory, no ballooning |
| **OS Disk** | 100 GB | 200 GB | Thin provisioning OK |
| **Data Disk** | 250 GB | 500 GB | For /var (session recordings) |
| **Network** | 1x vNIC | 2x vNIC | Management + OT network |
| **Boot Mode** | UEFI | UEFI | Required for Secure Boot |

### Hypervisor Compatibility

| Hypervisor | Version | AES-NI Support | Notes |
|------------|---------|----------------|-------|
| **VMware vSphere** | 7.0+ | Yes (default) | Recommended for enterprise |
| **VMware Workstation** | 16+ | Yes | Lab/dev environments |
| **Proxmox VE** | 7.0+ | Yes (CPU type: host) | Open-source option |
| **Microsoft Hyper-V** | 2019+ | Yes | Windows environments |
| **KVM/QEMU** | Latest | Yes (cpu host) | Linux native |
| **Oracle VirtualBox** | 7.0+ | Limited | Not recommended for production |

### Required Materials

```
[ ] Debian 12 (Bookworm) installation ISO
    └── Download: https://www.debian.org/download
    └── Recommended: debian-12.x.x-amd64-netinst.iso

[ ] Bootable USB drive (8GB+)
    └── Tool: Rufus (Windows), dd (Linux), balenaEtcher (Cross-platform)

[ ] Network connectivity
    └── DHCP or static IP information

[ ] Strong LUKS passphrase
    └── Minimum 20 characters recommended
    └── Mix of uppercase, lowercase, numbers, symbols

[ ] Server specifications document
    └── Hostname, IP address, gateway, DNS
```

### Verify ISO Integrity

```bash
# Download SHA256SUMS and signature
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS.sign

# Verify checksum
sha256sum -c SHA256SUMS 2>/dev/null | grep debian-12

# Verify GPG signature (optional but recommended)
gpg --verify SHA256SUMS.sign SHA256SUMS
```

---

## Pre-Installation Preparation

### 1. Create Bootable USB

#### On Linux:

```bash
# Identify USB device (BE CAREFUL - this will erase the device)
lsblk

# Write ISO to USB (replace /dev/sdX with your USB device)
sudo dd if=debian-12.x.x-amd64-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Sync and eject
sync
sudo eject /dev/sdX
```

#### On Windows (using Rufus):

```
1. Download Rufus from https://rufus.ie
2. Insert USB drive
3. Select Debian ISO
4. Partition scheme: GPT (for UEFI) or MBR (for Legacy)
5. Target system: UEFI (non CSM) recommended
6. Click START
7. Select "Write in DD Image mode" if prompted
```

#### On macOS:

```bash
# List disks
diskutil list

# Unmount USB (replace diskN with your USB disk number)
diskutil unmountDisk /dev/diskN

# Write ISO
sudo dd if=debian-12.x.x-amd64-netinst.iso of=/dev/rdiskN bs=4m

# Eject
diskutil eject /dev/diskN
```

### 2. Document Server Configuration

Before starting, document your planned configuration:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SERVER CONFIGURATION WORKSHEET                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  IDENTITY                                                                   │
│  ────────                                                                   │
│  Hostname:        _________________________ (e.g., wallix-a1)               │
│  Domain:          _________________________ (e.g., corp.local)              │
│  FQDN:            _________________________ (e.g., wallix-a1.corp.local)    │
│                                                                             │
│  NETWORK (Management Interface)                                             │
│  ──────────────────────────────                                             │
│  IP Address:      _________________________ (e.g., 10.0.1.10)               │
│  Netmask:         _________________________ (e.g., 255.255.255.0)           │
│  Gateway:         _________________________ (e.g., 10.0.1.1)                │
│  DNS Server 1:    _________________________ (e.g., 10.0.1.2)                │
│  DNS Server 2:    _________________________ (e.g., 10.0.1.3)                │
│                                                                             │
│  DISK LAYOUT                                                                │
│  ───────────                                                                │
│  Primary Disk:    _________________________ (e.g., /dev/sda, /dev/nvme0n1)  │
│  Disk Size:       _________________________ (e.g., 200 GB)                  │
│  Encryption:      [X] LUKS2 Full Disk                                       │
│                                                                             │
│  ACCOUNTS                                                                   │
│  ────────                                                                   │
│  Root Password:   _________________________ (store securely!)               │
│  Admin User:      _________________________ (e.g., wallixadmin)             │
│  Admin Password:  _________________________ (store securely!)               │
│  LUKS Passphrase: _________________________ (store securely!)               │
│                                                                             │
│  TIME                                                                       │
│  ────                                                                       │
│  Timezone:        _________________________ (e.g., Europe/Paris)            │
│  NTP Server:      _________________________ (e.g., ntp.corp.local)          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3. Generate Strong LUKS Passphrase

```bash
# Option 1: Random passphrase (recommended for servers with console access)
# Generate 4 random words
shuf -n4 /usr/share/dict/words | tr '\n' '-' | sed 's/-$/\n/'

# Option 2: High-entropy random string
openssl rand -base64 32

# Option 3: Diceware-style (manual dice rolls for highest security)
# Use EFF wordlist: https://www.eff.org/dice
```

**Passphrase Requirements for WALLIX Deployment:**
- Minimum 20 characters
- Store in secure password manager
- Document recovery procedures
- Consider key escrow for enterprise environments

---

## VM Firmware Configuration

### Accessing VM Console

| Hypervisor | Console Access |
|------------|----------------|
| **VMware vSphere** | vSphere Client → VM → Launch Web Console |
| **VMware Workstation** | Window → VM Console |
| **Proxmox VE** | Web UI → VM → Console (noVNC or xterm.js) |
| **Hyper-V** | Hyper-V Manager → Connect |
| **KVM/virt-manager** | virt-manager → Open Console |

### VM Firmware Settings (UEFI)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VM FIRMWARE CHECKLIST                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  BOOT SETTINGS                                                              │
│  ═════════════                                                              │
│  [X] Firmware: UEFI (not BIOS/Legacy)                                       │
│  [ ] Secure Boot: Disabled for installation, enable after                   │
│  [X] Boot Order: CD/DVD first, then disk                                    │
│                                                                             │
│  HYPERVISOR SETTINGS (Configure BEFORE creating VM)                         │
│  ═══════════════════════════════════════════════════                        │
│  [X] CPU Type: host-passthrough (KVM) or "host" (Proxmox)                  │
│      VMware: AES-NI enabled by default                                     │
│  [X] Memory: Fixed allocation, no ballooning                               │
│  [X] Disk Controller: VirtIO-SCSI (Proxmox/KVM) or PVSCSI (VMware)        │
│  [X] Network: VirtIO (Proxmox/KVM) or VMXNET3 (VMware)                     │
│                                                                             │
│  NOTE: Most VM-specific settings are configured at VM creation,            │
│        not in the VM's UEFI firmware menu.                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### VMware UEFI Boot Menu

Press **F2** during VM boot to access:
- Boot Manager
- Enter Setup (rarely needed)
- Enter EFI Shell

Press **Esc** for one-time boot menu.

### Verify AES-NI Support

AES-NI hardware acceleration is critical for LUKS performance:

```bash
# Check from existing Linux system
grep -o aes /proc/cpuinfo | head -1

# Or check CPU flags
cat /proc/cpuinfo | grep -i aes
```

---

## Virtual Machine Setup

### VMware vSphere / ESXi Configuration

#### Create New Virtual Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VMWARE VM CONFIGURATION                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STEP 1: Create New VM                                                      │
│  ─────────────────────                                                      │
│  • Name: wallix-a1                                                          │
│  • Compatibility: ESXi 7.0 and later                                        │
│  • Guest OS Family: Linux                                                   │
│  • Guest OS Version: Debian GNU/Linux 12 (64-bit)                          │
│                                                                             │
│  STEP 2: Customize Hardware                                                 │
│  ──────────────────────────                                                 │
│  • CPU: 8 vCPU                                                              │
│    └── Hardware virtualization: Expose to guest (for nested virt)          │
│  • Memory: 16 GB                                                            │
│    └── Reserve all guest memory (recommended)                              │
│  • Hard Disk 1: 200 GB (OS)                                                │
│    └── Thin provisioning OK                                                │
│  • Hard Disk 2: 500 GB (Data) - Add after initial setup                    │
│  • Network Adapter 1: Management network                                    │
│    └── Adapter Type: VMXNET3                                               │
│  • Network Adapter 2: OT network (optional)                                │
│    └── Adapter Type: VMXNET3                                               │
│  • CD/DVD: Debian 12 ISO                                                   │
│    └── Connect at power on: Yes                                            │
│                                                                             │
│  STEP 3: VM Options                                                         │
│  ──────────────────                                                         │
│  • Boot Options: UEFI                                                       │
│    └── Secure Boot: Enabled (optional)                                     │
│  • VMware Tools: Will install after OS                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### VMware Advanced Settings for AES-NI

```
# Edit VM settings → VM Options → Advanced → Edit Configuration

# Add these parameters to enable AES-NI passthrough:
cpuid.aes = "TRUE"

# Or via PowerCLI:
Get-VM "wallix-a1" | New-AdvancedSetting -Name "cpuid.aes" -Value "TRUE" -Confirm:$false
```

#### VMware vSphere VM Template (Reference)

```yaml
# VM Specification for WALLIX Bastion Node
name: wallix-template
guest_os: debian12_64Guest
hardware:
  cpu:
    count: 8
    cores_per_socket: 4
    hot_add: false
    hardware_virtualization: true
  memory:
    size_mb: 16384
    hot_add: false
    reservation: 16384  # Full reservation
  disks:
    - label: "OS Disk"
      size_gb: 200
      type: thin
      controller: pvscsi
    - label: "Data Disk"
      size_gb: 500
      type: thin
      controller: pvscsi
  nics:
    - label: "Management"
      network: "VLAN_Management"
      type: vmxnet3
    - label: "OT Network"
      network: "VLAN_OT"
      type: vmxnet3
  boot:
    firmware: efi
    secure_boot: true
    boot_order: [cdrom, disk]
```

### Proxmox VE Configuration

#### Create VM via Web UI

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PROXMOX VM CONFIGURATION                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  General:                                                                   │
│  ────────                                                                   │
│  • VM ID: 100                                                               │
│  • Name: wallix-a1                                                          │
│  • Start at boot: Yes                                                       │
│                                                                             │
│  OS:                                                                        │
│  ───                                                                        │
│  • ISO Image: debian-12.x.x-amd64-netinst.iso                              │
│  • Type: Linux                                                              │
│  • Version: 6.x - 2.6 Kernel                                               │
│                                                                             │
│  System:                                                                    │
│  ───────                                                                    │
│  • Machine: q35                                                             │
│  • BIOS: OVMF (UEFI)                                                       │
│  • EFI Storage: local-lvm                                                  │
│  • SCSI Controller: VirtIO SCSI                                            │
│  • Qemu Agent: Yes                                                         │
│                                                                             │
│  Disks:                                                                     │
│  ──────                                                                     │
│  • Bus/Device: SCSI                                                        │
│  • Storage: local-lvm                                                      │
│  • Disk size: 200 GB                                                       │
│  • Cache: Write back                                                       │
│  • Discard: Yes (for SSD)                                                  │
│  • IO thread: Yes                                                          │
│                                                                             │
│  CPU:                                                                       │
│  ────                                                                       │
│  • Sockets: 1                                                               │
│  • Cores: 8                                                                 │
│  • Type: host  ← CRITICAL for AES-NI passthrough                           │
│                                                                             │
│  Memory:                                                                    │
│  ───────                                                                    │
│  • Memory: 16384 MB                                                         │
│  • Ballooning: No (disable for production)                                 │
│                                                                             │
│  Network:                                                                   │
│  ────────                                                                   │
│  • Bridge: vmbr0                                                            │
│  • Model: VirtIO (paravirtualized)                                         │
│  • VLAN Tag: (your management VLAN)                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Proxmox CLI (qm) Commands

```bash
# Create VM
qm create 100 \
    --name wallix-a1 \
    --memory 16384 \
    --balloon 0 \
    --cores 8 \
    --cpu host \
    --scsihw virtio-scsi-pci \
    --scsi0 local-lvm:200,discard=on,ssd=1 \
    --net0 virtio,bridge=vmbr0,tag=100 \
    --bios ovmf \
    --machine q35 \
    --efidisk0 local-lvm:1,efitype=4m \
    --boot order=scsi0 \
    --agent enabled=1 \
    --onboot 1

# Attach Debian ISO
qm set 100 --cdrom local:iso/debian-12.x.x-amd64-netinst.iso

# Start VM
qm start 100

# After installation, remove ISO
qm set 100 --cdrom none

# Add second disk for data (after OS install)
qm set 100 --scsi1 local-lvm:500,discard=on,ssd=1
```

### Microsoft Hyper-V Configuration

```powershell
# Create new VM
New-VM -Name "wallix-a1" `
    -MemoryStartupBytes 16GB `
    -Generation 2 `
    -NewVHDPath "C:\VMs\wallix-a1\os.vhdx" `
    -NewVHDSizeBytes 200GB `
    -SwitchName "Management"

# Configure CPU
Set-VMProcessor -VMName "wallix-a1" -Count 8

# Disable dynamic memory (important for production)
Set-VMMemory -VMName "wallix-a1" -DynamicMemoryEnabled $false

# Enable nested virtualization (includes AES-NI)
Set-VMProcessor -VMName "wallix-a1" -ExposeVirtualizationExtensions $true

# Disable Secure Boot for Debian (or add Microsoft UEFI CA)
Set-VMFirmware -VMName "wallix-a1" -EnableSecureBoot Off

# Or keep Secure Boot with proper template
Set-VMFirmware -VMName "wallix-a1" -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

# Add DVD drive with Debian ISO
Add-VMDvdDrive -VMName "wallix-a1" -Path "C:\ISOs\debian-12.x.x-amd64-netinst.iso"

# Set boot order (DVD first)
$dvd = Get-VMDvdDrive -VMName "wallix-a1"
Set-VMFirmware -VMName "wallix-a1" -FirstBootDevice $dvd

# Add second network adapter for OT network
Add-VMNetworkAdapter -VMName "wallix-a1" -SwitchName "OT_Network" -Name "OT"

# Start VM
Start-VM -Name "wallix-a1"
```

### KVM/QEMU Configuration

```bash
# Using virt-install
virt-install \
    --name wallix-a1 \
    --memory 16384 \
    --vcpus 8 \
    --cpu host-passthrough \
    --disk path=/var/lib/libvirt/images/wallix-a1-os.qcow2,size=200,format=qcow2,bus=virtio \
    --network network=default,model=virtio \
    --graphics none \
    --console pty,target_type=serial \
    --cdrom /var/lib/libvirt/images/debian-12.x.x-amd64-netinst.iso \
    --boot uefi \
    --os-variant debian12

# Using virsh with XML
virsh define wallix-a1.xml
virsh start wallix-a1
```

#### KVM XML Template

```xml
<domain type='kvm'>
  <name>wallix-a1</name>
  <memory unit='GiB'>16</memory>
  <vcpu placement='static'>8</vcpu>
  <cpu mode='host-passthrough' check='none' migratable='on'/>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE.fd</loader>
    <nvram>/var/lib/libvirt/qemu/nvram/wallix-a1_VARS.fd</nvram>
    <boot dev='cdrom'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' discard='unmap'/>
      <source file='/var/lib/libvirt/images/wallix-a1-os.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/images/debian-12.x.x-amd64-netinst.iso'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
</domain>
```

### Post-Installation: VM Guest Tools

After Debian installation, install guest tools:

#### VMware Tools

```bash
# Install open-vm-tools (recommended over VMware Tools)
sudo apt update
sudo apt install -y open-vm-tools

# For VMs that need desktop features (not needed for WALLIX)
# sudo apt install -y open-vm-tools-desktop

# Verify installation
vmware-toolbox-cmd -v
```

#### QEMU Guest Agent (Proxmox/KVM)

```bash
# Install QEMU guest agent
sudo apt update
sudo apt install -y qemu-guest-agent

# Enable and start
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

#### Hyper-V Integration Services

```bash
# Usually included in kernel, but verify:
lsmod | grep hv_

# If needed:
sudo apt install -y hyperv-daemons

# Services should auto-start
sudo systemctl status hv-fcopy-daemon
sudo systemctl status hv-kvp-daemon
sudo systemctl status hv-vss-daemon
```

---

## Booting the Installer

### 1. Insert USB and Power On

```
1. Insert bootable USB drive
2. Power on server
3. Press boot menu key (usually F12, F11, or Esc)
4. Select USB device from boot menu
```

### 2. Debian Boot Menu

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Debian GNU/Linux installer                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│     Graphical install          ← Use for servers with graphics             │
│     Install                    ← Text-based install (recommended)          │
│     Advanced options        >                                               │
│     Accessible dark contrast                                                │
│     Install with speech synthesis                                           │
│                                                                             │
│  ───────────────────────────────────────────────────────────────────────── │
│                                                                             │
│     Press ENTER to boot or TAB to edit boot options                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: "Install" (text-based) for server installations
```

### 3. Advanced Boot Options (Optional)

Press TAB on "Install" to add kernel parameters if needed:

```
Common parameters:
  nomodeset          - Disable kernel mode setting (for graphics issues)
  net.ifnames=0      - Use traditional interface names (eth0 instead of ens192)
  console=ttyS0      - Enable serial console (for remote management)
```

---

## Installation Walkthrough

### Step 1: Language and Location

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SELECT A LANGUAGE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Choose the language to be used for the installation process:               │
│                                                                             │
│    C            - No localization                                           │
│    English      - English                          ← RECOMMENDED            │
│    ...                                                                      │
│                                                                             │
│  NOTE: For servers, English is recommended for consistent                   │
│        documentation and troubleshooting                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

1. Select: English
2. Select: United States (or your country)
3. Select: American English (keyboard)
```

### Step 2: Network Configuration

#### Automatic (DHCP)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONFIGURE THE NETWORK                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Primary network interface:                                                 │
│                                                                             │
│    ens192: Intel Corporation Ethernet Controller                            │
│    ens224: Intel Corporation Ethernet Controller                            │
│                                                                             │
│  Select your primary (management) interface                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

If DHCP is available, network will configure automatically.
```

#### Manual (Static IP) - Recommended for Servers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONFIGURE THE NETWORK                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Network autoconfiguration failed                                           │
│                                                                             │
│    > Configure network manually                    ← SELECT THIS            │
│      Retry DHCP                                                             │
│      Do not configure network at this time                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Enter the following when prompted:

  IP address:     10.0.1.10              (your planned IP)
  Netmask:        255.255.255.0          (typically /24)
  Gateway:        10.0.1.1               (your default gateway)
  DNS servers:    10.0.1.2 10.0.1.3      (space-separated)
  Hostname:       wallix-a1              (short hostname)
  Domain:         corp.local             (your domain)
```

### Step 3: User Setup

#### Root Password

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SET UP USERS AND PASSWORDS                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  You need to set a password for 'root', the system administrator.           │
│                                                                             │
│  A good password will contain a mixture of letters, numbers and             │
│  punctuation and should be changed at regular intervals.                    │
│                                                                             │
│  Root password: ****************************************                    │
│                                                                             │
│  IMPORTANT: Use a strong, unique password. Store securely.                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Create Admin User

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SET UP USERS AND PASSWORDS                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Full name for the new user:     WALLIX Administrator                       │
│  Username for your account:      wallixadmin                                │
│  Password for the new user:      ****************************************   │
│                                                                             │
│  This user will have sudo privileges.                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 4: Disk Partitioning with LUKS

This is the **most critical section** for LUKS setup.

#### 4.1 Select Partitioning Method

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Partitioning method:                                                       │
│                                                                             │
│    Guided - use entire disk                                                 │
│    Guided - use entire disk and set up LVM                                  │
│    Guided - use entire disk and set up encrypted LVM    ← SELECT THIS       │
│    Manual                                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: "Guided - use entire disk and set up encrypted LVM"
```

#### 4.2 Select Disk

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Select disk to partition:                                                  │
│                                                                             │
│    SCSI1 (0,0,0) (sda) - 214.7 GB ATA VBOX HARDDISK                        │
│    SCSI2 (0,0,1) (sdb) - 536.9 GB ATA VBOX HARDDISK                        │
│                                                                             │
│  Select your primary OS disk (usually sda or nvme0n1)                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select your primary disk (the one for the OS installation).
```

#### 4.3 Select Partitioning Scheme

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Partitioning scheme:                                                       │
│                                                                             │
│    All files in one partition (recommended for new users)                   │
│    Separate /home partition                                                 │
│    Separate /home, /var, and /tmp partitions        ← RECOMMENDED           │
│                                                                             │
│  For WALLIX servers, separate partitions provide:                           │
│  - Better security isolation                                                │
│  - Easier capacity management                                               │
│  - Protection against log flooding                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: "Separate /home, /var, and /tmp partitions"
```

#### 4.4 Confirm Disk Write

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Write the changes to disks and configure LVM?                              │
│                                                                             │
│  ⚠️  WARNING: This will ERASE ALL DATA on the selected disk!               │
│                                                                             │
│  The following partitions will be created:                                  │
│                                                                             │
│    /dev/sda1 - ESP (EFI System Partition) - 512 MB                         │
│    /dev/sda2 - /boot - 1 GB (unencrypted, for bootloader)                  │
│    /dev/sda3 - LUKS encrypted volume (remainder)                           │
│                                                                             │
│                    <Yes>                    <No>                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: <Yes>
```

#### 4.5 Enter LUKS Encryption Passphrase

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ENCRYPTION CONFIGURATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  You need to enter a passphrase to encrypt the disk.                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  IMPORTANT: This passphrase is CRITICAL!                           │   │
│  │                                                                     │   │
│  │  • You will need it EVERY TIME the server boots                    │   │
│  │  • If lost, ALL DATA IS UNRECOVERABLE                              │   │
│  │  • Store securely in password manager AND physical safe            │   │
│  │  • Consider enterprise key escrow for production                   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Encryption passphrase: ________________________________________________   │
│                                                                             │
│  Re-enter passphrase to verify: ________________________________________   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Enter your prepared strong passphrase (minimum 20 characters recommended).
```

#### 4.6 Disk Erasure (Secure Wipe)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ENCRYPTION CONFIGURATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Erasing data on the disk for security...                                   │
│                                                                             │
│  This process writes random data to the entire disk partition               │
│  to prevent recovery of previous data. This may take a while.               │
│                                                                             │
│  ████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░  45%                   │
│                                                                             │
│  On a 200GB disk:                                                           │
│  - SSD: ~10-20 minutes                                                      │
│  - HDD: ~30-60 minutes                                                      │
│                                                                             │
│  TIP: For new SSDs, you can cancel this (Ctrl+C) as flash storage           │
│       doesn't retain data patterns like HDDs.                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 4.7 Configure LVM Volume Sizes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Amount of volume group to use for guided partitioning:                     │
│                                                                             │
│  Maximum: 199.7 GB                                                          │
│                                                                             │
│  Guided partitioning will create:                                           │
│                                                                             │
│    /      (root)  -  10 GB    (system files)                               │
│    /home          -  5 GB     (user home directories)                       │
│    /var           -  remaining (logs, WALLIX data)                          │
│    /tmp           -  2 GB     (temporary files)                             │
│    swap           -  16 GB    (equal to RAM recommended)                    │
│                                                                             │
│  Enter: max (or specific size like 180 GB)                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Enter: max (to use all available space)
```

#### 4.8 Review Partition Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PARTITION DISKS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  This is the partition layout that will be created:                         │
│                                                                             │
│  SCSI1 (0,0,0) (sda) - 214.7 GB ATA VBOX HARDDISK                          │
│  >     #1  primary   512.0 MB  B  f  ESP                                   │
│  >     #2  primary   1.0 GB       f  ext2   /boot                          │
│  >     #3  primary   213.2 GB     K  crypto (sda3_crypt)                   │
│  >                                                                          │
│  >  Encrypted volume (sda3_crypt) - 213.2 GB Linux device-mapper           │
│  >  >  #1  213.2 GB     K  lvm                                             │
│  >                                                                          │
│  >  LVM VG wallix-vg, LV home - 5.0 GB Linux device-mapper                 │
│  >  >  #1  5.0 GB        f  ext4   /home                                   │
│  >                                                                          │
│  >  LVM VG wallix-vg, LV root - 10.0 GB Linux device-mapper                │
│  >  >  #1  10.0 GB       f  ext4   /                                       │
│  >                                                                          │
│  >  LVM VG wallix-vg, LV swap_1 - 16.0 GB Linux device-mapper              │
│  >  >  #1  16.0 GB       f  swap   swap                                    │
│  >                                                                          │
│  >  LVM VG wallix-vg, LV tmp - 2.0 GB Linux device-mapper                  │
│  >  >  #1  2.0 GB        f  ext4   /tmp                                    │
│  >                                                                          │
│  >  LVM VG wallix-vg, LV var - 180.2 GB Linux device-mapper                │
│  >  >  #1  180.2 GB      f  ext4   /var                                    │
│                                                                             │
│  Finish partitioning and write changes to disk                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: "Finish partitioning and write changes to disk"
Then confirm: <Yes>
```

### Step 5: Base System Installation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      INSTALLING THE BASE SYSTEM                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Installing the base system...                                              │
│                                                                             │
│  ████████████████████████████████████████████████░░  95%                   │
│                                                                             │
│  Unpacking linux-image-6.1.0-amd64                                         │
│                                                                             │
│  This installs:                                                             │
│  - Linux kernel                                                             │
│  - Essential system utilities                                               │
│  - Basic libraries                                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 6: Package Selection

#### Configure Package Manager

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       CONFIGURE PACKAGE MANAGER                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Scan extra installation media?                                             │
│  > No                                                              ← SELECT │
│                                                                             │
│  Use a network mirror?                                                      │
│  > Yes                                                             ← SELECT │
│                                                                             │
│  Debian archive mirror country:                                             │
│  > United States (or nearest to you)                                        │
│                                                                             │
│  Debian archive mirror:                                                     │
│  > deb.debian.org                                                  ← SELECT │
│                                                                             │
│  HTTP proxy (leave blank for none):                                         │
│  > (blank, unless you require a proxy)                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Software Selection

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SOFTWARE SELECTION                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Choose software to install:                                                │
│                                                                             │
│    [ ] Debian desktop environment                                           │
│    [ ] ... GNOME                                                            │
│    [ ] ... Xfce                                                             │
│    [ ] ... GNOME Flashback                                                  │
│    [ ] ... KDE Plasma                                                       │
│    [ ] ... Cinnamon                                                         │
│    [ ] ... MATE                                                             │
│    [ ] ... LXDE                                                             │
│    [ ] ... LXQt                                                             │
│    [ ] web server                                                           │
│    [*] SSH server                                              ← SELECT     │
│    [*] standard system utilities                               ← SELECT     │
│                                                                             │
│  For WALLIX Bastion servers:                                                │
│  - Do NOT install desktop environment                                       │
│  - Do NOT install web server (WALLIX has its own)                          │
│  - SELECT SSH server                                                        │
│  - SELECT standard system utilities                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select ONLY:
  [*] SSH server
  [*] standard system utilities
```

### Step 7: Bootloader Installation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      INSTALL THE GRUB BOOT LOADER                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Install the GRUB boot loader to your primary drive?                        │
│                                                                             │
│  > Yes                                                             ← SELECT │
│                                                                             │
│  Device for boot loader installation:                                       │
│                                                                             │
│    /dev/sda (214 GB ATA VBOX HARDDISK)                            ← SELECT │
│    Enter device manually                                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Select: Yes, then select your primary disk (/dev/sda or /dev/nvme0n1)
```

### Installation Complete

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       FINISH THE INSTALLATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Installation is complete.                                                  │
│                                                                             │
│  Remove installation media and press ENTER to reboot.                       │
│                                                                             │
│  ⚠️  IMPORTANT: After reboot, you will be prompted for the LUKS            │
│     passphrase at the console BEFORE the system can boot.                   │
│                                                                             │
│                           <Continue>                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Post-Installation Configuration

### First Boot - LUKS Unlock

After reboot, you will see:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  Please unlock disk sda3_crypt:                                             │
│                                                                             │
│  Enter passphrase: _                                                        │
│                                                                             │
│  ⚠️  This prompt appears at EVERY boot                                     │
│  ⚠️  Requires physical console or IPMI/iLO/iDRAC access                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Enter your LUKS passphrase to unlock the encrypted volume.
```

### Initial System Configuration

After successful boot and login:

```bash
# 1. Update system packages
sudo apt update && sudo apt upgrade -y

# 2. Install essential packages for WALLIX
sudo apt install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    vim \
    htop \
    net-tools \
    dnsutils \
    chrony \
    rsync \
    unzip \
    cryptsetup-initramfs

# 3. Configure timezone
sudo timedatectl set-timezone Europe/Paris  # Adjust to your timezone

# 4. Configure NTP
sudo systemctl enable chrony
sudo systemctl start chrony

# 5. Verify LUKS status
sudo cryptsetup status sda3_crypt
```

### Verify LUKS Configuration

```bash
# Check encrypted volumes
lsblk -f

# Expected output:
# NAME                    FSTYPE      LABEL UUID                                   MOUNTPOINT
# sda
# ├─sda1                  vfat              XXXX-XXXX                              /boot/efi
# ├─sda2                  ext2              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /boot
# └─sda3                  crypto_LUKS       xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   └─sda3_crypt          LVM2_member       xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#     ├─wallix--vg-root   ext4              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /
#     ├─wallix--vg-swap_1 swap              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   [SWAP]
#     ├─wallix--vg-tmp    ext4              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /tmp
#     ├─wallix--vg-var    ext4              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /var
#     └─wallix--vg-home   ext4              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /home

# View LUKS header information
sudo cryptsetup luksDump /dev/sda3

# Verify LUKS version (should show Version: 2)
sudo cryptsetup luksDump /dev/sda3 | grep "Version:"
```

### Configure SSH Hardening

```bash
# Edit SSH configuration
sudo vim /etc/ssh/sshd_config

# Recommended settings for WALLIX servers:
```

```
# /etc/ssh/sshd_config - Hardened for WALLIX

# Protocol and Port
Port 22
Protocol 2

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Security
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

# Allowed users (adjust as needed)
AllowUsers wallixadmin

# Cryptography (high security)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Logging
LogLevel VERBOSE
```

```bash
# Restart SSH
sudo systemctl restart sshd

# Set up SSH key authentication
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Add your public key to ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## LUKS Management

### Add Backup Passphrase

LUKS supports up to 8 key slots. Add a backup passphrase:

```bash
# Add new passphrase (you'll need to enter an existing passphrase first)
sudo cryptsetup luksAddKey /dev/sda3

# Enter any existing passphrase: (enter current passphrase)
# Enter new passphrase: (enter backup passphrase)
# Verify passphrase: (confirm backup passphrase)

# Verify key slots
sudo cryptsetup luksDump /dev/sda3 | grep "Key Slot"
# Key Slot 0: ENABLED
# Key Slot 1: ENABLED  (your new backup key)
# Key Slot 2: DISABLED
# ...
```

### Add Key File (for Automated Unlock)

For environments with physical security, you can add a key file:

```bash
# Generate a random key file
sudo dd if=/dev/urandom of=/root/.luks-keyfile bs=4096 count=1
sudo chmod 400 /root/.luks-keyfile

# Add key file to LUKS
sudo cryptsetup luksAddKey /dev/sda3 /root/.luks-keyfile

# CAUTION: The key file must be stored securely!
# It provides full access to decrypt the disk.
```

### Remove a Key Slot

```bash
# Remove a specific key slot (e.g., slot 1)
sudo cryptsetup luksKillSlot /dev/sda3 1

# You'll be prompted for a remaining valid passphrase
```

### Change Passphrase

```bash
# Change passphrase in a specific slot
sudo cryptsetup luksChangeKey /dev/sda3

# Enter current passphrase
# Enter new passphrase
# Verify new passphrase
```

### Backup LUKS Header

**CRITICAL**: Always backup your LUKS header!

```bash
# Create header backup
sudo cryptsetup luksHeaderBackup /dev/sda3 \
    --header-backup-file /root/luks-header-backup-$(date +%Y%m%d).img

# Store this file SECURELY and SEPARATELY from the server
# Without the header and passphrase, data is unrecoverable

# Verify backup
file /root/luks-header-backup-*.img
# Should show: LUKS encrypted file, ver 2
```

### Restore LUKS Header (Emergency)

```bash
# DANGER: Only use if header is corrupted!
sudo cryptsetup luksHeaderRestore /dev/sda3 \
    --header-backup-file /root/luks-header-backup-YYYYMMDD.img
```

---

## Partitioning Schemes

### Scheme 1: Standard Server (Guided)

Suitable for most WALLIX deployments:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STANDARD SERVER PARTITION SCHEME                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Disk: 200 GB                                                               │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ sda1 │  ESP   │  512 MB  │  EFI System Partition (unencrypted)      │  │
│  ├──────┼────────┼──────────┼──────────────────────────────────────────┤  │
│  │ sda2 │ /boot  │  1 GB    │  Boot partition (unencrypted)            │  │
│  ├──────┼────────┼──────────┼──────────────────────────────────────────┤  │
│  │ sda3 │ LUKS   │  ~198 GB │  Encrypted container                     │  │
│  │      │        │          │                                          │  │
│  │      │  ┌─────┴──────────┴──────────────────────────────────────┐  │  │
│  │      │  │  LVM Physical Volume inside LUKS                      │  │  │
│  │      │  │                                                       │  │  │
│  │      │  │  wallix-vg (Volume Group)                            │  │  │
│  │      │  │  ├── root     10 GB   ext4   /                       │  │  │
│  │      │  │  ├── swap     16 GB   swap   [SWAP]                  │  │  │
│  │      │  │  ├── tmp       2 GB   ext4   /tmp                    │  │  │
│  │      │  │  ├── var     165 GB   ext4   /var                    │  │  │
│  │      │  │  └── home      5 GB   ext4   /home                   │  │  │
│  │      │  │                                                       │  │  │
│  │      │  └───────────────────────────────────────────────────────┘  │  │
│  └──────┴────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Scheme 2: High-Performance Server (Manual)

For large deployments with separate data disk:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 HIGH-PERFORMANCE SERVER PARTITION SCHEME                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Disk 1: 200 GB NVMe (OS)              Disk 2: 500 GB NVMe (Data)          │
│                                                                             │
│  ┌────────────────────────────────┐    ┌────────────────────────────────┐  │
│  │ nvme0n1p1 │ ESP    │  512 MB  │    │ nvme1n1p1 │ LUKS  │  500 GB   │  │
│  │ nvme0n1p2 │ /boot  │  1 GB    │    │           │       │           │  │
│  │ nvme0n1p3 │ LUKS   │  198 GB  │    │  ┌───────┴───────┴─────────┐ │  │
│  │                               │    │  │ LVM: data-vg            │ │  │
│  │  ┌───────────────────────┐   │    │  │ ├── wallix   400 GB    │ │  │
│  │  │ LVM: system-vg        │   │    │  │ └── backup   100 GB    │ │  │
│  │  │ ├── root     20 GB   │   │    │  └─────────────────────────┘ │  │
│  │  │ ├── swap     32 GB   │   │    │                               │  │
│  │  │ ├── tmp       4 GB   │   │    │  Mount points:               │  │
│  │  │ ├── var      50 GB   │   │    │  /var/lib/wallix  (wallix)  │  │
│  │  │ ├── log      20 GB   │   │    │  /backup          (backup)  │  │
│  │  │ └── home      5 GB   │   │    │                               │  │
│  │  └───────────────────────┘   │    └────────────────────────────────┘  │
│  └────────────────────────────────┘                                        │
│                                                                             │
│  Mount /var/log separately to prevent log flooding from filling /var       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Manual Partitioning Commands

If you need to manually set up LUKS (expert mode):

```bash
# 1. Create partitions (using fdisk or gdisk)
gdisk /dev/sda
# Create:
#   Partition 1: 512M, type EF00 (EFI System)
#   Partition 2: 1G, type 8300 (Linux filesystem)
#   Partition 3: remaining, type 8309 (Linux LUKS)

# 2. Format EFI partition
mkfs.vfat -F32 /dev/sda1

# 3. Format boot partition
mkfs.ext2 /dev/sda2

# 4. Create LUKS container
cryptsetup luksFormat --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha512 \
    --pbkdf argon2id \
    --iter-time 5000 \
    /dev/sda3

# 5. Open LUKS container
cryptsetup luksOpen /dev/sda3 sda3_crypt

# 6. Create LVM physical volume
pvcreate /dev/mapper/sda3_crypt

# 7. Create volume group
vgcreate wallix-vg /dev/mapper/sda3_crypt

# 8. Create logical volumes
lvcreate -L 10G -n root wallix-vg
lvcreate -L 16G -n swap wallix-vg
lvcreate -L 2G -n tmp wallix-vg
lvcreate -L 5G -n home wallix-vg
lvcreate -l 100%FREE -n var wallix-vg

# 9. Format logical volumes
mkfs.ext4 /dev/wallix-vg/root
mkfs.ext4 /dev/wallix-vg/tmp
mkfs.ext4 /dev/wallix-vg/home
mkfs.ext4 /dev/wallix-vg/var
mkswap /dev/wallix-vg/swap
```

---

## Advanced LUKS Configuration

### LUKS2 with Argon2id (Default in Debian 12)

Verify your LUKS is using Argon2id:

```bash
sudo cryptsetup luksDump /dev/sda3 | grep -A10 "Key Slot 0"

# Expected output:
# Key Slot 0: ENABLED
#   Iterations: (number)
#   Salt: (hex string)
#   ...
#   PBKDF:      argon2id
#   Time cost:  (number)
#   Memory:     (number)
#   Threads:    (number)
```

### Remote Unlock via SSH (Dropbear)

For headless servers, enable network unlock:

```bash
# Install dropbear-initramfs
sudo apt install dropbear-initramfs

# Configure dropbear
sudo vim /etc/dropbear/initramfs/dropbear.conf
```

```
# /etc/dropbear/initramfs/dropbear.conf
DROPBEAR_OPTIONS="-p 2222 -s -j -k"
```

```bash
# Add your SSH public key for initramfs
sudo vim /etc/dropbear/initramfs/authorized_keys
# Paste your public key (same as ~/.ssh/id_rsa.pub)

# Convert OpenSSH key to dropbear format (if needed)
dropbearconvert openssh dropbear ~/.ssh/id_rsa /etc/dropbear/initramfs/id_rsa.dropbear

# Configure network for initramfs
sudo vim /etc/initramfs-tools/initramfs.conf
```

```
# Add to /etc/initramfs-tools/initramfs.conf
IP=10.0.1.10::10.0.1.1:255.255.255.0:wallix-a1:ens192:off
# Format: IP::GATEWAY:NETMASK:HOSTNAME:INTERFACE:AUTOCONF
```

```bash
# Update initramfs
sudo update-initramfs -u

# After reboot, connect via SSH to unlock:
ssh -p 2222 root@10.0.1.10
# Then run:
cryptroot-unlock
# Enter LUKS passphrase
```

### TPM2 Integration (Future Enhancement)

For automated unlock with TPM2:

```bash
# Install required packages
sudo apt install clevis clevis-luks clevis-tpm2 tpm2-tools

# Bind LUKS to TPM2 PCR values
sudo clevis luks bind -d /dev/sda3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"0,1,2,3,4,5,6,7"}'

# Enter existing LUKS passphrase when prompted

# Update initramfs
sudo update-initramfs -u

# The system will now auto-unlock if PCR values match
# (i.e., no tampering with boot process)
```

---

## Troubleshooting

### Problem: Forgot LUKS Passphrase

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FORGOT PASSPHRASE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ⚠️  WITHOUT the passphrase, data is UNRECOVERABLE.                        │
│                                                                             │
│  Options:                                                                   │
│                                                                             │
│  1. Use backup passphrase (if you added one)                               │
│  2. Use key file (if you created one)                                      │
│  3. Restore LUKS header from backup (if passphrase was changed)            │
│  4. Reinstall and restore from backup                                      │
│                                                                             │
│  Prevention:                                                                │
│  • Always add multiple key slots                                           │
│  • Store passphrases in enterprise password manager                        │
│  • Implement key escrow procedures                                         │
│  • Regular passphrase verification tests                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Problem: LUKS Header Corruption

```bash
# Symptoms:
# - "No key available with this passphrase"
# - "LUKS header is damaged"

# Solution (if you have header backup):
sudo cryptsetup luksHeaderRestore /dev/sda3 \
    --header-backup-file /path/to/luks-header-backup.img

# If no backup exists:
# Data is likely unrecoverable. Restore from system backup.
```

### Problem: Boot Fails After Update

```bash
# Boot from Debian live USB, then:

# 1. Open encrypted volume
sudo cryptsetup luksOpen /dev/sda3 sda3_crypt

# 2. Activate LVM
sudo vgchange -ay

# 3. Mount filesystems
sudo mount /dev/wallix-vg/root /mnt
sudo mount /dev/sda2 /mnt/boot
sudo mount /dev/sda1 /mnt/boot/efi
sudo mount /dev/wallix-vg/var /mnt/var

# 4. Chroot into system
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo chroot /mnt

# 5. Rebuild initramfs
update-initramfs -u -k all

# 6. Reinstall GRUB
grub-install /dev/sda
update-grub

# 7. Exit and reboot
exit
sudo umount -R /mnt
sudo reboot
```

### Problem: Slow Boot (LUKS Performance)

```bash
# Check if AES-NI is being used
grep -o aes /proc/cpuinfo | head -1

# Check dm-crypt performance
sudo cryptsetup benchmark

# Expected output (with AES-NI):
# PBKDF2-sha256      1234567 iterations per second
# ...
# aes-xts   256b     2500.0 MiB/s     2600.0 MiB/s

# If performance is low, verify AES-NI is enabled in BIOS
```

### Problem: Cannot SSH After Reboot

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SSH FAILS AFTER REBOOT                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Most common cause: LUKS unlock prompt waiting at console                   │
│                                                                             │
│  Solution 1: Physical/remote console access                                 │
│  - Use IPMI, iLO, iDRAC, or VMware console                                 │
│  - Enter LUKS passphrase at boot prompt                                    │
│                                                                             │
│  Solution 2: Configure dropbear for SSH unlock                             │
│  - See "Remote Unlock via SSH" section above                               │
│                                                                             │
│  Solution 3: Configure TPM2 auto-unlock                                    │
│  - See "TPM2 Integration" section above                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Security Best Practices

### Passphrase Management

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LUKS PASSPHRASE BEST PRACTICES                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  DO:                                                                        │
│  ═══                                                                        │
│  ✓ Use 20+ character passphrases                                           │
│  ✓ Include uppercase, lowercase, numbers, symbols                          │
│  ✓ Store in enterprise password manager (CyberArk, HashiCorp Vault)        │
│  ✓ Create multiple key slots with different passphrases                    │
│  ✓ Backup LUKS header immediately after creation                           │
│  ✓ Test passphrase recovery procedures annually                            │
│  ✓ Document key escrow procedures                                          │
│  ✓ Use TPM2 binding for automated unlock in secure environments            │
│                                                                             │
│  DON'T:                                                                     │
│  ═════                                                                      │
│  ✗ Use dictionary words or predictable patterns                            │
│  ✗ Store passphrase in plain text files                                    │
│  ✗ Share passphrase via email or chat                                      │
│  ✗ Use same passphrase across multiple servers                             │
│  ✗ Leave only one key slot populated                                       │
│  ✗ Skip LUKS header backup                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Escrow Procedure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         KEY ESCROW PROCEDURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  For enterprise environments, implement key escrow:                         │
│                                                                             │
│  1. PRIMARY PASSPHRASE                                                      │
│     └── Known by: System Administrators                                    │
│     └── Stored in: Enterprise Password Manager                             │
│                                                                             │
│  2. BACKUP PASSPHRASE                                                       │
│     └── Known by: Security Team Lead                                       │
│     └── Stored in: Sealed envelope in physical safe                        │
│                                                                             │
│  3. EMERGENCY PASSPHRASE                                                    │
│     └── Known by: No individual (split knowledge)                          │
│     └── Stored as: 3 shares using Shamir's Secret Sharing                  │
│         - Share 1: CEO safe                                                │
│         - Share 2: CTO safe                                                │
│         - Share 3: External counsel                                        │
│     └── Requires: 2 of 3 shares to reconstruct                             │
│                                                                             │
│  4. LUKS HEADER BACKUP                                                      │
│     └── Stored in: Encrypted off-site backup                               │
│     └── Encrypted with: Separate passphrase (also escrowed)                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Compliance Checklist

```bash
# Run these checks to verify LUKS compliance:

# 1. Verify LUKS2 is in use
echo "=== LUKS Version ==="
sudo cryptsetup luksDump /dev/sda3 | grep "Version:"
# Expected: Version: 2

# 2. Verify Argon2id PBKDF
echo "=== PBKDF Algorithm ==="
sudo cryptsetup luksDump /dev/sda3 | grep "PBKDF:"
# Expected: PBKDF: argon2id

# 3. Verify cipher strength
echo "=== Cipher Configuration ==="
sudo cryptsetup luksDump /dev/sda3 | grep "Cipher:"
# Expected: Cipher: aes-xts-plain64
sudo cryptsetup luksDump /dev/sda3 | grep "Cipher key:"
# Expected: Cipher key: 512 bits (for AES-256)

# 4. Verify multiple key slots
echo "=== Key Slots ==="
sudo cryptsetup luksDump /dev/sda3 | grep "Key Slot"
# Expected: At least 2 ENABLED slots

# 5. Verify header backup exists
echo "=== Header Backup ==="
ls -la /root/luks-header-backup-*.img 2>/dev/null || echo "WARNING: No header backup found!"
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    LUKS QUICK REFERENCE CARD                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STATUS & INFO                                                              │
│  ═════════════                                                              │
│  cryptsetup status <name>         # Show active mapping status              │
│  cryptsetup luksDump <device>     # Show LUKS header info                   │
│  lsblk -f                         # Show filesystem tree                    │
│  dmsetup ls                       # List device-mapper devices              │
│                                                                             │
│  KEY MANAGEMENT                                                             │
│  ══════════════                                                             │
│  cryptsetup luksAddKey <dev>              # Add new passphrase             │
│  cryptsetup luksRemoveKey <dev>           # Remove passphrase              │
│  cryptsetup luksChangeKey <dev>           # Change passphrase              │
│  cryptsetup luksKillSlot <dev> <slot>     # Remove specific slot           │
│                                                                             │
│  BACKUP & RESTORE                                                           │
│  ════════════════                                                           │
│  cryptsetup luksHeaderBackup <dev> --header-backup-file <file>             │
│  cryptsetup luksHeaderRestore <dev> --header-backup-file <file>            │
│                                                                             │
│  OPEN & CLOSE                                                               │
│  ════════════                                                               │
│  cryptsetup luksOpen <dev> <name>         # Open/decrypt volume            │
│  cryptsetup luksClose <name>              # Close/lock volume              │
│                                                                             │
│  BENCHMARK                                                                  │
│  ═════════                                                                  │
│  cryptsetup benchmark                     # Test encryption speed           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Next Steps

After completing Debian installation with LUKS:

1. **Proceed to WALLIX Installation**
   - Continue with [01-prerequisites.md](./01-prerequisites.md)
   - Then follow site-specific guides (02, 03, or 04)

2. **Verify System Readiness**
   ```bash
   # Run pre-installation checks
   sudo apt update
   sudo apt install -y curl

   # Verify network
   ping -c 3 google.com

   # Verify disk space
   df -h

   # Verify memory
   free -h

   # Verify LUKS is active
   lsblk -f | grep crypto_LUKS
   ```

3. **Document Your Installation**
   - Record all passphrases securely
   - Backup LUKS header to separate location
   - Document server configuration
   - Update network documentation

---

## Version Information

| Item | Value |
|------|-------|
| Document Version | 1.0 |
| Debian Version | 12 (Bookworm) |
| LUKS Version | LUKS2 |
| Last Updated | January 2026 |

---

<p align="center">
  <a href="./README.md">← Back to Installation Overview</a> •
  <a href="./01-prerequisites.md">Next: Prerequisites →</a>
</p>
