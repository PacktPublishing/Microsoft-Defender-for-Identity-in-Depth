##############################################################
# This script will install ADDS window feature and promote windows server
# as a domain controller and restarts to finish AD setup
##############################################################
# Configure the Domain Controller
param (
    [string]$domainName,
    [string]$domainAdminUsername,
    [string]$domainAdminPassword,
    [string]$templateBaseUrl
)

[System.Environment]::SetEnvironmentVariable('domainName', $domainName,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('domainAdminUsername', $domainAdminUsername,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('domainAdminPassword', $domainAdminPassword,[System.EnvironmentVariableTarget]::Machine)

# Convert plain text password to secure string
$secureDomainAdminPassword = $domainAdminPassword | ConvertTo-SecureString -AsPlainText -Force

# Enable ADDS windows feature to setup domain forest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$netbiosname = $domainName.Split('.')[0].ToUpper()

# Create Active Directory Forest
Install-ADDSForest `
    -DomainName "$domainName" `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "7" `
    -DomainNetbiosName $netbiosname `
    -ForestMode "7" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$True `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true `
    -SafeModeAdministratorPassword $secureDomainAdminPassword


# Reboot computer
Restart-Computer