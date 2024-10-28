# Chapter 5: Extending MDI capabilities through APIs

## Getting started with Microsoft Graph API
### Creating App Registration Using Bicep

1. Save the files [main.bicep](Chapter04/main.bicep) and [bicepconfig.json](Chapter04/bicepconfig.json) to your local computer.

2. Start Windows PowerShell if you don’t have PowerShell 7. If you already have PowerShell 7 installed, skip to the next step. To install PowerShell 7, type the following command: 

```powershell
winget install --id Microsoft.Powershell --source winget
```

#### Using Azure CLI 

To use Azure CLI, follow the below steps, if you want to use Azure PowerShell for deployment – refer to the following section. 

1. Open the newly installed PowerShell 7 from the start menu and then type below to install Azure CLI: 

```powershell
winget install -e --id Microsoft.AzureCLI 
```

2. If not logged in, run the following command to login to Azure and follow the sign in prompt
```powershell
az login
```

3. Choose the subscription that you want to create a new resource group to be able to deploy the Bicep file.

4. Change the path in the console to the location where you have the `main.bicep` file.

5. Type the following to create a new resource group (choose name of your resource group and Azure location, like for example: `westeurope` or `eastus`)

```powershell
az group create --name rg-GraphAPI-test-001 --location westeurope
```

6. Run the below query for deployment:

```powershell
$AppRegDeploy = az deployment group create --resource-group rg-GraphAPI-test-001 --template-file .\main.bicep
```

7. Now in the variable `$AppRegDeploy` we have some JSON output that we need to handle to gather our newly created secret. Type this to convert the JSON result to a PowerShell object: 

```powershell
$AppRegDeployObj = $AppRegDeploy | ConvertFrom-Json 
```

8. We can now extract the secret value which is located at `properties` > `outputs` > `secretValue` > `value` 

```powershell
$secretValue = $AppRegDeployObj.properties.outputs.secretValue.value 
```

9. With a new variable called `$secretValue` we will now find our secret: 

```powershell
$secretValue
```

#### Using Azure PowerShell 

To use Azure PowerShell module, follow below steps: 

1. Before we proceed, we need to install Bicep CLI from winget. Type the following: 

```powershell
winget install -e --id Microsoft.Bicep 
```

2. If not logged in, run below to login to Azure and follow the sign in prompt: 

```powershell
Login-AzAccount 
```

3. Choose the subscription that you want to create a new resource group to be able to deploy the Bicep file.

4. Change the path in the console to the location where you have the `main.bicep` file. 

5. Type the following to create a new resource group (choose name of your resource group and Azure location, like for example: `westeurope` or `eastus`) 

```powershell
New-AzResourceGroup -Name rg-GraphAPI-test-001 -Location eastus
```

6. Run the following for deployment: 

```powershell
$AppRegDeploy = New-AzResourceGroupDeployment -ResourceGroupName rg-GraphAPI-test-001 -TemplateFile .\main.bicep
```

7. Now in the variable `$AppRegDeploy` we have the output from the `New-AzResourceGroupDeployment`, to get the value of the secret we simply type the following:

```powershell
$AppRegDeploy.Outputs.secretValue.Value
```

8. With a new variable called `$secretValue` we will now find our secret: 

```powershell
$secretValue
```

## Creating Enterprise Application


## Getting the Access Token
### Using PowerShell

#### Invoke-RestMethod
Interaction with the Microsoft Graph API. The example fetches user profile information by making a `GET` request. Here’s how you can structure your request: 

```powershell
$uri = "https://graph.microsoft.com/v1.0/me"
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$response = Invoke-RestMethod -Uri $uri -Headers $headers
$response 
```


#### Invoke-WebRequest
For scenarios requiring detailed HTTP response data, `Invoke-WebRequest` is particularly useful. Here’s how to set up and execute a request that provides comprehensive response details: 

```powershell
$uri = "https://graph.microsoft.com/v1.0/me"
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$response = Invoke-WebRequest -Uri $uri -Headers $headers
$response
```

Additionally, you can parse the JSON content from the response body to manipulate it further: 

```powershell
$data = $response.Content | ConvertFrom-Json
$data
```

## Making API Calls

```powershell
$tenantId = "<your_tenant_id>"
$clientId = "<your_client_id>"
$clientSecret = "<your_client_secret>"

$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body

$accessToken = $tokenResponse.access_token

$headers = @{
    Authorization = "Bearer $accessToken"
} 
```

Next, we’ll query healthIssue API to be able to gather open issues with our sensors using the following: 

```powershell
$uri = "https://graph.microsoft.com/beta/security/identities/healthIssues"

$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
```

We’ll output the response using the following command: 

```powershell
$response.value
```