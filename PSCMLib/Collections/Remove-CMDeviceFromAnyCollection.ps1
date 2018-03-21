
Function Remove-CMDeviceFromAnyCollection {

<#

Get-CMDeviceFromAnyCollection will return devices in the following way:

Name      ResourceID CollectionName             CollectionID
----      ---------- --------------             ------------
DTC000010   16777433 OSD_W10_Fall_Preassessment CHQ00033    
DTC000011   16777434 OSD_W10_Fall_Preassessment CHQ00033    
DTC000012   16777435 OSD_W10_Fall_Preassessment CHQ00033    
DTC000013   16777436 OSD_W10_Fall_Preassessment CHQ00033    
DTC000014   16777437 OSD_W10_Fall_Preassessment CHQ00033    
DTC000015   16777438 OSD_W10_Fall_Preassessment CHQ00033    
DTC000016   16777439 OSD_W10_Fall_Preassessment CHQ00033    
DTC000017   16777440 OSD_W10_Fall_Preassessment CHQ00033    
DTC000018   16777441 OSD_W10_Fall_Preassessment CHQ00033    
DTC000019   16777442 OSD_W10_Fall_Preassessment CHQ00033    
DTC000020   16777443 OSD_W10_Fall_Finished      CHQ00035    
DTC000021   16777444 OSD_W10_Fall_Finished      CHQ00035    
DTC000022   16777445 OSD_W10_Fall_Finished      CHQ00035    
DTC000023   16777446 OSD_W10_Fall_Finished      CHQ00035    
DTC000024   16777447 OSD_W10_Fall_Finished      CHQ00035    
DTC000025   16777448 OSD_W10_Fall_Finished      CHQ00035    
DTC000026   16777449 OSD_W10_Fall_Finished      CHQ00035    
DTC000027   16777450 OSD_W10_Fall_Finished      CHQ00035    
DTC000028   16777451 OSD_W10_Fall_Finished      CHQ00035    
DTC000029   16777452 OSD_W10_Fall_Finished      CHQ00035    

This script will group the collections, and remove each item for each group in bulk.

#>


    [CmdLetBinding(SupportsShouldProcess=$true)]
    Param(
        [parameter(Mandatory=$true,  ValueFromPipeline=$true)]
        # custom object from Get-DeviceFromAnyCollection, do not confuse with $System
        $AnySystem

    )

    process {

        $AnySystem |
            Group-Object -Property CollectionID | 
            ForEach-Object {
                $_.Group | Remove-CMDeviceFromCollection -CollectionID $_.Name
            }
    }

}
