# Chapter 7: Investigating and Responding to Security Alerts


To efficiently monitor or even hunt for changes to high-value Active Directory groups, the following KQL query can be an essential tool in your security toolkit:

```kql
let SensitiveGroupName = pack_array(
    'Account Operators',
    'Administrators',
    'Backup Operators',
    'Domain Admins',
    'Domain Controllers',
    'Enterprise Admins',
    'Enterprise Read-only Domain Controllers',
    'Group Policy Creator Owners',
    'Incoming Forest Trust Builders',
    'Microsoft Exchange Servers',
    'Network Configuration Operators',
    'Power Users',
    'Print Operators',
    'Read-only Domain Controllers',
    'Replicators',
    'Schema Admins',
    'Server Operators'
);
IdentityDirectoryEvents
| where Application == "Active Directory"
| where ActionType == "Group Membership changed"
| extend ToGroup = tostring(parse_json(AdditionalFields).["TO.GROUP"])
| extend FromGroup = tostring(parse_json(AdditionalFields).["FROM.GROUP"])
| extend Action = iff(isempty(ToGroup), "Remove", "Add")
| extend GroupModified = iff(isempty(ToGroup), FromGroup, ToGroup)
| extend Target_Group = tostring(parse_json(AdditionalFields).["TARGET_OBJECT.GROUP"])
| where GroupModified in~ (SensitiveGroupName)
```



