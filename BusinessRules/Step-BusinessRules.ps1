<#

#>

[cmdletbinding()]
param(
    $hostname,
    $Database
)

#region Rule - Move Business Group Ready For PreAssessment to PreAssessment

foreach ( $Collection in Get-CMCollection -CollectionType Device -Name 'OSD_W10_*_Ready_for_PreAssessment' | % Name ) { 

    # Get the base name of the Collection, and 
    $PreAssess = $Collection | Get-CMCollectionBusinessName -postFix 'PreAssessment'
    Get-CMDevice -CollectionName $Collection | 
        Move-CMDeviceToCollection -FromCollectionName $Collection -ToCollectionName $PreAssess
}

#endregion

#region Rule - Process PreAssessments and move to PreCache_Compat_Scan if pass!

# TBD - External Rules...

#endregion

#region Rule - Process PreCache_Compat_Scan and move toe REady for Scheduling if pass!

$PreCacheSQL = @"
WITH LastKnownStatus as (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY resourceID ORDER BY ExecutionTime DESC) as rn
    FROM [dbo].[v_TaskExecutionStatus]
)

SELECT col.Name,LKS.ResourceID
FROM LastKnownStatus LKS
JOIN [dbo].[v_Advertisement] adv on adv.AdvertisementID = LKS.AdvertisementID
JOIN [dbo].[v_collection] col on adv.CollectionID = col.CollectionID
WHERE rn = 1 AND ExecutionTime > DATEADD(Day, -40, getdate()) 
    AND col.Name LIKE 'OSD_W10_{0}_Precache_Compat_Scan'
    AND LKS.LastStatusMessageID = 11143
"@

foreach ( $Group in 'Fall_x64','Spring_x64') {

    Write-Verbose ("Process OSD_W10_{0}_Precache_Compat_Scan to OSD_W10_{0}_Ready_For_Scheduling" -f $Group)
    Invoke-SQLCMD @PSBoundParameters -Query $Query -args $Group | 
        Move-CMDeviceToCollection -FromCollectionName ('OSD_W10_{0}_Precache_Compat_Scan' -f $Group) -ToCollectionName ('OSD_W10_{0}_Ready_For_Scheduling' -f $Group)

}

#endregion

#region Rule - Ready for scheduling

# TBD - XXX

#endregion

#region Rule - Process PreCache_Compat_Scan and move toe REady for Scheduling if pass!

$PreCacheSQL = @"
WITH LastKnownStatus as (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY resourceID ORDER BY ExecutionTime DESC) as rn
    FROM [dbo].[v_TaskExecutionStatus]
)

SELECT col.Name,LKS.ResourceID
FROM LastKnownStatus LKS
JOIN [dbo].[v_Advertisement] adv on adv.AdvertisementID = LKS.AdvertisementID
JOIN [dbo].[v_collection] col on adv.CollectionID = col.CollectionID
WHERE rn = 1 AND ExecutionTime > DATEADD(Day, -40, getdate()) 
    AND col.Name LIKE 'OSD_W10_{0}_Day_%'
    AND LKS.LastStatusMessageID = 11143
"@

foreach ( $Group in 'Fall_x64','Spring_x64') {

    Write-Verbose ("Process OSD_W10_{0}_DAY_XX_PM to OSD_W10_{0}_Finished" -f $Group)
    Invoke-SQLCMD @PSBoundParameters -Query $Query -args $Group | 
        Move-CMDeviceToCollection -FromCollectionName ('OSD_W10_{0}_DAY_XXXBADBADBAD!!!' -f $Group) -ToCollectionName ('OSD_W10_{0}_Finished' -f $Group)

    # TBD, need to group the Collection names, so we can move them from the right date

}

#endregion

