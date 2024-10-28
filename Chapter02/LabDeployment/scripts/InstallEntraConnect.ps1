# Define the URL and the local path for the MSI installer
$downloadUrl = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
$localPath = "$env:TEMP\AzureADConnect.msi"

# Download the MSI installer
Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath

# Install Entra Connect silently
Start-Process "msiexec.exe" -ArgumentList "/i `"$localPath`" /qn /norestart" -Wait -NoNewWindow
