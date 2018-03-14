
function Get-CMDeviceFromAnyCollectionn {
    <#
    Return an object containing the system, and any collection it belongs to.
    #>
    [cmdletbinding()]
    param (
        $System
    )

    # Construct the connection arguments
    $WmiArgs = Get-CMSiteForWMI @PSBoundParameters

    ##############

    $CollectionMembershipQuery = "SELECT SMS_Collection.*,SMS_FullCollectionMembership.* FROM SMS_FullCollectionMembership, SMS_Collection "+
        "where ResourceID = '{0}' and SMS_Collection.name LIKE 'OSD_W10_%' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID"

    $Systems | %{ gwmi @wmiargs -query ( $CollectionMembershipQuery -f $_.ResourceID )  } | 
        %{ [pscustomobject] @{
            Name = $_.SMS_FullCollectionMembership.Name
            ResourceID   = $_.SMS_FullCollectionMembership.ResourceID
            CollectionName = $_.SMS_COllection.Name
            CollectionID   = $_.SMS_COllection.CollectionID
        }} 

}
