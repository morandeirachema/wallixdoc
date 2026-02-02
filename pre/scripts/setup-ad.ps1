# setup-ad.ps1
# Active Directory Setup Script for WALLIX Pre-Production Lab
# Run as Administrator on Windows Server 2022

#Requires -RunAsAdministrator

param(
    [string]$DomainName = "lab.local",
    [string]$NetBIOSName = "LAB",
    [string]$SafeModePassword = "SafeMode123!",
    [string]$ServiceAccountPassword = "WallixSvc123!"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WALLIX Lab - AD Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to write status
function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# Check if AD DS is already installed
$addsFeature = Get-WindowsFeature AD-Domain-Services
if ($addsFeature.Installed) {
    Write-Status "AD DS feature already installed" "INFO"
} else {
    Write-Status "Installing AD DS feature..." "INFO"
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Write-Status "AD DS feature installed" "SUCCESS"
}

# Check if domain already exists
try {
    $domain = Get-ADDomain -ErrorAction Stop
    Write-Status "Domain $($domain.DNSRoot) already exists" "INFO"
    $domainExists = $true
} catch {
    $domainExists = $false
}

# Install AD DS Forest if domain doesn't exist
if (-not $domainExists) {
    Write-Status "Creating new AD DS Forest: $DomainName" "INFO"

    $securePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force

    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $NetBIOSName `
        -SafeModeAdministratorPassword $securePassword `
        -InstallDns:$true `
        -Force:$true `
        -NoRebootOnCompletion:$false

    Write-Status "AD DS Forest created. Server will reboot." "SUCCESS"
    Write-Host ""
    Write-Host "After reboot, run this script again to create OUs, groups, and users." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Status "Configuring AD objects for WALLIX..." "INFO"
Write-Host ""

# Create Organizational Units
Write-Status "Creating Organizational Units..." "INFO"

$ous = @(
    "OU=WALLIX,DC=lab,DC=local",
    "OU=Users,OU=WALLIX,DC=lab,DC=local",
    "OU=Groups,OU=WALLIX,DC=lab,DC=local",
    "OU=Service Accounts,OU=WALLIX,DC=lab,DC=local"
)

foreach ($ou in $ous) {
    $ouName = ($ou -split ",")[0] -replace "OU=", ""
    try {
        Get-ADOrganizationalUnit -Identity $ou -ErrorAction Stop | Out-Null
        Write-Status "  OU exists: $ouName" "INFO"
    } catch {
        $parentOU = ($ou -split ",", 2)[1]
        New-ADOrganizationalUnit -Name $ouName -Path $parentOU -ProtectedFromAccidentalDeletion $false
        Write-Status "  Created OU: $ouName" "SUCCESS"
    }
}

# Create Security Groups
Write-Status "Creating Security Groups..." "INFO"

$groups = @(
    @{Name="WALLIX-Admins"; Description="WALLIX Administrators"},
    @{Name="WALLIX-Operators"; Description="WALLIX Operators"},
    @{Name="WALLIX-Auditors"; Description="WALLIX Auditors"},
    @{Name="Linux-Admins"; Description="Linux Server Administrators"},
    @{Name="Windows-Admins"; Description="Windows Server Administrators"},
    @{Name="Network-Admins"; Description="Network Device Administrators"},
    @{Name="OT-Engineers"; Description="OT/ICS Engineers"}
)

foreach ($group in $groups) {
    try {
        Get-ADGroup -Identity $group.Name -ErrorAction Stop | Out-Null
        Write-Status "  Group exists: $($group.Name)" "INFO"
    } catch {
        New-ADGroup -Name $group.Name `
            -GroupCategory Security `
            -GroupScope Global `
            -Path "OU=Groups,OU=WALLIX,DC=lab,DC=local" `
            -Description $group.Description
        Write-Status "  Created group: $($group.Name)" "SUCCESS"
    }
}

# Create Service Account
Write-Status "Creating Service Account..." "INFO"

$svcAccountName = "wallix-svc"
try {
    Get-ADUser -Identity $svcAccountName -ErrorAction Stop | Out-Null
    Write-Status "  Service account exists: $svcAccountName" "INFO"
} catch {
    $securePassword = ConvertTo-SecureString $ServiceAccountPassword -AsPlainText -Force
    New-ADUser -Name "WALLIX Service Account" `
        -SamAccountName $svcAccountName `
        -UserPrincipalName "$svcAccountName@$DomainName" `
        -Path "OU=Service Accounts,OU=WALLIX,DC=lab,DC=local" `
        -AccountPassword $securePassword `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -CannotChangePassword $true `
        -Description "Service account for WALLIX WALLIX LDAP bind"
    Write-Status "  Created service account: $svcAccountName" "SUCCESS"
}

# Create Test Users
Write-Status "Creating Test Users..." "INFO"

$users = @(
    @{
        Name="John Admin"
        Sam="jadmin"
        Password="JohnAdmin123!"
        Groups=@("WALLIX-Admins","Linux-Admins","Windows-Admins")
        Description="WALLIX Lab Administrator"
    },
    @{
        Name="Sarah Operator"
        Sam="soperator"
        Password="SarahOp123!"
        Groups=@("WALLIX-Operators","Linux-Admins")
        Description="WALLIX Lab Operator"
    },
    @{
        Name="Mike Auditor"
        Sam="mauditor"
        Password="MikeAud123!"
        Groups=@("WALLIX-Auditors")
        Description="WALLIX Lab Auditor"
    },
    @{
        Name="Lisa Network"
        Sam="lnetwork"
        Password="LisaNet123!"
        Groups=@("Network-Admins")
        Description="Network Administrator"
    },
    @{
        Name="Tom OT Engineer"
        Sam="totengineer"
        Password="TomOT123!"
        Groups=@("OT-Engineers")
        Description="OT/ICS Engineer"
    }
)

foreach ($user in $users) {
    try {
        Get-ADUser -Identity $user.Sam -ErrorAction Stop | Out-Null
        Write-Status "  User exists: $($user.Sam)" "INFO"
    } catch {
        $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
        New-ADUser -Name $user.Name `
            -SamAccountName $user.Sam `
            -UserPrincipalName "$($user.Sam)@$DomainName" `
            -Path "OU=Users,OU=WALLIX,DC=lab,DC=local" `
            -AccountPassword $securePassword `
            -Enabled $true `
            -Description $user.Description
        Write-Status "  Created user: $($user.Sam)" "SUCCESS"
    }

    # Add to groups
    foreach ($groupName in $user.Groups) {
        try {
            Add-ADGroupMember -Identity $groupName -Members $user.Sam -ErrorAction SilentlyContinue
        } catch {
            # Already a member, ignore
        }
    }
}

# Configure LDAPS
Write-Status "Configuring LDAPS (Certificate Services)..." "INFO"

$caFeature = Get-WindowsFeature ADCS-Cert-Authority
if ($caFeature.Installed) {
    Write-Status "  Certificate Services already installed" "INFO"
} else {
    Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
    Write-Status "  Certificate Services feature installed" "SUCCESS"

    # Configure CA
    try {
        Install-AdcsCertificationAuthority `
            -CAType EnterpriseRootCA `
            -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
            -KeyLength 2048 `
            -HashAlgorithmName SHA256 `
            -ValidityPeriod Years `
            -ValidityPeriodUnits 5 `
            -Force
        Write-Status "  Enterprise Root CA configured" "SUCCESS"
    } catch {
        Write-Status "  CA may already be configured: $($_.Exception.Message)" "WARNING"
    }
}

# Export CA Certificate
Write-Status "Exporting CA Certificate..." "INFO"
$caName = (Get-CACertificate).Subject
$certPath = "C:\lab-ca.cer"
$pemPath = "C:\lab-ca.pem"

try {
    # Export as DER
    certutil -ca.cert $certPath | Out-Null

    # Convert to PEM
    certutil -encode $certPath $pemPath | Out-Null
    Write-Status "  CA certificate exported to: $pemPath" "SUCCESS"
} catch {
    Write-Status "  Could not export CA cert: $($_.Exception.Message)" "WARNING"
}

# Configure DNS records
Write-Status "Creating DNS records..." "INFO"

$dnsRecords = @(
    @{Name="wallix-node1"; IP="10.10.1.11"},
    @{Name="wallix-node2"; IP="10.10.1.12"},
    @{Name="wallix"; IP="10.10.1.100"},
    @{Name="siem-lab"; IP="10.10.1.50"},
    @{Name="monitoring-lab"; IP="10.10.1.60"},
    @{Name="linux-test"; IP="10.10.2.10"},
    @{Name="windows-test"; IP="10.10.2.20"},
    @{Name="network-test"; IP="10.10.2.30"},
    @{Name="plc-sim"; IP="10.10.3.10"}
)

foreach ($record in $dnsRecords) {
    try {
        $existing = Get-DnsServerResourceRecord -ZoneName $DomainName -Name $record.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Status "  DNS record exists: $($record.Name)" "INFO"
        } else {
            Add-DnsServerResourceRecordA -ZoneName $DomainName -Name $record.Name -IPv4Address $record.IP
            Write-Status "  Created DNS record: $($record.Name) -> $($record.IP)" "SUCCESS"
        }
    } catch {
        Write-Status "  Could not create DNS record $($record.Name): $($_.Exception.Message)" "WARNING"
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domain: $DomainName" -ForegroundColor White
Write-Host "Service Account: $svcAccountName (Password: $ServiceAccountPassword)" -ForegroundColor White
Write-Host ""
Write-Host "Test Users:" -ForegroundColor Yellow
foreach ($user in $users) {
    Write-Host "  - $($user.Sam) / $($user.Password) ($($user.Groups -join ', '))" -ForegroundColor White
}
Write-Host ""
Write-Host "CA Certificate: $pemPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Copy the CA certificate to WALLIX nodes:" -ForegroundColor Yellow
Write-Host "  scp $pemPath root@wallix-node1:/tmp/lab-ca.pem" -ForegroundColor Gray
Write-Host "  scp $pemPath root@wallix-node2:/tmp/lab-ca.pem" -ForegroundColor Gray
Write-Host ""

# Verify LDAPS
Write-Status "Verifying LDAPS is working..." "INFO"
$ldapsTest = Test-NetConnection -ComputerName localhost -Port 636
if ($ldapsTest.TcpTestSucceeded) {
    Write-Status "LDAPS (port 636) is responding" "SUCCESS"
} else {
    Write-Status "LDAPS (port 636) not responding - may need reboot" "WARNING"
}

Write-Host ""
Write-Host "AD setup complete. Next steps:" -ForegroundColor Green
Write-Host "  1. Copy CA certificate to WALLIX nodes" -ForegroundColor White
Write-Host "  2. Configure LDAP in WALLIX" -ForegroundColor White
Write-Host "  3. Test authentication with jadmin user" -ForegroundColor White
Write-Host ""
