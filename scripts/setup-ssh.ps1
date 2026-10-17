<#
.SYNOPSIS
    Configures SSH client on Windows for the AWS VPC Peering Lab.
.DESCRIPTION
    Fixes Windows NTFS permissions on ewb-lab.pem and populates ~/.ssh/config.
.PARAMETER BastionPublicIP
    Public IPv4 address of ewb-bastion from AWS EC2 Console.
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Enter your Bastion public IPv4")]
    [string]$BastionPublicIP
)

$sshDir = Join-Path $HOME ".ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "[+] Created directory: $sshDir" -ForegroundColor Green
}

$keyPath = Join-Path $sshDir "ewb-lab.pem"
if (Test-Path $keyPath) {
    Write-Host "[+] Setting strict permissions on $keyPath..." -ForegroundColor Cyan
    icacls $keyPath /inheritance:r | Out-Null
    icacls $keyPath /grant:r "$($env:USERNAME):(R)" | Out-Null
    Write-Host "[+] Locked down permissions: Read-only for current user." -ForegroundColor Green
} else {
    Write-Warning "File 'ewb-lab.pem' not found in $sshDir. Please ensure it is placed there."
}

$configFile = Join-Path $sshDir "config"
$configText = @"
# ==============================================================================
# AWS VPC Peering - OpenSSH Configuration
# Project: EWB Cloud Labs - AWS Architect Associate
# ==============================================================================

Host ewb-bastion
    HostName $BastionPublicIP
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes

Host ewb-app-a
    HostName 10.10.2.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion

Host ewb-app-b
    HostName 10.20.1.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion
"@

Set-Content -Path $configFile -Value $configText -Encoding UTF8
Write-Host "[+] Configured ~/.ssh/config with Bastion IP: $BastionPublicIP" -ForegroundColor Green
Write-Host "`nTest SSH connectivity in terminal:" -ForegroundColor Yellow
Write-Host "  ssh ewb-bastion" -ForegroundColor Cyan
Write-Host "  ssh ewb-app-a" -ForegroundColor Cyan
Write-Host "  ssh ewb-app-b`n" -ForegroundColor Cyan
