# Chapter 9: Building a Resilient Identity Threat Detection and Response Framework


## Example 1: Detecting Unauthorized Group Membership Changes

IdentityDirectoryEvents
| where Application == "Active Directory"
| where ActionType == "Group Membership changed"
| where DestinationDeviceName != "" 
| extend ToGroup = tostring(parse_json(AdditionalFields).["TO.GROUP"]) 
| extend FromGroup = tostring(parse_json(AdditionalFields).["FROM.GROUP"])
| extend Action = iff(isempty(ToGroup), "Remove", "Add")
| extend GroupModified = iff(isempty(ToGroup), FromGroup, ToGroup) 
| extend Target_Group = tostring(parse_json(AdditionalFields)["TARGET_OBJECT.GROUP"])
//| where GroupModified == "Domain Admins"
| project Timestamp, Action, GroupModified,  Target_Account = TargetAccountDisplayName, Target_UPN = TargetAccountUpn, Target_Group,  DC=DestinationDeviceName, Actor=AccountName, ActorDomain=AccountDomain, AdditionalFields


IdentityLogonEvents
| where AccountName contains "<username>"
| where Application == "Active Directory"
| summarize TotalCount=count(),FirstSeen=min(Timestamp),LastSeen=max(Timestamp),SuccessCount=countif(ActionType=="LogonSuccess"),ListOfSuccessfulDevices=make_set_if(DeviceName,ActionType=="LogonSuccess"),FailureCount=countif(ActionType=="LogonFailed"),ListofFailedDevices=make_set_if(DeviceName,ActionType=="LogonFailure") by AccountName,DeviceName,LogonType


## Example 2: Monitoring Service Creation Events for Persistent Threats

IdentityDirectoryEvents
| where ActionType == "Service creation"
| project Timestamp, Application, AccountName, AdditionalFields.ServiceName


## Orchestrator Function

Here’s a simplified example:
function Run-Orchestrator {
    param([OrchestrationContext] $context)

    # Fan-out: Trigger parallel tasks
    $tasks = @()
    $tasks += Invoke-DurableActivity -FunctionName 'Query-AbuseIPDB' -Input $context
    $tasks += Invoke-DurableActivity -FunctionName 'Check-SignInLogs' -Input $context
    $tasks += Invoke-DurableActivity -FunctionName 'Check-DeviceCompliance' -Input $context

    # Fan-in: Wait for all tasks to complete
    $results = Wait-DurableTask -Task $tasks

    # Process the aggregated results
    $finalResult = @{
        AbuseIPDB = $results[0]
        SignInLogs = $results[1]
        DeviceCompliance = $results[2]
    }

    # Return consolidated results
    return $finalResult
}


## Activity Functions

For example, an activity function could query AbuseIPDB to enrich MDI alerts with additional information about an IP address involved in a potential incident:
function Invoke-Query-AbuseIPDB {
    param([ActivityContext] $context)
    
    # Query AbuseIPDB for IP reputation
    $ip = $context.Input.IpAddress
    $result = Invoke-RestMethod -Uri "https://api.abuseipdb.com/api/v2/check?ipAddress=$ip" -Headers @{ "Key" = "API_KEY" ; "Accept" = "application/json" }
    return ($result.content | ConvertFrom-Json).data
}
