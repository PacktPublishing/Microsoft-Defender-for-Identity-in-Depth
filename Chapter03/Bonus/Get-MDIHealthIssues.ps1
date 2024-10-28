# PowerShell script that uses the Microsoft Graph Security API to get the health issues of Defender for Identity

#GET https://graph.microsoft.com/beta/security/identities/healthIssues

#Required permissions in Entra ID - SecurityIdentitiesHealth.Read.All

# Required Modules
Import-Module Az.Accounts
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Security

# Azure AD App credentials and Log Analytics workspace details
$tenantId = '<Tenant-ID>'
$appId = '<App-ID>'
$appSecret = '<App-Secret>'
$logAnalyticsWorkspaceId = '<Log-Analytics-Workspace-ID>'
$logAnalyticsKey = '<Log-Analytics-Primary-Key>'

# Function to authenticate and get a token for Microsoft Graph API
Function Get-AuthToken {
    $body = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $appId
        client_secret = $appSecret
    }
    $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $body
    return $response.access_token
}

# Function to send data to Log Analytics
Function Send-ToLogAnalytics {
    param (
        $LogType,
        $json
    )
    $customerId = $logAnalyticsWorkspaceId
    $sharedKey = $logAnalyticsKey
    $timeStampField = 'eventTime'
    $date = Get-Date -Format r
    $stringToHash = "POST\n" + $json.Length + "\napplication/json\n" + "x-ms-date:" + $date + "\n/api/logs"
    $bytesToHash = [Text.Encoding]::ASCII.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = $keyBytes
    $signature = $hmacsha256.ComputeHash($bytesToHash) | ForEach-Object { '{0:x2}' -f $_ } -join ''
    $authorization = 'SharedKey ' + $customerId + ':' + $signature
    $headers = @{
        "Authorization" = $authorization
        "Log-Type" = $LogType
        "x-ms-date" = $date
        "time-generated-field" = $timeStampField
    }
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $json
}

# Main function to retrieve health issues and log them
Function Main {
    $token = Get-AuthToken
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }
    $uri = "https://graph.microsoft.com/beta/security/identityContainer/healthIssues"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $json = $response.value | ConvertTo-Json -Depth 10
    Send-ToLogAnalytics -LogType "DefenderIdentityHealthIssues" -json $json
}

# Execute the main function
Main
