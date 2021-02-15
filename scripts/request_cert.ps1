$CACommonName="LAB-CA"
$pem = $true

$SAN = "dns=splk-uf1.lab.lan"
$CN = "splk-uf1.lab.lan"
$County = "Canada"
$State = "BC"
$City = "Vancouver"
$Organisation = "LAB"
$OU = "LAB"
$SourceTemplateName = "Web Server Policy"

$cc = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$cc"
$st = $ADSI.psbase.children | where {$_.displayName -eq $SourceTemplateName}
$TemplateName = $st.Name

Write-output $TemplateName

function Remove-ReqTempfiles() {
    param(
        [String[]]$tempfiles
    )
    Write-Verbose "Cleanup temp files..."
    Remove-Item -Path $tempfiles -Force -ErrorAction SilentlyContinue
}

function Remove-ReqFromStore {
    param(
        [String]$CN
    )
    Write-Verbose "Remove pending certificate request form cert store..."

    #delete pending request (if a request exists for the CN)
    $certstore = new-object system.security.cryptography.x509certificates.x509Store('REQUEST', 'LocalMachine')
    $certstore.Open('ReadWrite')
    foreach ($certreq in $($certstore.Certificates)) {
        if ($certreq.Subject -eq "CN=$CN") {
            $certstore.Remove($certreq)
        }
    }
    $certstore.close()
}


# create request
$file = @"
[NewRequest]
Subject = "CN=$CN,c=$Country, s=$State, l=$City, o=$Organisation, ou=$Department"
MachineKeySet = TRUE
KeyLength = 2048
KeySpec=1
Exportable = TRUE
RequestType = PKCS10
ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0"
[RequestAttributes]
CertificateTemplate = "$TemplateName"
"@

#check if SAN certificate is requested
if ($SAN -ne $null) {
    #each SAN must be a array element
    #if the array has ony one element then split it on the commas.
    if (($SAN).count -eq 1) {
        $SAN = @($SAN -split ',')

        Write-Host "Requesting SAN certificate with subject $CN and SAN: $($SAN -join ',')" -ForegroundColor Green
        Write-Debug "Parameter values: CN = $CN, TemplateName = $TemplateName, CAName = $CACommonName, SAN = $($SAN -join ' ')"
    }

    Write-Verbose "A value for the SAN is specified. Requesting a SAN certificate."
    Write-Debug "Add Extension for SAN to the inf file..."
    $file += @'

[Extensions]
; If your client operating system is Windows Server 2008, Windows Server 2008 R2, Windows Vista, or Windows 7
; SANs can be included in the Extensions section by using the following text format. Note 2.5.29.17 is the OID for a SAN extension.

2.5.29.17 = "{text}"

'@

    foreach ($an in $SAN) {
        $file += "_continue_ = `"$($an)&`"`n"
    }
}

$inf = [System.IO.Path]::GetTempFileName()
$req = [System.IO.Path]::GetTempFileName()
$cer = Join-Path -Path 'C:\Temp' -ChildPath "$CN.cer"
$rsp = Join-Path -Path 'C:\Temp' -ChildPath "$CN.rsp"

Remove-ReqTempfiles -tempfiles $inf, $req, $cer, $rsp
#create new request inf file
Set-Content -Path $inf -Value $file

#show inf file if -verbose is used
Get-Content -Path $inf | Write-Verbose

Write-Verbose "generate .req file with certreq.exe"
Invoke-Expression -Command "certreq -new `"$inf`" `"$req`""
if (!($LastExitCode -eq 0)) {
    throw "certreq -new command failed"
}

$rootDSE = [System.DirectoryServices.DirectoryEntry]'LDAP://RootDSE'
$searchBase = [System.DirectoryServices.DirectoryEntry]"LDAP://$($rootDSE.configurationNamingContext)"
$CAs = [System.DirectoryServices.DirectorySearcher]::new($searchBase,'objectClass=pKIEnrollmentService').FindAll()

if($CAs.Count -gt 0){
    $CAName = "$($CAs[0].Properties.dnshostname)\$($CAs[0].Properties.cn)"
}
else {
    $CAName = ""
}

if (!$CAName -eq "") {
    $CAName = " -config `"$CAName`""
}


Write-output "certreq -submit$CAName `"$req`" `"$cer`""
Invoke-Expression -Command "certreq -submit$CAName `"$req`" `"$cer`""

if (!($LastExitCode -eq 0)) {
    throw "certreq -submit command failed"
}
Write-output "request was successful. Result was saved to `"$cer`""

write-output "retrieve and install the certificate"
Invoke-Expression -Command "certreq -accept `"$cer`""

if (!($LastExitCode -eq 0)) {
    throw "certreq -accept command failed"
}

if (($LastExitCode -eq 0) -and ($? -eq $true)) {
    Write-Host "Certificate request successfully finished!" -ForegroundColor Green

}
else {
    throw "Request failed with unknown error. Try with -verbose -debug parameter"
}

$cert = Get-Childitem "cert:\LocalMachine\My" | where-object {$_.Thumbprint -eq (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Get-Item $cer).FullName, "")).Thumbprint}

#create a pfx export as a byte array
$certbytes = $cert.export([System.Security.Cryptography.X509Certificates.X509ContentType]::pfx)
$pfxPath = "C:\Temp\$CN.pfx"

$certbytes | Set-Content -Encoding Byte -Path $pfxPath -ea Stop
Write-Host "Certificate successfully exported to `"$pfxPath`"!" -ForegroundColor Green

Write-Verbose "deleting exported certificate from computer store"

# delete certificate from computer store
$certstore = new-object system.security.cryptography.x509certificates.x509Store('My', 'LocalMachine')
$certstore.Open('ReadWrite')
$certstore.Remove($cert)
$certstore.close()

Remove-ReqTempfiles -tempfiles $inf, $req, $cer, $rsp
Remove-ReqFromStore -CN $CN

# export root cert pem file
$a = Get-ChildItem -Path cert:\LocalMachine\My | where {$_.Subject -like "CN=$CACommonName*"} 
$cert_bytes = $a.Export( [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

if($pem -eq $true){
    $cert_content = "-----BEGIN CERTIFICATE-----`r`n"
    $base64_string = [System.Convert]::ToBase64String($cert_bytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    $cert_content += $base64_string
    $cert_content += "`r`n-----END CERTIFICATE-----"
    $file_encoding = [System.Text.Encoding]::ASCII
    $cert_bytes = $file_encoding.GetBytes($cert_content)
}

[io.file]::WriteAllBytes("C:\Temp\$CACommonName.pem",$cert_bytes)

###########################
# Configuration for Splunk
###########################

# extract key from pfx
#openssl pkcs12 -in [yourfile.pfx] -nocerts -out [keyfile-encrypted.key]

# remove pass (required for splunk)
#openssl rsa -in [keyfile-encrypted.key] -out [keyfile.key]

# extract cer from pfx
#openssl pkcs12 -in [yourfile.pfx] -clcerts -nokeys -out [certificate.crt]

# create serverCert pem
# openssl rsa -in [keyfile-encrypted.key] -aes256 -passout pass:password  -out [key-encrypted-pem.pem]

# bundle
# cat [certificate.crt] [key-encrypted-pem.pem] [ca-certificate.pem]

# etc/system/local/web.conf
# -------------------------
# [settings]
# enableSplunkWebSSL = True
# serverCert = etc/auth/splunkweb/splunk.pem
# privKeyPath = etc/auth/splunkweb/splunk.key
#
# etc/system/local/server.conf
# ----------------------------
# [sslConfig]
# sslPassword = $7$KicnrY+lE3mabYnGN69ZbUWPKlgHo/g4nBNx7KStomrRKWkdPamhCg==
# serverCert = splunk.pem
# sslRootCAPath = /opt/splunk/etc/auth/labCA.pem



