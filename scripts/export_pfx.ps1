# Script to export certificate from LocalMachine store along with private key
$Password = "@de08nt2128"; #password to access certificate after expting
$CertName = "WMSvc-WIN-9KC7DG31JBV"; # name of the certificate to export
$RootCertName = "WMSvc-WIN-9KC7DG31JBV"; # root certificate (the Issuer)
$ExportPathRoot = "C:\DestinationFolder"

$CertListToExport = Get-ChildItem -Path cert:\LocalMachine\My | ?{ $_.Subject -Like "*CN=$CertName*" -and $_.Issuer -Like "CN=$RootCertName*" }

foreach($CertToExport in $CertListToExport | Sort-Object Subject)
{
    # Destination Certificate Name should be CN. 
    # Since subject contains CN, OU and other information,
    # extract only upto the next comma (,)
    $DestCertName=$CertToExport.Subject.ToString().Replace("CN=","");
    $DestCertName = $DestCertName.Substring(0, $DestCertName.IndexOf(","));

    $CertDestPath = Join-Path -Path $ExportPathRoot -ChildPath "$DestCertName.pfx"

    $SecurePassword = ConvertTo-SecureString -String $Password -Force –AsPlainText

    # Export PFX certificate along with private key
    Export-PfxCertificate -Cert $CertToExport -FilePath $CertDestPath -Password $SecurePassword -Verbose
}