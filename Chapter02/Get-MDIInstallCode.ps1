<#
.SYNOPSIS
    Retrieves the installation code and product version from the MDI installation log file.

.DESCRIPTION
    This script retrieves the installation code and product version from the MDI installation log file.
    It searches for the latest log file in the user's temporary folder that matches the naming pattern.
    If the log file is found, it extracts the installation code and product version from the log file.
    Finally, it outputs the installation code and product version.

.PARAMETER None

.INPUTS
    None.

.OUTPUTS
    $MDIInstallCode
    $productVersion

.NOTES
    This script requires the user to have the appropriate permissions to access the log file.

.LINK
    N/A

.EXAMPLE
    Get-MDIInstallCode.ps1
    Retrieves the installation code and product version from the MDI installation log file.

#>

# Get the installation code from the MDI installation log file
$MDIInstallLog = Get-ChildItem -Path "$env:LocalAppData\Temp" -Filter "Azure Advanced Threat Protection Sensor_*_MsiPackage.log" -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if ($MDIInstallLog -eq $null) {
    Write-Host "MDI installation log file not found"
}

$MDIInstallCode = Get-Content -Path $MDIInstallLog.FullName | Select-String -Pattern "Installation completed successfully"
if ($MDIInstallCode -eq $null) {
    Write-Host "MDI installation code not found"
}

# Extract the product version found in the same logfile
$MDIProductVersion = Get-Content -Path $MDIInstallLog.FullName | Select-String -Pattern "Product Version:"
if ($MDIProductVersion -match '\d+\.\d+\.\d+\.\d+') {
    $productVersion = $matches[0]
    Write-Host "Product version found."
} else {
    Write-Host "Product version not found."
}

# Output the results
Write-Host "MDI installation code: $MDIInstallCode"
Write-Host "MDI product version: $productVersion"

# Get the installation code from the MDI installation log file
$MDIInstallLog = Get-ChildItem -Path "$env:LocalAppData\Temp" -Filter "Azure Advanced Threat Protection Sensor_*_MsiPackage.log" -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if ($MDIInstallLog -eq $null) {
    Write-Host "MDI installation log file not found"
}

$MDIInstallCode = Get-Content -Path $MDIInstallLog.FullName | Select-String -Pattern "Installation completed successfully"
if ($MDIInstallCode -eq $null) {
    Write-Host "MDI installation code not found"
}

# Extract the product version found in the same logfile
$MDIProductVersion = Get-Content -Path $MDIInstallLog.FullName | Select-String -Pattern "Product Version:"
if ($MDIProductVersion -match '\d+\.\d+\.\d+\.\d+') {
    $productVersion = $matches[0]
    Write-Host "Product version found."
} else {
    Write-Host "Product version not found."
}

# Output the results
Write-Host "MDI installation code: $MDIInstallCode"
Write-Host "MDI product version: $productVersion"