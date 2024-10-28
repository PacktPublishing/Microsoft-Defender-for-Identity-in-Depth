# Chapter 4: Integrating MDI with AD FS, AD CS, and Entra Connect

# Table of Contents

- [Integrating MDI with AD FS](#integrating-mdi-with-ad-fs)
    - [AD FS Advanced Auditing / Verbose settings](#ad-fs-advanced-auditing--verbose-settings)
    - [Configuring SACL on AD FS container](#configuring-sacl-on-ad-fs-container)
    - [AD FS database permissions](#ad-fs-database-permissions)
    - [Validate MDI sensor service](#validate-mdi-sensor-service)
    - [Enable AD FS IdP-Initiated Sign-On Page](#enable-ad-fs-idp-initiated-sign-on-page)
    - [Verify AD FS log ingestion to Defender XDR](#verify-ad-fs-log-ingestion-to-defender-xdr)
- [Integrating MDI with AD CS](#integrating-mdi-with-ad-cs)
    - [Implementing CA Auditing via PowerShell](#implementing-ca-auditing-via-powershell)
    - [Validating the AD CS integration](#validating-the-ad-cs-integration)
- [Integrating MDI with Entra Connect](#integrating-mdi-with-entra-connect)
    - [Verify Entra Connect log ingestion to Defender XDR](#verify-entra-connect-log-ingestion-to-defender-xdr)


## Integrating MDI with AD FS
### AD FS Advanced Auditing / Verbose settings

On your AD FS server; 
1. Start Windows PowerShell 
2. Ensure that the `DefenderForIdentity` module is installed on your 
server. For detailed installation instructions, see Chapter 2. 
- On servers that are not domain controllers, ensure the following modules 
are installed, as they are required by the `DefenderForIdentity` 
module: 
    - `ActiveDirectory` (RSAT-AD-Tools)
        ```powershell
        Install-WindowsFeature –Name RSAT-AD-Tools
        ```
    - `GroupPolicy` (GPMC)
        ```powershell
        Install-WindowsFeature –Name GPMC
        ```

3. Type the commands below to configure the required audit settings

```powershell
Import-Module –Name DefenderForIdentity
Set-AdfsProperties -AuditLevel Verbose
```

### Configuring SACL on AD FS container

Follow the below steps to configure the SACL for advanced auditing settings: 
1. On one of your domain controllers, start Windows PowerShell 
2. Run the following command for configuring the AD FS auditing settings:

```powershell 
Set-MDIConfiguration -Mode Domain -Configuration AdfsAuditing 
```

3. Verify the setting with the following command; you should now get an output 
that says `True`

```powershell
Test-MDIConfiguration -Mode Domain -Configuration AdfsAuditing 
```

### AD FS database permissions

- PowerShell script to find the database name

```powershell
$adfs = Get-WmiObject -Namespace "root/ADFS" -Class "SecurityTokenService"
$connectionString = $adfs.ConfigurationDatabaseConnectionString
$components = $connectionString.Split(';')
$initialCatalogComponent = $components | Where-Object { $_.StartsWith("Initial Catalog") }
$initialCatalog = $initialCatalogComponent.Split('=')[1].Trim()
Write-Output "Connection String: $connectionString"
Write-Output "Initial Catalog: $initialCatalog"
```

- Configure the database permissions

```powershell
$ConnectionString = 'server=\\.\pipe\MICROSOFT##WID\tsql\query;database=OurDatabaseName;trusted_connection=true;'
$SQLConnection= New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
$SQLConnection.Open()
$SQLCommand = $SQLConnection.CreateCommand()
$SQLCommand.CommandText = @"
USE [master];  
CREATE LOGIN [CONTOSO\MDIGMSA$] FROM WINDOWS WITH
DEFAULT_DATABASE=[master];
USE [OurDatabaseName];
CREATE USER [CONTOSO\MDIGMSA$] FOR LOGIN
[CONTOSO\MDIGMSA$];
ALTER ROLE [db_datareader] ADD MEMBER [CONTOSO\MDIGMSA$];
GRANT CONNECT TO [CONTOSO\MDIGMSA$];
GRANT SELECT TO [CONTOSO\MDIGMSA$];
"@
$SqlDataReader = $SQLCommand.ExecuteReader()
$SQLConnection.Close()
```

- Validate MDI sensor service

```powershell
Get-Service AATPSensor | Select-Object Status
```

- Enable AD FS IdP-Initiated Sign-On Page

```powershell
Get-AdfsProperties | Select-Object –ExpandProperty EnableIdPInitiatedSignonPage
Set-AdfsProperties –EnableIdPInitiatedSignonPage $true
```

- Verify AD FS log ingestion to Defender XDR

```kql
IdentityLogonEvents
| where Protocol =~ 'Adfs'
```

## Integrating MDI with AD CS
### Implementing CA Auditing via PowerShell 

1. Modify the CA audit settings

```powershell
certutil -setreg CA\AuditFilter 127
```

2. To ensure the new settings take effect immediately, cycle the Certificate Services 

```powershell
Stop-Service -Name certsvc
Start-Service -Name certsvc
```

### Validating the AD CS integration

1. Validate MDI sensor service

```powershell
Get-Service AATPSensor | Select-Object Status
```

2. Test certificate request with PowerShell

```powershell
$certRequest = @"
[Version]
Signature = "$Windows NT$"
[NewRequest]
Subject = "CN=TestUser, OU=YourOU, O=YourOrg, C=US"
KeyLength = 2048
Exportable = TRUE
MachineKeySet = FALSE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel
Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
"@
```

3. Save the certificate request data to a file

```powershell
$requestFile = "C:\Temp\ESC1_certRequest.inf"
$certRequest | Out-File -FilePath $requestFile
```

4. Generate the certificate request

```powershell
$certReqFileOutput = "C:\Temp\ESC1_certReq.req"
certreq -new $requestFile $certReqFileOutput
```

5. Verify AD CS log ingestion to Defender XDR

```kql
IdentityDirectoryEvents
| where Protocol =~ "Adcs"
```

## Integrating MDI with Entra Connect

- Verify Entra Connect log ingestion to Defender XDR

```kql
IdentityDirectoryEvents 
| where Application =~ "Entra Connect"
```


## Integrating MDI with AD FS
### AD FS Advanced Auditing / Verbose settings

On your AD FS server; 
1. Start Windows PowerShell 
2. Ensure that the `DefenderForIdentity` module is installed on your 
server. For detailed installation instructions, see Chapter 2. 
- On servers that are not domain controllers, ensure the following modules 
are installed, as they are required by the `DefenderForIdentity` 
module: 
  - `ActiveDirectory` (RSAT-AD-Tools)
    ```powershell
    Install-WindowsFeature –Name RSAT-AD-Tools
    ```
  - `GroupPolicy` (GPMC)
    ```powershell
    Install-WindowsFeature –Name GPMC
    ```

3. Type the commands below to configure the required audit settings

```powershell
Import-Module –Name DefenderForIdentity
Set-AdfsProperties -AuditLevel Verbose
```

### Configuring SACL on AD FS container

Follow the below steps to configure the SACL for advanced auditing settings: 
1. On one of your domain controllers, start Windows PowerShell 
2. Run the following command for configuring the AD FS auditing settings:

```powershell 
Set-MDIConfiguration -Mode Domain -Configuration AdfsAuditing 
```

3. Verify the setting with the following command; you should now get an output 
that says `True`

```powershell
Test-MDIConfiguration -Mode Domain -Configuration AdfsAuditing 
```

### AD FS database permissions

- PowerShell script to find the database name

```powershell
$adfs = Get-WmiObject -Namespace "root/ADFS" -Class "SecurityTokenService"
$connectionString = $adfs.ConfigurationDatabaseConnectionString
$components = $connectionString.Split(';')
$initialCatalogComponent = $components | Where-Object { $_.StartsWith("Initial Catalog") }
$initialCatalog = $initialCatalogComponent.Split('=')[1].Trim()
Write-Output "Connection String: $connectionString"
Write-Output "Initial Catalog: $initialCatalog"
```

- Configure the database permissions

```powershell
$ConnectionString = 'server=\\.\pipe\MICROSOFT##WID\tsql\query;database=OurDatabaseName;trusted_connection=true;'
$SQLConnection= New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
$SQLConnection.Open()
$SQLCommand = $SQLConnection.CreateCommand()
$SQLCommand.CommandText = @"
USE [master];  
CREATE LOGIN [CONTOSO\MDIGMSA$] FROM WINDOWS WITH
DEFAULT_DATABASE=[master];
USE [OurDatabaseName];
CREATE USER [CONTOSO\MDIGMSA$] FOR LOGIN
[CONTOSO\MDIGMSA$];
ALTER ROLE [db_datareader] ADD MEMBER [CONTOSO\MDIGMSA$];
GRANT CONNECT TO [CONTOSO\MDIGMSA$];
GRANT SELECT TO [CONTOSO\MDIGMSA$];
"@
$SqlDataReader = $SQLCommand.ExecuteReader()
$SQLConnection.Close()
```

- Validate MDI sensor service

```powershell
Get-Service AATPSensor | Select-Object Status
```

- Enable AD FS IdP-Initiated Sign-On Page

```powershell
Get-AdfsProperties | Select-Object –ExpandProperty EnableIdPInitiatedSignonPage
Set-AdfsProperties –EnableIdPInitiatedSignonPage $true
```

- Verify AD FS log ingestion to Defender XDR

```kql
IdentityLogonEvents
| where Protocol =~ 'Adfs'
```

## Integrating MDI with AD CS
### Implementing CA Auditing via PowerShell 

1. Modify the CA audit settings

```powershell
certutil -setreg CA\AuditFilter 127
```

2. To ensure the new settings take effect immediately, cycle the Certificate Services 

```powershell
Stop-Service -Name certsvc
Start-Service -Name certsvc
```

### Validating the AD CS integration

1. Validate MDI sensor service

```powershell
Get-Service AATPSensor | Select-Object Status
```

2. Test certificate request with PowerShell

```powershell
$certRequest = @"
[Version]
Signature = "$Windows NT$"
[NewRequest]
Subject = "CN=TestUser, OU=YourOU, O=YourOrg, C=US"
KeyLength = 2048
Exportable = TRUE
MachineKeySet = FALSE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel
Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
"@
```

3. Save the certificate request data to a file

```powershell
$requestFile = "C:\Temp\ESC1_certRequest.inf"
$certRequest | Out-File -FilePath $requestFile
```

4. Generate the certificate request

```powershell
$certReqFileOutput = "C:\Temp\ESC1_certReq.req"
certreq -new $requestFile $certReqFileOutput
```

5. Verify AD CS log ingestion to Defender XDR

```kql
IdentityDirectoryEvents
| where Protocol =~ "Adcs"
```

## Integrating MDI with Entra Connect

- Verify Entra Connect log ingestion to Defender XDR

```kql
IdentityDirectoryEvents 
| where Application =~ "Entra Connect"
```

