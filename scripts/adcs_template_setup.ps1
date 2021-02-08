Function newOid {
    param ($ConfigContext)
    $Hex = '0123456789ABCDEF'
    do {
        $oid = [ADSI]"LDAP://CN=OID,CN=Public Key Services,CN=Services,$ConfigContext" 
        $oidforest = $oid.'msPKI-Cert-Template-OID'
        $oid1 = Get-Random -Minimum 1000000  -Maximum 99999999
        $oid2 = Get-Random -Minimum 10000000 -Maximum 99999999
        $oid3 = $null
        For ($i=1;$i -le 32;$i++) {$oid3 += $Hex.Substring((Get-Random -Minimum 0 -Maximum 16),1)}
        $Name = "$oid2.$oid3"
        $msPKICertTemplateOID = "$oidforest.$oid1.$oid2"
    } until (($($oid.psbase.children | where { $_.cn -eq $Name -and $_.'msPKI-Cert-Template-OID' -eq $msPKICertTemplateOID }).Count -eq 0))
    Return @{
        oid  = $msPKICertTemplateOID
        name = $Name
    }
  }
  Function addTemplateAcl{
  param($Template, $User, $Read, $Enroll, $AutoEnroll)
      $user = New-Object System.Security.Principal.NTAccount($User)
      $enrollGuid = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
      $autoenrollGuid = [GUID]'a05b8cc2-17bc-4802-a710-e7c15ab866a2'
      $readGuid = [System.DirectoryServices.ActiveDirectoryRights] "GenericRead"
      $inheritedType = [GUID]'00000000-0000-0000-0000-000000000000'
      $allow = [System.Security.AccessControl.AccessControlType]"Allow"
      if($Enroll) { $Template.ObjectSecurity.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, 'ExtendedRight', $allow, $enrollGuid, 'None', $inheritedType)) }
      if($AutoEnroll) { $Template.ObjectSecurity.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, 'ExtendedRight', $allow, $autoenrollGuid, 'None', $inheritedType)) }
      if($Read) { $Template.ObjectSecurity.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, $readGuid, $allow, $inheritedType)) }
      $Template.commitchanges()

      return @{
          Template = $Template
      }
  }
  Function copyTemplate{
  param($NewTemplateName, $SourceTemplateName, $ConfigContext)
      $ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
      $st = $ADSI.psbase.children | where {$_.displayName -eq $SourceTemplateName}
      $oid = newOid -ConfigContext $ConfigContext
      $t = $ADSI.Create("pKICertificateTemplate", ("CN={0}" -f $oid.name)) 
      $t.put("distinguishedName",("CN={0},CN=Certificate Templates,CN=Public Key Services,CN=Services,{1}" -f $oid.name,$ConfigContext))         
      $t.put("flags","131680")
      $t.put("displayName",$NewTemplateName)
      $t.put("revision","100")
      $t.put("pKIDefaultKeySpec","1")
      $t.SetInfo()
      $t.put("pKIMaxIssuingDepth","0")
      $t.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")
      $t.put("msPKI-RA-Signature","0")
      $t.put("msPKI-Minimal-Key-Size","2048")
      $t.put("msPKI-Template-Schema-Version","2")
      $t.put("msPKI-Template-Minor-Revision","0")
      $t.put("msPKI-Cert-Template-OID",$oid.oid)
      $t.putex(3,"msPKI-Certificate-Application-Policy",@("1.3.6.1.5.5.7.3.1","1.3.6.1.5.5.7.3.2"))
      $t.SetInfo()
      $t.ObjectSecurity.SetAccessRuleProtection($st.ObjectSecurity.AreAccessRulesProtected, $false)
      $t.ObjectSecurity.Access | % {
          $t.ObjectSecurity.RemoveAccessRule($_)
      }
      $t.commitchanges()
      $st.ObjectSecurity.Access | % {
          $t.ObjectSecurity.AddAccessRule($_)
      }
      $t.commitchanges()
      $t.pKIKeyUsage = $st.pKIKeyUsage
      $t.pKIExpirationPeriod = $st.pKIExpirationPeriod
      $t.pKIOverlapPeriod = $st.pKIOverlapPeriod
      $t.SetInfo()

      return @{
          Template = $t
      }
  }
  Function publishTemplate{
  param($Template, $ConfigContext)
      $adsi = [ADSI]"LDAP://CN=Enrollment Services,CN=Public Key Services,CN=Services,$ConfigContext"
      $adsi.psbase.children | % { 
          $_.putex(3,'certificateTemplates',@($Template.Name))
          $_.commitchanges()
      }
  }

  $cc = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
  $t = copyTemplate -NewTemplateName "Web Server Policy" -SourceTemplateName "Web Server" -ConfigContext $cc
  $t.Template.putex(3,"pKICriticalExtensions",@("2.5.29.7","2.5.29.15"))
  $t.Template.putex(3,"pKIExtendedKeyUsage",@("1.3.6.1.5.5.7.3.1","1.3.6.1.5.5.7.3.2"))
  $t.Template.put("msPKI-Enrollment-Flag","0")
  $t.Template.put("msPKI-Private-Key-Flag","16842752")
  $t.Template.put("msPKI-Certificate-Name-Flag","1")
  $t.Template.SetInfo()
  publishTemplate -Template $t.Template -ConfigContext $cc

  $t = copyTemplate -NewTemplateName "RAS and IAS Server Policy" -SourceTemplateName "RAS and IAS Server" -ConfigContext $cc
  $t.Template.put("pKICriticalExtensions","2.5.29.15")
  $t.Template.putex(3,"pKIExtendedKeyUsage",@("1.3.6.1.5.5.7.3.1","1.3.6.1.5.5.7.3.2"))
  $t.Template.put("msPKI-Enrollment-Flag","32")
  $t.Template.put("msPKI-Private-Key-Flag","0")
  $t.Template.put("msPKI-Certificate-Name-Flag","-2013265920")
  $t.Template.SetInfo()
  $t = addTemplateAcl -Template $t.Template -User "RAS and IAS Servers" -Read $true -Enroll $true -AutoEnroll $true
  publishTemplate -Template $t.Template -ConfigContext $cc
  
  "Workstation Authentication","Domain Controller Authentication" | % { 
    $t = copyTemplate -NewTemplateName "$_ Policy" -SourceTemplateName $_ -ConfigContext $cc
    $t.Template.put("pKICriticalExtensions",$p)
    $t.Template.putex(3,"pKIExtendedKeyUsage",@("1.3.6.1.5.5.7.3.1","1.3.6.1.5.5.7.3.2"))
    $t.Template.put("msPKI-Enrollment-Flag","32")
    $t.Template.put("msPKI-Private-Key-Flag","67371264")
    $t.Template.put("msPKI-Certificate-Name-Flag","-2013265920")
    $t.Template.SetInfo()
    if($_ -eq "Workstation Authentication") { $t = addTemplateAcl -Template $t.Template -User "Domain Computers" -Read $true -Enroll $true -AutoEnroll $true }
    publishTemplate -Template $t.Template -ConfigContext $cc
  }
  
  restart-service certsvc