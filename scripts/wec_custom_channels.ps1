$ProgressPreference='SilentlyContinue' #for faster download
#Download Windows 8.1 SDK - only needed for ecmangen.exe (Last SDK where ecmangen was present is Windows 10 SDK ver. 10.0.15063. 8.1 can coexist with 10)
#Invoke-WebRequest -UseBasicParsing -Uri https://go.microsoft.com/fwlink/p/?LinkId=323507 -OutFile "$env:USERPROFILE\Downloads\SDK81_Setup.exe"
#Install SDK 8.1
#Start-Process -Wait -FilePath "$env:USERPROFILE\Downloads\SDK81_Setup.exe" -ArgumentList "/features OptionID.WindowsDesktopSoftwareDevelopmentKit /quiet"
 
#Download Windows 10 RS5 SDK
Invoke-WebRequest -UseBasicParsing -Uri https://go.microsoft.com/fwlink/p/?LinkID=2033908 -OutFile "$env:USERPROFILE\Downloads\SDKRS5_Setup.exe"
#Install SDK RS5
Start-Process -Wait -FilePath "$env:USERPROFILE\Downloads\SDKRS5_Setup.exe" -ArgumentList "/features OptionId.DesktopCPPx64 /quiet"


#Create Man file or run setup
 
#Manifest Generator GUI Tool - only in SDK 8.1
#Start-Process -FilePath "C:\Program Files (x86)\Windows Kits\8.1\bin\x64\ecmangen.exe"
 
#or create file
#Variables
$CustomEventChannelsFileName="CustomEventChannels"
$OutputFolder="$env:UserProfile\Downloads\ECMan"

#some neccessaries
$ManifestFileName = '{0}.man' -f $CustomEventChannelsFileName
$ResourceFileName = 'C:\Windows\system32\{0}.dll' -f $CustomEventChannelsFileName
$message = '$(string.Custom Forwarded Events.event.100.message)' 

#Events definition
$EventsArray = @(
    @{
        EventProviderName = 'WEC'
        EventGuid = New-Guid
        EventSymbol = 'WEC_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C1'
        Channels = @(
            @{
                ChannelName = 'WEC-Powershell'
                ChannelchID = 'WEC-Powershell'
                ChannelSymbol = 'WEC-Powershell'
            },
            @{
                ChannelName = 'WEC-WMI'
                ChannelchID = 'WEC-WMI'
                ChannelSymbol = 'WEC-WMI'
            },
            @{
                ChannelName = 'WEC-Authentication'
                ChannelchID = 'WEC-Authentication'
                ChannelSymbol = 'WEC-Authentication'
            },
            @{
                ChannelName = 'WEC-Services'
                ChannelchID = 'WEC-Services'
                ChannelSymbol = 'WEC-Services'
            },
            @{
                ChannelName = 'WEC-Process-Execution'
                ChannelchID = 'WEC-Process-Execution'
                ChannelSymbol = 'WEC-Process-Execution'
            },
             @{
                ChannelName = 'WEC-Code-Integrity'
                ChannelchID = 'WEC-Code-Integrity'
                ChannelSymbol = 'WEC-Code-Integrity'
            }
        )
    },
    @{
        EventProviderName = 'WEC2'
        EventGuid = New-Guid
        EventSymbol = 'WEC2_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C2'
        Channels = @(
            @{
                ChannelName = 'WEC2-Registry'
                ChannelchID = 'WEC2-Registry'
                ChannelSymbol = 'WEC2-Registry'
            },
            @{
                ChannelName = 'WEC2-Applocker'
                ChannelchID = 'WEC2-Applocker'
                ChannelSymbol = 'WEC2-Applocker'
            },
            @{
                ChannelName = 'WEC2-Task-Scheduler'
                ChannelchID = 'WEC2-Task-Scheduler'
                ChannelSymbol = 'WEC2-Task-Scheduler'
            },
            @{
                ChannelName = 'WEC2-Application-Crashes'
                ChannelchID = 'WEC2-Application-Crashes'
                ChannelSymbol = 'WEC2-Application-Crashes'
            },
            @{
                ChannelName = 'WEC2-Windows-Defender'
                ChannelchID = 'WEC2-Windows-Defender'
                ChannelSymbol = 'WEC2-Windows-Defender'
            },
            @{
                ChannelName = 'WEC2-Group-Policy-Errors'
                ChannelchID = 'WEC2-Group-Policy-Errors'
                ChannelSymbol = 'WEC-Group-Policy-Errors'
            },
            @{
                ChannelName = 'WEC2-Object-Manipulation'
                ChannelchID = 'WEC2-Object-Manipulation'
                ChannelSymbol = 'WEC2-Object-Manipulation'
            }
        )
    },
    @{
        EventProviderName = 'WEC3'
        EventGuid = New-Guid
        EventSymbol = 'WEC3_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C3'
        Channels = @(
            @{
                ChannelName = 'WEC3-Drivers'
                ChannelchID = 'WEC3-Drivers'
                ChannelSymbol = 'WEC3-Drivers'
            },
            @{
                ChannelName = 'WEC3-Account-Management'
                ChannelchID = 'WEC3-Account-Management'
                ChannelSymbol = 'WEC3-Account-Management'
            },
            @{
                ChannelName = 'WEC3-Windows-Diagnostics'
                ChannelchID = 'WEC3-Windows-Diagnostics'
                ChannelSymbol = 'WEC3-Windows-Diagnostics'
            },
            @{
                ChannelName = 'WEC3-Smart-Card'
                ChannelchID = 'WEC3-Smart-Card'
                ChannelSymbol = 'WEC3-Smart-Card'
            },
            @{
                ChannelName = 'WEC3-Print'
                ChannelchID = 'WEC3-Print'
                ChannelSymbol = 'WEC3-Print'
            },
            @{
                ChannelName = 'WEC3-Firewall'
                ChannelchID = 'WEC3-Firewall'
                ChannelSymbol = 'WEC3-Firewall'
            },
            @{
                ChannelName = 'WEC3-External-Devices'
                ChannelchID = 'WEC3-External-Devices'
                ChannelSymbol = 'WEC3-External-Devices'
            }
        )
    },
    @{
        EventProviderName = 'WEC4'
        EventGuid = New-Guid
        EventSymbol = 'WEC4_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C4'
        Channels = @(
            @{
                ChannelName = 'WEC4-Wireless'
                ChannelchID = 'WEC4-Wireless'
                ChannelSymbol = 'WEC4-Wireless'
            },
            @{
                ChannelName = 'WEC4-Shares'
                ChannelchID = 'WEC4-Shares'
                ChannelSymbol = 'WEC4-Shares'
            },
            @{
                ChannelName = 'WEC4-Bits-Client'
                ChannelchID = 'WEC4-Bits-Client'
                ChannelSymbol = 'WEC4-Bits-Client'
            },
            @{
                ChannelName = 'WEC4-Windows-Updates'
                ChannelchID = 'WEC4-Windows-Updates'
                ChannelSymbol = 'WEC4-Windows-Updates'
            },
            @{
                ChannelName = 'WEC4-Hotpatching-Errors'
                ChannelchID = 'WEC4-Hotpatching-Errors'
                ChannelSymbol = 'WEC4-Hotpatching-Errors'
            },
            @{
                ChannelName = 'WEC4-DNS'
                ChannelchID = 'WEC4-DNS'
                ChannelSymbol = 'WEC4-DNS'
            },
            @{
                ChannelName = 'WEC4-System-Time-Change'
                ChannelchID = 'WEC4-System-Time-Change'
                ChannelSymbol = 'WEC4-System-Time-Change'
            }
        )
    },
    @{
        EventProviderName = 'WEC5'
        EventGuid = New-Guid
        EventSymbol = 'WEC5_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C5'
        Channels = @(
            @{
                ChannelName = 'WEC5-Operating-System'
                ChannelchID = 'WEC5-Operating-System'
                ChannelSymbol = 'WEC5-Operating-System'
            },
            @{
                ChannelName = 'WEC5-Certificate-Authority'
                ChannelchID = 'WEC5-Certificate-Authority'
                ChannelSymbol = 'WEC5-Certificate-Authority'
            },
            @{
                ChannelName = 'WEC5-Crypto-API'
                ChannelchID = 'WEC5-Crypto-API'
                ChannelSymbol = 'WEC5-Crypto-API'
            },
            @{
                ChannelName = 'WEC5-MSI-Packages'
                ChannelchID = 'WEC5-MSI-Packages'
                ChannelSymbol = 'WEC5-MSI-Packages'
            },
            @{
                ChannelName = 'WEC5-Log-Deletion-Security'
                ChannelchID = 'WEC5-Log-Deletion-Security'
                ChannelSymbol = 'WEC5-Log-Deletion-Security'
            },
            @{
                ChannelName = 'WEC5-Log-Deletion-System'
                ChannelchID = 'WEC5-Log-Deletion-System'
                ChannelSymbol = 'WEC5-Log-Deletion-System'
            },
            @{
                ChannelName = 'WEC5-Autoruns'
                ChannelchID = 'WEC5-Autoruns'
                ChannelSymbol = 'WEC5-Autoruns'
            }
        )
    },
    @{
        EventProviderName = 'WEC6'
        EventGuid = New-Guid
        EventSymbol = 'WEC6_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C6'
        Channels = @(
            @{
                ChannelName = 'WEC6-Software-Restriction-Policies'
                ChannelchID = 'WEC6-Software-Restriction-Policies'
                ChannelSymbol = 'WEC6-Software-Restriction-Policies'
            },
            @{
                ChannelName = 'WEC6-ADFS'
                ChannelchID = 'WEC6-ADFS'
                ChannelSymbol = 'WEC6-ADFS'
            },
            @{
                ChannelName = 'WEC6-Device-Guard'
                ChannelchID = 'WEC6-Device-Guard'
                ChannelSymbol = 'WEC6-Device-Guard'
            },
            @{
                ChannelName = 'WEC6-Duo-Security'
                ChannelchID = 'WEC6-Duo-Security'
                ChannelSymbol = 'WEC6-Duo-Security'
            },
            @{
                ChannelName = 'WEC6-Microsoft-Office'
                ChannelchID = 'WEC6-Microsoft-Office'
                ChannelSymbol = 'WEC6-Microsoft-Office'
            },
            @{
                ChannelName = 'WEC6-Exploit-Guard'
                ChannelchID = 'WEC6-Exploit-Guard'
                ChannelSymbol = 'WEC6-Exploit-Guard'
            },
            @{
                ChannelName = 'WEC6-Sysmon'
                ChannelchID = 'WEC6-Sysmon'
                ChannelSymbol = 'WEC6-Sysmon'
            }
        )
    },
    @{
        EventProviderName = 'WEC7'
        EventGuid = New-Guid
        EventSymbol = 'WEC7_EVENTS'
        EventResourceFileName = $ResourceFileName
        ImportChannelID='C7'
        Channels = @(
            @{
                ChannelName = 'WEC7-Active-Directory'
                ChannelchID = 'WEC7-Active-Directory'
                ChannelSymbol = 'WEC7-Active-Directory'
            },
            @{
                ChannelName = 'WEC7-Terminal-Services'
                ChannelchID = 'WEC7-Terminal-Services'
                ChannelSymbol = 'WEC7-Terminal-Services'
            },
            @{
                ChannelName = 'WEC7-Privilege-Use'
                ChannelchID = 'WEC7-Privilege-Use'
                ChannelSymbol = 'WEC7-Privilege-Use'
            }
        )
    }
)

#Generate XML
$EventsArrayFinal = foreach ($Event in $EventsArray) {
    $channels = foreach ($channel in $Event.Channels) {
    @"

                    <channel name="$($Channel.ChannelName)" chid="$($Channel.ChannelchID)" symbol="$($Channel.ChannelSymbol)" type="Operational" enabled="true"></channel>
"@
    }
    @"

            <provider name="$($Event.EventProviderName)" guid="{$($Event.EventGUID)}" symbol="$($Event.EventSymbol)" resourceFileName="$($Event.EventResourceFileName)" messageFileName="$($Event.EventResourceFileName)">
                <events>
                    <event symbol="DUMMY_EVENT" value="100" version="0" template="DUMMY_TEMPLATE" message="$message"></event>
                </events>
                <channels>
                    <importChannel name="System" chid="$($Event.ImportChannelID)"></importChannel>$channels
                </channels>
                <templates>
                    <template tid="DUMMY_TEMPLATE">
                        <data name="Prop_UnicodeString" inType="win:UnicodeString" outType="xs:string"></data>
                        <data name="PropUInt32" inType="win:UInt32" outType="xs:unsignedInt"></data>
                    </template>
                </templates>
            </provider>
"@
}
$Content=@"
<?xml version="1.0"?>
<instrumentationManifest xsi:schemaLocation="http://schemas.microsoft.com/win/2004/08/events eventman.xsd" xmlns="http://schemas.microsoft.com/win/2004/08/events" xmlns:win="http://manifests.microsoft.com/win/2004/08/windows/events" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:trace="http://schemas.microsoft.com/win/2004/08/events/trace">
    <instrumentation>
        <events>$EventsArrayFinal
        </events>
    </instrumentation>
    <localization>
        <resources culture="en-US">
            <stringTable>
                <string id="level.Informational" value="Information"></string>
                <string id="channel.System" value="System"></string>
                <string id="Publisher.EventMessage" value="Prop_UnicodeString=%1;%n&#xA;                  Prop_UInt32=%2;%n"></string>
                <string id="Custom Forwarded Events.event.100.message" value="Prop_UnicodeString=%1;%n&#xA;                  Prop_UInt32=%2;%n"></string>
            </stringTable>
        </resources>
    </localization>
</instrumentationManifest>
"@

#Create output folder if does not exist
if(-not (Test-Path $OutputFolder)) { 
    New-Item -Path $OutputFolder -ItemType Directory
}

#write XML
Set-Content -Value $content -Path (Join-Path -Path $OutputFolder -ChildPath $ManifestFileName) -Encoding ASCII

#Compile manifest https://docs.microsoft.com/en-us/windows/desktop/WES/compiling-an-instrumentation-manifest
$CustomEventChannelsFileName="CustomEventChannels"
$OutputFolder="$env:UserProfile\Downloads\ECMan"
$ToolsPath="C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64"
$dotNetPath="C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
 
Start-Process -Wait -FilePath "$ToolsPath\mc.exe" -ArgumentList "$OutputFolder\$CustomEventChannelsFileName.man" -WorkingDirectory $OutputFolder
Start-Process -Wait -FilePath "$ToolsPath\mc.exe" -ArgumentList "-css CustomEventChannels.DummyEvent  $OutputFolder\$CustomEventChannelsFileName.man" -WorkingDirectory $OutputFolder
Start-Process -Wait -FilePath "$ToolsPath\rc.exe" -ArgumentList "$OutputFolder\$CustomEventChannelsFileName.rc"
Start-Process -Wait -FilePath "$dotNetPath\csc.exe" -ArgumentList "/win32res:$OutputFolder\$CustomEventChannelsFileName.res /unsafe /target:library /out:$OutputFolder\$CustomEventChannelsFileName.dll"

#Some variables
$CollectorServerName="Collector"
$CustomEventChannelsFileName="CustomEventChannels"
$CustomEventsFilesLocation="$env:UserProfile\Downloads\ECMan"
 
#configure Event Forwarding on collector server
WECUtil qc /q
 
#Create custom event forwarding logs
Stop-Service Wecsvc
#unload current event channnel (commented as there is no custom manifest)
#wevtutil um C:\windows\system32\CustomEventChannels.man
 
#copy new man and dll
$files="$CustomEventChannelsFileName.dll","$CustomEventChannelsFileName.man"
$Path="$CustomEventsFilesLocation"
foreach ($file in $files){
    Copy-Item -Path "$path\$file" -Destination C:\Windows\system32
}
#load new event channel file and start Wecsvc service
wevtutil im "C:\windows\system32\$CustomEventChannelsFileName.man"
Start-Service Wecsvc