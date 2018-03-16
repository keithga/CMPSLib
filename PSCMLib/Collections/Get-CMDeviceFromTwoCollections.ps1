
function Get-CMDeviceFromTwoCollections {
    <#
    Return an object containing the system, and any collection it belongs to.
    #>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $CollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $CollectionID,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('StripeName')] 
        [string]    $StripeCollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('StripeID')] 
        [string]    $StripeCollectionID

    )

    # Construct the connection arguments
    $WmiArgs = Get-CMSiteForWMI @PSBoundParameters
    $wmiargs | out-string -Width 200 | write-verbose

    ##############

    if ( $CollectionName -and $StripeCollectionName ) {
        $Query = @"
SELECT SMS_FullCollectionMembership.* 
FROM SMS_FullCollectionMembership, SMS_Collection
WHERE SMS_Collection.Name LIKE '{1}' AND SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID AND SMS_FullCOllectionMembership.ResourceID in (
    SELECT SMS_FullCollectionMembership.ResourceID
    FROM SMS_FullCollectionMembership, SMS_Collection 
    WHERE SMS_Collection.Name LIKE '{0}' AND SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID 
)
"@  -f $CollectionName,$StripeCollectionName
    }
    else {
        $Query = @"
SELECT SMS_FullCollectionMembership.* 
FROM SMS_FullCollectionMembership, SMS_Collection
WHERE SMS_Collection.CollectionID = '{1}' AND SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID AND SMS_FullCOllectionMembership.ResourceID in (
    SELECT SMS_FullCollectionMembership.ResourceID
    FROM SMS_FullCollectionMembership, SMS_Collection 
    WHERE SMS_Collection.CollectionID = '{0}' AND SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID 
)
"@  -f $CollectionID,$StripeCollectionID
    }

    GWMI @WMIArgs -query $Query | Select-Object -Property Name,ResourceID
}
