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



#endregion


<#

# Process Flow

## PreAssessment

- Query: PreAssessment Query
- Success: Move to PreCache_Compat_Scan
- Failure: Do nothing (FAILURE) - TBD Future

## PreCache_Compat_Scan

- Query: PreCache_Compat_Scan Query - TS Status Lookup, et. al.
- Success: Move to Ready_For_Scheduling
- Failure: Do nothing (FAILURE) - TBD Future

## Ready_For_Scheduling

- Query: (None Manual)
- Success: Move to Day_XX
- Failure: (None)

## DAY_XX

- Query: TS Query - TS Status Lookup, et. al.
- Success: Move to Finished
- Failure: Do nothing (FAILURE) - TBD Future

## Finished 

- Query: (None)
- Success: (None)
- Failure: (None)


#>