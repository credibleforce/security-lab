param(
    [Parameter(Mandatory=$true,Position=0,HelpMessage="Splunk Web Password")]
    [string]$SplunkPassword,
    
    [Parameter(Mandatory=$true,Position=1,HelpMessage="Splunk Deployment Server Hostname")]
    [string]$SplunkDeploymentServer
)

If (-not (Test-Path "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe")) {
    Write-Host "Downloading Splunk Universal Forwarder"
    $msiFile = $env:Temp + "\splunkforwarder-8.0.2-a7f645ddaf91-x64-release.msi"

    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Installing & Starting Splunk"
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    (New-Object System.Net.WebClient).DownloadFile('https://www.splunk.com/page/download_track?file=8.0.2/windows/splunkforwarder-8.0.2-a7f645ddaf91-x64-release.msi&ac=&wget=true&name=wget&platform=Windows&architecture=x86_64&version=8.0.2&product=universalforwarder&typed=release', $msiFile)
    Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList '/i', "$msiFile", $('DEPLOYMENT_SERVER="{0}:8089"  AGREETOLICENSE=Yes SERVICESTARTTYPE=auto LAUNCHSPLUNK=1 SPLUNKPASSWORD="{1}" /quiet' -f ${SplunkDeploymentServer},${SplunkPassword}) -Wait
} Else {
    Write-Host "Splunk is already installed. Moving on."
}
If ((Get-Service -name splunkforwarder).Status -ne "Running")
{
    throw "Splunk forwarder service not running"
}
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Splunk installation complete!"