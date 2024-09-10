param (
	[Parameter(Mandatory)]
	[string]$gMSA_ADFS,

    [Parameter(Mandatory)]
    [string]$IP_ADFS
)

# Install modules
Install-WindowsFeature ADFS-Federation -IncludeManagementTools
Install-WindowsFeature -Name RSAT-AD-Tools
Install-WindowsFeature -Name GPMC

# Configure ADFS Farm
Import-Module ADFS
$wmiDomain = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
$DomainName = $wmiDomain.DomainName
$DnsForestName = $wmiDomain.DnsForestName
$DomainControllerName = $wmiDomain.DomainControllerName -replace '\\',''

# Create a self-signed certificate for AD FS
$cert = New-SelfSignedCertificate -DnsName "adfs.$($DnsForestName)" -CertStoreLocation cert:\LocalMachine\My
$pwd = ConvertTo-SecureString -String "yourPassword" -Force -AsPlainText
Export-PfxCertificate -cert "cert:\LocalMachine\My\$($cert.Thumbprint)" -FilePath "C:\Temp\adfsCert.pfx" -Password $pwd
Import-PfxCertificate -FilePath "C:\Temp\adfsCert.pfx" -CertStoreLocation cert:\LocalMachine\My -Password $pwd

# Install AD FS
Install-ADServiceAccount -Identity $gMSA_ADFS
Install-AdfsFarm `
	-CertificateThumbprint $cert.thumbprint `
	-FederationServiceDisplayName "MDI AD FS Lab" `
    -FederationServiceName "adfs.$($DnsForestName)" `
	-GroupServiceAccountIdentifier "$($domainName)\$($gMSA_ADFS)$" `
	-OverwriteConfiguration

# Set the IdP initiated sign-on page
Set-AdfsProperties -EnableIdPInitiatedSignonPage $true 

# DNS
Install-WindowsFeature -Name DNS -IncludeManagementTools
Import-Module DNSServer
Add-DnsServerResourceRecordA -Name "adfs" -ZoneName $DnsForestName -IPv4Address $IP_ADFS -ComputerName $DomainControllerName

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
