# Create a gMSA for MDI action account

## Variables
$accountname = "MDIACTIONGMSA"
$description = "Microsoft Defender for Identity Action Account"
$accountdns = $accountname + "." + ((Get-ADDomain -Current LocalComputer).DNSRoot)
$accountDN = "CN=" + $accountname + ",CN=Managed Service Accounts," + ((Get-ADDomain -Current LocalComputer).DistinguishedName)
$groupname = "MDIActionAccounts"
$grouppath = "OU=Groups,OU=Contoso" + "," + ((Get-ADDomain -Current LocalComputer).DistinguishedName)
$SamAccountName = "MDIActionAccounts"
$groupDN = "CN=" + $groupname + "," + $grouppath
$assignOU = "OU=Users,OU=Contoso" + "," + ((Get-ADDomain -Current LocalComputer).DistinguishedName)
$NETBIOSwGroupName = ((Get-ADDomain -Current LocalComputer).NetBIOSName) + "\" + $groupname

## Create new MDI Action Account group and gMSA
New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name $groupname -Path $grouppath -SamAccountName $SamAccountName
New-ADServiceAccount $accountname -Description $description -DNSHostName $accountdns -PrincipalsAllowedToRetrieveManagedPassword $groupname -KerberosEncryptionType AES256

## Add gMSA to group and protect group from accidental deletion
Set-ADObject -Identity $groupDN -ProtectedFromAccidentalDeletion $true
Set-ADGroup -Add:@{'Member'=$accountDN} -Identity $groupDN

## Assign permissions to the group
### Permissions: Reset Password, Read pwdLastSet, Read userAccountControl, Read member
$params = @("$assignOU", "/I:S", "/G", "$NETBIOSwGroupName`:WP;pwdLastSet;user")
dsacls.exe $params 

$params = @("$assignOU", "/I:S", "/G", "$NETBIOSwGroupName`:WP;userAccountControl;user")
dsacls.exe $params 

$params = @("$assignOU", "/I:S", "/G", "$NETBIOSwGroupName`:CA;Reset Password;user")
dsacls.exe $params 

$params = @("$assignOU", "/I:S", "/G", "$NETBIOSwGroupName`:WP;member;group")
dsacls.exe $params

