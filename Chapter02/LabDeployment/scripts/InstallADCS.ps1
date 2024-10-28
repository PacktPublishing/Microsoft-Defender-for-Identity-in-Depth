# Define variables
$CAName = "ContosoRootCA"
$CommonName = "Contoso Root CA"
$ValidityPeriodYears = 5
$CSP = "RSA#Microsoft Software Key Storage Provider"
$KeyLength = 2048
$CRLPath = "C:\CertEnroll\"
$DatabasePath = "C:\Windows\System32\CertLog\"
$LogPath = "C:\Windows\System32\CertLog\"

# Install AD CS role
Install-WindowsFeature ADCS-Cert-Authority, ADCS-Web-Enrollment -IncludeManagementTools

# Install AD CS
Install-AdcsCertificationAuthority `
    -CAType EnterpriseRootCA `
    -CACommonName $CommonName `
    -CADistinguishedNameSuffix "DC=contoso,DC=local" `
    -CryptoProviderName $CSP `
    -KeyLength $KeyLength `
    -HashAlgorithmName "SHA256" `
    -ValidityPeriod Years `
    -ValidityPeriodUnits $ValidityPeriodYears `
    -DatabaseDirectory $DatabasePath `
    -LogDirectory $LogPath `
    -Confirm:$false

Install-AdcsWebEnrollment -Force

# Enable Auditing for AD CS - required for MDI
certutil -setreg CA\AuditFilter 127 

# Restart the AD CS service to apply the changes
Restart-Service CertSvc

Write-Host "AD CS Installation and Configuration completed successfully."
