<#

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

$Query = @"
    WITH LastKnownStatus as (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY resourceID ORDER BY ExecutionTime DESC) as rn
        FROM [dbo].[v_TaskExecutionStatus]
    )

    SELECT col.Name as CollectionName,Col.CollectionID,Sys.ResourceID,Sys.Name0 as Name
    FROM LastKnownStatus LKS
    JOIN [dbo].[v_Advertisement] adv on adv.AdvertisementID = LKS.AdvertisementID
    JOIN [dbo].[v_collection] col on adv.CollectionID = col.CollectionID
    JOIN [dbo].[v_R_System] sys on LKS.ResourceID = sys.ResourceID
    WHERE rn = 1 AND ExecutionTime > DATEADD(Day, -40, getdate()) 
        AND col.Name LIKE '$(get-OSDW10Prefix)_%_Precache_Compat_Scan'
        AND LKS.LastStatusMessageID = 11143
"@

Write-Verbose ("Process OSD_W10_%_Precache_Compat_Scan to OSD_W10_*_Ready_For_Scheduling")
Invoke-SQLCMD -HostName $HostName -Database $Database -Query $Query | 
    Move-CMDeviceToCollectionFromAny -CollectionPostFix Ready_For_Scheduling -WhatIf:([bool]$WhatIfPreference.IsPresent)

