# 02 - Active Directory Setup

## Domain Controller Configuration for PAM4OT Lab

This guide covers setting up Active Directory for PAM4OT authentication and testing.

---

## Domain Configuration

| Setting | Value |
|---------|-------|
| Domain Name | LAB.LOCAL |
| NetBIOS Name | LAB |
| Forest Functional Level | Windows Server 2016 |
| Domain Functional Level | Windows Server 2016 |
| DC Hostname | dc-lab.lab.local |
| DC IP Address | 10.10.1.10 |

---

## Step 1: Install AD DS Role

### Using PowerShell

```powershell
# Set static IP first
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.1.10 -PrefixLength 24 -DefaultGateway 10.10.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1

# Rename computer
Rename-Computer -NewName "dc-lab" -Restart

# After restart, install AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest `
    -DomainName "lab.local" `
    -DomainNetbiosName "LAB" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "SafeMode123!" -AsPlainText -Force) `
    -Force:$true

# Server will restart automatically
```

---

## Step 2: Create Organizational Units

```powershell
# Create OU structure for PAM4OT lab
$OUs = @(
    "OU=PAM4OT,DC=lab,DC=local",
    "OU=Users,OU=PAM4OT,DC=lab,DC=local",
    "OU=Groups,OU=PAM4OT,DC=lab,DC=local",
    "OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local",
    "OU=Servers,OU=PAM4OT,DC=lab,DC=local"
)

foreach ($OU in $OUs) {
    try {
        New-ADOrganizationalUnit -Path ($OU -replace "^OU=[^,]+,", "") -Name ($OU -split ",")[0].Replace("OU=","")
    } catch {
        Write-Host "OU may already exist: $OU"
    }
}

# Verify
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
```

---

## Step 3: Create PAM4OT Service Account

```powershell
# Create service account for PAM4OT LDAP binding
$ServiceAccountPassword = ConvertTo-SecureString "WallixSvc123!" -AsPlainText -Force

New-ADUser `
    -Name "wallix-svc" `
    -SamAccountName "wallix-svc" `
    -UserPrincipalName "wallix-svc@lab.local" `
    -Path "OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local" `
    -AccountPassword $ServiceAccountPassword `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true `
    -Description "PAM4OT LDAP Service Account"

# Grant read access to user objects (for authentication)
# The service account needs to read user attributes
$acl = Get-Acl "AD:DC=lab,DC=local"
$user = Get-ADUser "wallix-svc"
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $user.SID,
    "ReadProperty",
    "Allow",
    [GUID]::Empty,
    "Descendents",
    [GUID]"bf967aba-0de6-11d0-a285-00aa003049e2"  # User object GUID
)
$acl.AddAccessRule($ace)
Set-Acl "AD:DC=lab,DC=local" $acl
```

---

## Step 4: Create Security Groups

```powershell
# Create groups for PAM4OT authorization

# Admin groups
New-ADGroup -Name "PAM4OT-Admins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "PAM4OT Full Administrators"

New-ADGroup -Name "PAM4OT-Operators" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "PAM4OT Operators (read-only)"

New-ADGroup -Name "PAM4OT-Auditors" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "PAM4OT Audit Access"

# Target access groups
New-ADGroup -Name "Linux-Admins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "Linux server root access"

New-ADGroup -Name "Windows-Admins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "Windows server admin access"

New-ADGroup -Name "Network-Admins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "Network device access"

New-ADGroup -Name "OT-Engineers" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "OT/Industrial system access"

New-ADGroup -Name "External-Vendors" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,OU=PAM4OT,DC=lab,DC=local" `
    -Description "Third-party vendor access"
```

---

## Step 5: Create Test Users

```powershell
# Function to create test users
function New-LabUser {
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$Password,
        [string[]]$Groups
    )

    $Username = ($FirstName.Substring(0,1) + $LastName).ToLower()
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

    New-ADUser `
        -Name "$FirstName $LastName" `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $Username `
        -UserPrincipalName "$Username@lab.local" `
        -Path "OU=Users,OU=PAM4OT,DC=lab,DC=local" `
        -AccountPassword $SecurePassword `
        -PasswordNeverExpires $true `
        -Enabled $true

    foreach ($Group in $Groups) {
        Add-ADGroupMember -Identity $Group -Members $Username
    }

    Write-Host "Created user: $Username"
}

# Create test users
New-LabUser -FirstName "John" -LastName "Admin" -Password "JohnAdmin123!" `
    -Groups @("PAM4OT-Admins", "Linux-Admins", "Windows-Admins")

New-LabUser -FirstName "Sarah" -LastName "Operator" -Password "SarahOp123!" `
    -Groups @("PAM4OT-Operators", "Linux-Admins")

New-LabUser -FirstName "Mike" -LastName "Auditor" -Password "MikeAudit123!" `
    -Groups @("PAM4OT-Auditors")

New-LabUser -FirstName "Lisa" -LastName "Network" -Password "LisaNet123!" `
    -Groups @("Network-Admins")

New-LabUser -FirstName "Tom" -LastName "OTEngineer" -Password "TomOT123!" `
    -Groups @("OT-Engineers")

New-LabUser -FirstName "Vendor" -LastName "Support" -Password "Vendor123!" `
    -Groups @("External-Vendors")
```

---

## Step 6: Configure LDAPS (Secure LDAP)

### Option A: Self-Signed Certificate (Lab Only)

```powershell
# Install Certificate Services
Install-WindowsFeature -Name AD-Certificate -IncludeManagementTools

# Configure as Enterprise Root CA
Install-AdcsCertificationAuthority `
    -CAType EnterpriseRootCA `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -KeyLength 2048 `
    -HashAlgorithmName SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits 5 `
    -Force

# Restart to apply certificate
Restart-Computer

# After restart, verify LDAPS
# The DC will automatically get a certificate from the CA
```

### Verify LDAPS

```powershell
# Test LDAPS connectivity
$LdapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("dc-lab.lab.local:636")
$LdapConnection.SessionOptions.SecureSocketLayer = $true
$LdapConnection.SessionOptions.VerifyServerCertificate = { $true }  # Lab only - skip verification
$LdapConnection.Bind()
Write-Host "LDAPS connection successful!"
```

### Export CA Certificate (for PAM4OT)

```powershell
# Export the CA certificate for import into PAM4OT
$CACert = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { $_.Subject -like "*lab-DC-LAB-CA*" }
Export-Certificate -Cert $CACert -FilePath C:\lab-ca.cer -Type CERT

# Convert to PEM format (run in PowerShell)
certutil -encode C:\lab-ca.cer C:\lab-ca.pem

# Copy this file to PAM4OT nodes
```

---

## Step 7: Create DNS Records

```powershell
# Add DNS records for lab infrastructure
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "pam4ot-node1" -IPv4Address "10.10.1.11"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "pam4ot-node2" -IPv4Address "10.10.1.12"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "pam4ot" -IPv4Address "10.10.1.100"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "siem-lab" -IPv4Address "10.10.1.50"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "monitor-lab" -IPv4Address "10.10.1.60"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "linux-test" -IPv4Address "10.10.2.10"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "windows-test" -IPv4Address "10.10.2.20"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "network-test" -IPv4Address "10.10.2.30"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "plc-sim" -IPv4Address "10.10.3.10"

# Verify
Get-DnsServerResourceRecord -ZoneName "lab.local" | Where-Object { $_.RecordType -eq "A" }
```

---

## AD Configuration Summary

### Users Created

| Username | Full Name | Groups | Password |
|----------|-----------|--------|----------|
| jadmin | John Admin | PAM4OT-Admins, Linux-Admins, Windows-Admins | JohnAdmin123! |
| soperator | Sarah Operator | PAM4OT-Operators, Linux-Admins | SarahOp123! |
| mauditor | Mike Auditor | PAM4OT-Auditors | MikeAudit123! |
| lnetwork | Lisa Network | Network-Admins | LisaNet123! |
| totengineer | Tom OTEngineer | OT-Engineers | TomOT123! |
| vsupport | Vendor Support | External-Vendors | Vendor123! |

### Groups Created

| Group | Purpose |
|-------|---------|
| PAM4OT-Admins | Full PAM4OT administration |
| PAM4OT-Operators | Read-only PAM4OT access |
| PAM4OT-Auditors | Session review only |
| Linux-Admins | SSH access to Linux servers |
| Windows-Admins | RDP access to Windows servers |
| Network-Admins | Network device access |
| OT-Engineers | OT/PLC access |
| External-Vendors | Vendor remote access |

### Service Accounts

| Account | Purpose | Password |
|---------|---------|----------|
| wallix-svc | LDAP bind for PAM4OT | WallixSvc123! |

---

## Verification Checklist

```powershell
# Run these commands to verify AD setup

# Check domain
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode

# Check users
Get-ADUser -Filter * -SearchBase "OU=Users,OU=PAM4OT,DC=lab,DC=local" | Select-Object Name, SamAccountName, Enabled

# Check groups
Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=PAM4OT,DC=lab,DC=local" | Select-Object Name

# Check group membership
Get-ADGroupMember -Identity "PAM4OT-Admins" | Select-Object Name

# Test LDAP bind with service account
$cred = Get-Credential -UserName "LAB\wallix-svc" -Message "Enter service account password"
Get-ADUser -Identity "jadmin" -Credential $cred
```

---

## Troubleshooting

### LDAPS Not Working

```powershell
# Check if certificate is installed
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.EnhancedKeyUsageList -like "*Server Authentication*" }

# Check LDAPS port is listening
Test-NetConnection -ComputerName localhost -Port 636

# Check certificate binding
netsh http show sslcert
```

### User Cannot Authenticate

```powershell
# Check user account status
Get-ADUser -Identity "jadmin" -Properties LockedOut, Enabled, PasswordExpired

# Unlock if locked
Unlock-ADAccount -Identity "jadmin"

# Reset password if needed
Set-ADAccountPassword -Identity "jadmin" -NewPassword (ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force)
```

---

<p align="center">
  <a href="./01-infrastructure-setup.md">← Previous</a> •
  <a href="./03-pam4ot-installation.md">Next: PAM4OT Installation →</a>
</p>
