param(
    [Parameter(Mandatory=$true,Position=0,HelpMessage="Splunk Local Password")]
    [string]$SplunkPassword,
    
    [Parameter(Mandatory=$true,Position=1,HelpMessage="Splunk Deployment Server Hostname")]
    [string]$SplunkDeploymentServer
)

If (-not (Test-Path "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe")) {
    Write-Host "Downloading Splunk Universal Forwarder"
    $msiFile = $env:Temp + "\splunkforwarder-8.2.0-e053ef3c985f-x64-release.msi"

    Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Installing & Starting Splunk"
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    (New-Object System.Net.WebClient).DownloadFile('https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=windows&version=8.2.0&product=universalforwarder&filename=splunkforwarder-8.2.0-e053ef3c985f-x64-release.msi&wget=true', $msiFile)
    Start-Process -FilePath "c:\windows\system32\msiexec.exe" -ArgumentList '/i', "$msiFile", $('DEPLOYMENT_SERVER="{0}:8089"  AGREETOLICENSE=Yes SERVICESTARTTYPE=auto LAUNCHSPLUNK=1 SPLUNKPASSWORD="{1}" /quiet' -f ${SplunkDeploymentServer},${SplunkPassword}) -Wait
} Else {
    Write-Host "Splunk is already installed. Moving on."
}
If ((Get-Service -name splunkforwarder).Status -ne "Running")
{
    throw "Splunk forwarder service not running"
}
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Splunk installation complete!"