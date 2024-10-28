# Install the required module
if (-not (Get-Module -Name Microsoft.Graph.Authentication -ListAvailable)) {
    Install-Module -Name Microsoft.Graph.Authentication -Force
}

# Connect to Microsoft Graph to create a new app registration
Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All,Application.ReadWrite.All -NoWelcome

# Create a new app registration
$displayName = "MDI-Health-Issues-App-Registration"
$apiPermission = "SecurityIdentitiesHealth.Read.All"
$AppRoleId = "f8dcd971-5d83-4e1e-aa95-ef44611ad351"

# Create a new app registration
$appRegistration = New-MgApplication -DisplayName $displayName

# Add API permissions to the app registration
$params = @{
    RequiredResourceAccess = @(
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = @(
                @{
                    Id = $AppRoleId
                    Type = "Role"
                }
            )
        }
    )
}
Update-MgApplication -ApplicationId $appRegistration.Id -BodyParameter $params

# Generate a new secret for the app registration
$secret = Add-MgApplicationPassword -ApplicationId $appRegistration.id

# Grant the app registration
$graphSpId = $(Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'").Id
$sp = New-MgServicePrincipal -AppId $appRegistration.appId
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -AppRoleId $AppRoleId -ResourceId $graphSpId

# Display the app registration details along with the secret
$registrationDetails = @{
    Name = $appRegistration.DisplayName
    AppId = $appRegistration.AppId
    Secret = $secret.SecretText
    Permission = $apiPermission
}
$registrationDetails

# Disconnect all sessions from Microsoft Graph
Disconnect-MgGraph

# Connect to Microsoft Graph using the app registration
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $appRegistration.AppId, ($secret.SecretText | ConvertTo-SecureString -AsPlainText -Force)
Connect-MgGraph -TenantId "b29a1c6d-3698-4e5d-b3c6-3a7e2976bf69" -ClientSecretCredential $credential
