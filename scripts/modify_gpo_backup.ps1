Install-Module -Name GPRegistryPolicyParser
$script:policyPath = 'C:\GPO\wef_configuration\{F523FD69-7E4C-4315-93D0-557089F1B8A1}\DomainSysvol\GPO\Machine\'
$script:REGFILE_SIGNATURE = 0x67655250 # PRef
$script:REGISTRY_FILE_VERSION = 0x00000001 #Initially defined as 1, then incremented each time the file format is changed.

Function Create-GPRegistryPolicyFile
{
    param (
        [Parameter(Mandatory)]
        $Path
    )

    $null = Remove-Item -Path $Path -Force -Verbose -ErrorAction SilentlyContinue

    New-Item -Path $Path -Force -Verbose -ErrorAction Stop | Out-Null

    [System.BitConverter]::GetBytes($script:REGFILE_SIGNATURE) | Add-Content -Path $Path -Encoding Byte
    [System.BitConverter]::GetBytes($script:REGISTRY_FILE_VERSION) | Add-Content -Path $Path -Encoding Byte
}

Create-GPRegistryPolicyFile -Path "$script:policyPath\registry.pol.tmp"
$PolicySettings = Parse-PolFile -Path "$script:policyPath\registry.pol"
$PolicySettings[1].ValueData="Server=http://win16-wef1.lab.local:5985/wsman/SubscriptionManager/WEC,Refresh=60"
Append-RegistryPolicies -RegistryPolicies $PolicySettings -Path "$script:policyPath\registry.pol.tmp"

Rename-Item  "$script:policyPath\registry.pol" "$script:policyPath\registry.pol.bak"
Rename-Item  "$script:policyPath\registry.pol.tmp" "$script:policyPath\registry.pol"

$GPOName = 'Windows Event Forwarding Server'
Import-GPO -BackupGpoName $GPOName -Path "c:\GPO\wef_configuration" -TargetName $GPOName -CreateIfNeeded 
