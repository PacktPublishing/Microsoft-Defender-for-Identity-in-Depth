# Define variables
$wmiDomain      = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
$shortDomain    = $wmiDomain.DomainName
$DomainName     = $wmidomain.DnsForestName
$ComputerName   = $wmiDomain.PSComputerName
$CARootName     = "$($shortDomain.ToLower())-$($ComputerName.ToUpper())-CA"
$CAServerFQDN   = "$ComputerName.$DomainName"
$CertPath       = "C:\src\"

# Set CA configuration parameters
$CAConfigArgs = @{
    CAType = "EnterpriseRootCA"
    CACommonName = $CARootName
    ValidityPeriodUnits = 5
    ValidityPeriod = "Years"
    CryptoProvider = "RSA#Microsoft Software Key Storage Provider"
    HashAlgorithmName = "SHA256"
    KeyLength = "2048"
    DatabaseDirectory = "C:\Windows\System32\CertLog\"
    LogDirectory = "C:\Windows\System32\CertLog\"
}

# Create src folder
New-Item -Path $CertPath -ItemType Directory -Force

# Install AD CS role
Install-WindowsFeature ADCS-Cert-Authority, ADCS-Web-Enrollment -IncludeManagementTools

# Install AD CS
Install-AdcsCertificationAuthority @CAConfigArgs -Confirm:$false -Force

# Enable Auditing for AD CS - required for MDI
certutil -setreg CA\AuditFilter 127 

# Restart the AD CS service to apply the changes
Restart-Service CertSvc

# Install ADCS Web Enrollment
Install-AdcsWebEnrollment -Confirm:$false -Force

# Export Root Certificate
function Export-RootCert {
    Write-Verbose "Exporting Root Certificate"
    $arr = $DomainName.Split('.')
    $rootDN = "CN=$CARootName, " + (($arr | ForEach-Object { "DC=$_"}) -join ', ')

    $rootCert = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { $_.Subject -eq $rootDN }
    if ($null -eq $rootCert) {
        Write-Output "ERROR: Root certificate with subject '$rootDN' not found. Export canceled."
    } else {
        $fileName = $CertPath + $rawCert.DnsNameList.Punycode + ".cer" 
        Export-Certificate -FilePath $fileName -Cert $rootCert
        Write-Output "Root certificate exported to $CertPath."
    }
}

# Execution Steps
Export-RootCert

Write-Host "AD CS Installation and Configuration completed successfully."