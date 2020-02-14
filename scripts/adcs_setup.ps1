<#
.SYNOPSIS
Install an Enterprise PKI with HTTP CRL and AIA publishing

.DESCRIPTION
Install ADFS and IIS roles and configure ADFS to publish CRL and AIA over HTTP and LDAP.
All Certificate Templates are removed from the Enterprise PKI during the installation.

.PARAMETER CACommonName 
The name of the Certificate Authority, default is My5mnPKI"

.PARAMETER RootDirectory
Path where the script will install ADFS and IIS Website, default is C:\ADFS

.PARAMETER WebSiteName
Name of the IIS WebSite, default is My5mnPKI

.PARAMETER HTTPHostname
Published hostname of the PKI, default is the computer fqdn

.PARAMETER logpath
Where the script save is transcript, default is c:\Windows\temp\My5mnPKI.log
#>


Param(
[Parameter()] [String] $CACommonName = "My5mnPKI",
[Parameter()] [String] $RootDirectory = "C:\ADFS",
[Parameter()] [String] $WebSiteName = "My5mnPKI",
[Parameter()] [String] $HTTPHostname = [System.Net.Dns]::GetHostByName(($env:computerName)).hostname,
[Parameter()] [String] $logpath = "c:\Windows\temp\My5mnPKI.log"
)

Start-Transcript -Path $logpath

#region check domain joined
try {
    [System.DirectoryServices.ActiveDirectory.domain]::GetComputerDomain()
}
catch {
    Write-Error "Computer is not domain joined or can't join the domain"
    Exit 0
}
#endregion check domain joined

#region Directory
try {
    Write-host "Create Directory"
    New-Item -ItemType Directory -Path "$RootDirectory\DB" -Force 
    New-Item -ItemType Directory -Path "$RootDirectory\Log" -Force 
    New-Item -ItemType Directory -Path "$RootDirectory\InetSrv" -Force 
    New-Item -ItemType Directory -Path "$RootDirectory\IISLog" -Force 
}
catch {
    Write-Error "Error during directory creation"
    Write-Error $_.ToString()
    Exit 0
}
#endregion Directory

#region ACL
try {
    Write-Host "Set ACL"
    # remove ACL inheritance
    $ACL = Get-Acl -Path "$RootDirectory"
    $ACL.SetAccessRuleProtection($true,$true)
    $ACL | Set-ACL 

    # purge ACE if not system or administrator or Owner            
    $ace = $acl.Access | where  {($_.IdentityReference.translate([System.Security.Principal.SecurityIdentifier]).value -ne 'S-1-5-18') `
        -and ($_.IdentityReference.translate([System.Security.Principal.SecurityIdentifier]).value -ne 'S-1-5-32-544') `
        -and ($_.IdentityReference.translate([System.Security.Principal.SecurityIdentifier]).value -ne 'S-1-3-0')
        }
    
    $ace | foreach {
        $ACL.RemoveAccessRule($_)
    }
    
    Set-Acl -Path "$RootDirectory" -AclObject $ACL 
    
    # add Anonymous User READ acl to InetSrv and descendant files
    $alluser = New-Object System.Security.Principal.SecurityIdentifier S-1-1-0
    $ACL = Get-Acl -Path "$RootDirectory\InetSrv"
    $ACL.AddAccessRule((new-object System.Security.AccessControl.FileSystemAccessRule $alluser,ReadAndExecute,ObjectInherit,InheritOnly,Allow))
    Set-Acl -Path "$RootDirectory\InetSrv" -AclObject ($ACL) 
}
catch {
    Write-Error "Error during ACL setting"
    Write-Error $_.ToString()
    Exit 0
}
#endregion ACL

#region WindowsFeatures
try {
    Write-Host "Install Windows Features"
    Install-WindowsFeature ADCS-Cert-Authority, RSAT-ADCS-Mgmt, Web-Http-Errors, Web-Static-Content, Web-Http-Logging, Web-Custom-Logging, Web-Stat-Compression, Web-Mgmt-Console 
}
catch {
    Write-Error "Error during Windows features installation"
    Write-Error $_.ToString()
    Exit 0
}
#endregion WindowsFeatures
    
#region IIS
try {
    Write-Host "Configure IIS"
    <# Create and Configure the IIS server for CRL and AIA #>
    Import-module WebAdministration

    New-Website -Name "My5mnPKI" -PhysicalPath "$RootDirectory\InetSrv" -HostHeader $HTTPHostname 
    # Set IIS Log Directory
    Set-WebConfigurationProperty -Filter "/system.applicationHost/sites/site[@name=""$WebSiteName""]/logFile"  -Value "$RootDirectory\IISLog" -name "directory" 
}
catch {
    Write-Error "Error during Windows features installation"
    Write-Error $_.ToString()
    Exit 0
}
#endregion IIS
    
#region ADCS
try {
    Write-Host "Install AD CS"
    Import-Module ADCSDeployment   
    Install-AdcsCertificationAuthority -CACommonName $CACommonName -CAType EnterpriseRootCA -DatabaseDirectory "$RootDirectory\DB" -LogDirectory "$RootDirectory\Log" -HashAlgorithmName SHA256 -KeyLength 2048 -Force -Verbose
    Start-Sleep 10
}
catch {
    Write-Error "Error during ADCS installation"
    Write-Error $_.ToString()
    Exit 0
}
    
try { 
    Write-Host "Configure AD CS"
    Import-module ADCSAdministration

    # clear all template
    Get-CATemplate | Remove-CATemplate -Force 

    # create new HTTP CRL and AIA
    Add-CACrlDistributionPoint  -Uri "http://$HTTPHostname/$CACommonName.crl" -AddToCertificateCdp -Force 
    Add-CAAuthorityInformationAccess -Uri "http://$HTTPHostname/$CACommonName.crt" -AddToCertificateAia -Force     
    
    # publish CRL 
    Add-CACrlDistributionPoint  -Uri "file://$RootDirectory/InetSrv/$CACommonName.crl" -PublishToServer -Force 
    Restart-Service CertSvc
    Start-Sleep 10
    certutil -crl 

    # publish AIA
    $a = Get-ChildItem -Path cert:\LocalMachine\My | where {$_.Subject -like "CN=$CACommonName*"} 
    $cer = $a.Export( [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    [io.file]::WriteAllBytes("$RootDirectory\InetSrv\$CACommonName.crt",$cer)
}
catch {
    Write-Error "Error during Windows features installation"
    Write-Error $_.ToString()
    Exit 0
}
#endregion ADCS

Write-Host "Installation done, check transcript at $logpath"
Stop-Transcript
