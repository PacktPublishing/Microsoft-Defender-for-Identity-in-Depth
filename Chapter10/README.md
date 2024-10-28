# Chapter 10: Navigating Challenges: MDI Troubleshooting and Optimization

## gMSA Credentials Not Retrieved
- What it means: The sensor might fail to retrieve the Group Managed Service Account (gMSA) password, preventing it from functioning properly.
- How to fix it: Ensure that the server has the necessary permissions to access the gMSA credentials. Verify that the gMSA account is properly configured and that the network connectivity required to retrieve the credentials is functioning without interruption. Also make sure to have a security group where all of your MDI sensor servers (AD DS, AD CS, AD FS, and Entra Connect) will be a member of. Run the following command in a PowerShell window within one of your domain controllers, replace the name of the gMSA account that you have created:

```powershell
Get-ADServiceAccount -Name <name of gMSA> -Properties PrincipalsAllowedToRetrieveManagedPassword
In the output you should see either the security group or the individual servers under the property PrincipalsAllowedToRetrieveManagedPassword 
```

## Testing MDI Sensor Connectivity
If your MDI sensor isn’t communicating with the backend, it’s essential to test connectivity as early as possible and to start troubleshooting. You can use PowerShell to run diagnostic tests that simulate the sensor’s communication with the MDI backend.

### Using PowerShell
1.	Start Windows PowerShell or PowerShell 7 on the MDI sensor server.
2.	Run the following command to test the connection to the MDI backend:

```powershell
Invoke-WebRequest -Uri https://<your-instance-name>sensorapi.atp.azure.com/tri/sensor/api/ping
```
> [!TIP]
> For Windows Server Core edition, make sure to use the `-UseBasicParsing` parameter within the Invoke-WebRequest cmdlet.

```powershell
Invoke-WebRequest -UseBasicParsing -Uri https://<your-instance-name>sensorapi.atp.azure.com/tri/sensor/api/ping
```

Replace `<your-instance-name>` with your actual MDI instance name. 


### Using MDI PowerShell module
Before you begin, ensure that the Defender for Identity PowerShell module is installed on your server. This module provides the necessary cmdlets for testing and managing MDI sensor connectivity.
Once you’ve verified that the Defender for Identity PowerShell module is installed, you can test the sensor’s connectivity using different approaches based on your requirements. Whether you want to verify the connection using the current server configuration or test it with specific settings, there are two main options available:

- **Option A**: Test Using Current Server Configuration:
To test connectivity using the server’s existing settings, open PowerShell and run:

```powershell
Test-MDISensorApiConnection
```

This command checks if the sensor can successfully connect to the MDI cloud service using the current configuration, including any proxy settings.

- **Option B**: Test Using Specific Settings:
If you want to test connectivity with settings that aren’t currently applied to the server, use the following syntax:

```powershell
$credential = Get-Credential
Test-MDISensorApiConnection -BypassConfiguration -SensorApiUrl 'https://<your-instance-name>sensorapi.atp.azure.com' -ProxyUrl 'https://your-proxy-server:port' -ProxyCredential $credential
```

Replace the placeholders with:
 - `https://<your-instance-name>sensorapi.atp.azure.com`: Your actual sensor API URL, where your-instance-name is the name of your MDI workspace (observe that there’s no dot between the instance name and the sensorapi part).
- `https://your-proxy-server:port`: The URL and port number of your proxy server.
- `$credential`: A PowerShell credential object containing your proxy authentication details.
