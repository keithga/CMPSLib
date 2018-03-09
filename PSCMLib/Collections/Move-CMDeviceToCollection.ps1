
function Move-CMDeviceToCollection {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $CollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $DestCollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $CollectionID,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $DestCollectionID,

        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollNameSet')]
        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollIDSet')]
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

            Write-Verbose "Remove From $CollectionName $CollectionID"
            if ( $CollectionName ) {
                Remove-CMResourceFromCollection -CollectionName $CollectionName -System $MySystem
            }
            else {
                Remove-CMResourceFromCollection -CollectionID $CollectionID -System $MySystem
            }

            Write-Verbose "Write to $DestCollectionName $DestCollectionID"
            if ( $DestCollectionName ) {
                Add-CMResourceFromCollection -CollectionName $DestCollectionName -System $MySystem
            }
            else {
                Add-CMResourceFromCollection -CollectionID $DestCollectionID -System $MySystem
            }

        }
    }
}
