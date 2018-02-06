
function Move-CMDeviceToCollection {
    [CmdLetBinding()]
    Param(
        [string]   $FromCollectionName,
        [string]   $ToCollectionName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $System
    )

    begin {
        $MySystem = @()
    }
    process {
        $MySystem += $System
    }
    end {
        if ( $MySystem.Count -gt 0 ) {
            Remove-CMResourceFromCollection -CollectionName $FromCollectionName -System $MySystem
            Add-CMDeviceToCollection -CollectionName $ToCollectionName -System $MySystem
        }
    }
}
