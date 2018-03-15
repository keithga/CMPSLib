
function Get-CMDeviceFromAnyCollection {
    <#
    Return an object containing the system, and any collection it belongs to.
    #>
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true,  ValueFromPipeline=$true)]
        $System,

        [Alias('SMSSiteServerName')]
        [string]    $ComputerName,
        [string]    $SiteCode,
        [pscredential]$Credential

    )

    begin {

        # Construct the connection arguments
        $WmiArgs = Get-CMSiteForWMI @PSBoundParameters
        $wmiargs | out-string -Width 200 | write-verbose

        ##############

        $CollectionMembershipQuery = "SELECT SMS_Collection.*,SMS_FullCollectionMembership.* FROM SMS_FullCollectionMembership, SMS_Collection "+
            "where ResourceID = '{0}' and SMS_Collection.name LIKE '$($OSDW10Prefix)_%' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID"

    }
    process {
        $System | 
            %{ 
                $Query = $CollectionMembershipQuery -f $_.ResourceID
                write-verbose $Query 
                gwmi @wmiargs -query $QUery 
            } | 
            %{ [pscustomobject] @{
                Name = $_.SMS_FullCollectionMembership.Name
                ResourceID   = $_.SMS_FullCollectionMembership.ResourceID
                CollectionName = $_.SMS_COllection.Name
                CollectionID   = $_.SMS_COllection.CollectionID
            }} |
        Write-Output
    }
}
