param (
    [Parameter(Mandatory)]
    [string]$Acct,

    [Parameter(Mandatory)]
    [string]$PW,

	[Parameter(Mandatory)]
	[string]$WapFqdn

	[Parameter(Mandatory)]
	[string]$gMSA_ADFS
)

#Forcing TLS 1.2 on calls from this script
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

$wmiDomain = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
$DCName = $wmiDomain.DomainControllerName
$ComputerName = $wmiDomain.PSComputerName
$Subject = $WapFqdn -f $instance

$DomainName=$wmiDomain.DomainName
$DomainNetbiosName = $DomainName.split('.')[0]
$SecPw = ConvertTo-SecureString $PW -AsPlainText -Force
[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Acct)", $SecPW)

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()  
$principal = new-object Security.Principal.WindowsPrincipal $identity 
$elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  

if (-not $elevated) {
    $a = $PSBoundParameters
    $cl = "-Acct $($a.Acct) -PW $($a.PW)"
    $arglist = (@("-file", (join-path $psscriptroot $myinvocation.mycommand)) + $args + $cl)
    Write-host "Not elevated, restarting as admin..."
    Start-Process cmd.exe -Credential $DomainCreds -NoNewWindow -ArgumentList "/c powershell.exe $arglist"
} else {
    Write-Host "Elevated, continuing..." -Verbose

    #Configure ADFS Farm
    Import-Module ADFS
    $wmiDomain = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
    $DCName = $wmiDomain.DomainControllerName
    $ComputerName = $wmiDomain.PSComputerName
    $DomainName=$wmiDomain.DomainName
    $DomainNetbiosName = $DomainName.split('.')[0]
    $SecPw = ConvertTo-SecureString $PW -AsPlainText -Force

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Acct)", $SecPW)

    $Index = $ComputerName.Substring($ComputerName.Length-1,1)
	$Subject = $WapFqdn -f $Index
	Write-Host "Subject: $Subject"

    #get thumbprint of certificate
    $cert = Get-ChildItem Cert:\LocalMachine\My | where {$_.Subject -eq "CN=$Subject"}
	try {
	    Get-ADfsProperties -ErrorAction Stop
        Write-Host "Farm already configured" -Verbose
	}
	catch {
		Install-AdfsFarm `
			-CertificateThumbprint $cert.thumbprint `
			-FederationServiceName $Subject `
			-ServiceAccountCredential (Get-ADServiceAccount $gMSA_ADFS) `
			-OverwriteConfiguration

        Write-Host "Farm configured" -Verbose
	}

	Set-AdfsProperties -EnableIdPInitiatedSignonPage $true 
 
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}