# Enable Active Directory Recycle Bin
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target (Get-ADDomain).DNSRoot -Confirm:$false

# Add KDS Root Key
Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)

# Install NuGet provider
Install-PackageProvider -Name NuGet -Force

# Install Defender for Identity module
Install-Module DefenderForIdentity -Force

# Import Defender for Identity module
Import-Module DefenderForIdentity

# Create new gMSA for MDI sensor, and create a group for the sensor, the cmdlet will also set the required permissions for the Deleted Objects container
New-MDIDSA -Identity "MDIGMSA" -GmsaGroupName "MDIGroup"

# Create new gMSA for AD FS
New-ADServiceAccount -Name "ADFSGMSA" -DNSHostName "adfs.$env:USERDNSDOMAIN" -PrincipalsAllowedToRetrieveManagedPassword "ADFS01$"