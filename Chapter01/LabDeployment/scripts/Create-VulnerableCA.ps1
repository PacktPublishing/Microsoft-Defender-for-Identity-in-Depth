# Define variables
$domain = 'CONTOSO'
$domainUsers = $domain + '\Domain Users'
$outputFolder = 'C:\Temp\'
$githubRepo = 'https://raw.githubusercontent.com/PacktPublishing/Microsoft-Defender-for-Identity-in-Depth/main/Chapter01/LabDeployment/ESCs/'
$PSPKIAuditrepoUrl = "https://github.com/GhostPack/PSPKIAudit/archive/refs/heads/master.zip"
$PSPKIAuditdestinationPath = "C:\Temp\PSPKIAudit.zip"
$PSPKIAuditextractPath = "C:\Temp\"
$templates = @(
    'ESC1.json',
    'ESC2.json',
    'ESC3-1.json',
    'ESC3-2.json',
    'ESC4.json'
)

# Install and import the required modules
$requiredModules = @('ADCSTemplate', 'PSPKI')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ErrorAction SilentlyContinue)) {
        Install-Module -Name $module -Force -AllowClobber
    }
    Import-Module -Name $module
}

# Download all ESC templates from the public GitHub repository and save them to the output folder
foreach ($template in $templates) {
    $url = $githubRepo + $template
    $outputFile = $outputFolder + $template
    Invoke-WebRequest -Uri $url -OutFile $outputFile
}

# Create the vulnerable certificate templates with New-ADCSTemplate (from the ADCSTemplate module)
Set-Location -Path $outputFolder
foreach ($template in $templates) {
    New-ADCSTemplate -DisplayName $template.Replace('.json', '') -JSON (Get-Content $template -Raw) -Publish -Identity $domainUsers -AutoEnroll
}

# Configure CA security settings (with PSPKI module)
$domainUsers = New-Object System.Security.Principal.NTAccount($domainUsers)
$ca = Get-CA

## Allow Domain Users to 'Issue and Manage Certificates'
$issueManageCertsACE = New-Object SysadminsLV.PKI.Security.AccessControl.CertSrvAccessRule (
    $domainUsers,
    "ManageCertificates",
    "Allow"
)

## Allow Domain Users to 'Manage CA'
$manageCAACE = New-Object SysadminsLV.PKI.Security.AccessControl.CertSrvAccessRule (
    $domainUsers,
    "ManageCA",
    "Allow"
)

# Set the permissions
$ca | Get-CASecurityDescriptor | Add-CertificationAuthorityAcl -AccessRule $issueManageCertsACE | Set-CertificationAuthorityAcl -RestartCA
$ca | Get-CASecurityDescriptor | Add-CertificationAuthorityAcl -AccessRule $manageCAACE | Set-CertificationAuthorityAcl -RestartCA

# Set ESC6 vulnerability
$ca = Get-CA
$caServerName = $ca.ComputerName
$caDisplayName = $ca.DisplayName
certutil -config "$($caServerName)\$($caDisplayName)" -setreg policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2
Get-Service -ComputerName $caServerName certsvc | Restart-Service -Force

# Download and import the PSPKIAudit module
Invoke-WebRequest -Uri $PSPKIAuditrepoUrl -OutFile $PSPKIAuditdestinationPath
Expand-Archive -Path $PSPKIAuditdestinationPath -DestinationPath $PSPKIAuditextractPath
cd "$PSPKIAuditextractPath\PSPKIAudit-main"

## Unblock the files in the PSPKIAudit module
Get-ChildItem -Recurse | Unblock-File

## Import the PSPKIAudit module
Import-Module .\PSPKIAudit.psd1