
function Move-CMDeviceToCollectionFromAny {
    [CmdLetBinding()]
    Param(
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

        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollNameSet')]
        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollIDSet')]
        # custom object from Get-DeviceFromAnyCollection, do not confuse with $System
        $AnySystem
    )

    begin {
        $MySystem = @()
    }
    process {
        if ( $CollectionName ) {
            $MySystem += $AnySystem | ? CollectionName -NE $CollectionName
        }
        else {
            $MySystem += $AnySystem | ? CollectionID -NE $CollectionID
        }
    }
    end {
        if ( $MySystem.Count -gt 0 ) {

            Write-Verbose "Remove From ANY $($MySystem.Count)"
            Remove-CMDeviceFromAnyCollection -AnySystem $MySystem

            Write-Verbose "Write to $CollectionName $CollectionID"
            if ( $CollectionName ) {
                # although tecnically -System and $AnySytem are different types, it works here, only use Name and ResourceID
                Add-CMDeviceToCollection -CollectionName $CollectionName -System $MySystem
            }
            else {
                Add-CMDeviceToCollection -CollectionID $CollectionID -System $MySystem
            }

        }
    }
}
