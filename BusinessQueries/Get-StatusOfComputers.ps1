[cmdletbinding()]
param(
    $HostName,
    $Database
)
# Ready

Import-Module "$PSScriptRoot\..\PSCMLib" -force -ErrorAction SilentlyContinue 
if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }
if ( -not $hostName ) { $HostName = import-clixml $PSscriptRoot\Settings.clixml | % HostName } 
if ( -not $Database ) { $Database = import-clixml $PSscriptRoot\Settings.clixml | % Database } 
if ( -not $CfgPath ) { $CfgPath = import-clixml $PSscriptRoot\Settings.clixml | % Path } 
 
###############################################################################

write-host ('*' * 80)

get-childitem filesystem::$CfgPath\moveToDay\*\*.clixml -exclude Error,Done -EA SilentlyContinue | 
    foreach-object {
        write-verbose $_.FullName
        $Blob = $null
        $Blob = import-clixml "filesystem::$($_.FullName)"
        $Blob.Add('File',$_.Name)
        $Blob | out-string -width 120 | write-host 
        write-host ('*' * 80)
    }

###############################################################################
write-host ('*' * 80)

$QUery = @"
WITH WAASCollection as ( 
    SELECT CollectionID 
        ,case 
            WHEN col.Name LIKE 'OSD_W10_Fall_PreAssessment' THEN ('1. ' + Col.Name )
            WHEN col.Name LIKE 'OSD_W10_Fall_PreCache_Compat_Scan' THEN ('2. ' + Col.Name ) 
            WHEN col.Name LIKE 'OSD_W10_Fall_Ready_For_Scheduling_%' THEN ( '3>     ' + Col.Name )
            WHEN col.Name LIKE 'OSD_W10_Fall_Ready_For_Scheduling' THEN ( '3. ' + Col.Name )
            WHEN col.Name LIKE 'OSD_W10_Fall_Day_%' THEN ( '4>     ' + Col.Name )
            WHEN col.Name LIKE 'OSD_W10_Finished' THEN ( '5. ' + Col.Name )
            else ( '9. ' + Col.Name )
        end as nameX 
    FROM [CM_CAS].[dbo].v_Collection as col 
    WHERE ( Name LIKE 'OSD_W10_Fall_%' AND Name <> '') 
) 
SELECT 
      Col.[namex] as State
      ,count(*) as Count
  FROM [CM_CAS].[dbo].[v_FullCollectionMembership] fcm 
  JOIN WAASCollection col ON col.CollectionID = fcm.CollectionID 
  Group by col.nameX

"@

Invoke-SQLCMD -Query $Query -HostName $HostName -database $Database | 
    ? NameX -notIn 'OSD_W10_Fall_Available_On_Demand','OSD_W10_Fall_Ready_for_Scheduling' |
    Sort -Property State |
    FT 
