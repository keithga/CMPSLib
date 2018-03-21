
function Move-CMDeviceToCollectionFromAny {
    [CmdLetBinding(SupportsShouldProcess=$true)]
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

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollPostFixSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]    $CollectionPostFix,

        [Parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName='CollPostFixSet')]
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
        elseif ( $CollectionPostFix ) {
            $MySystem += $AnySystem | ? { -not $_.COllectionName.EndsWith($CollectionPostFix) } 
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
            elseif ( $CollectionPostFix ) {
                $MySystem |
                    Group-Object -Property CollectionName | 
                    ForEach-Object {
                        $NewTargetCollection = Get-CMCollectionBusinessName -Name $_.Name -PostFix $CollectionPostFix
                        $_.Group | Add-CMDeviceToCollection -CollectionName $NewTargetCollection
                    }

            }
            else {
                Add-CMDeviceToCollection -CollectionID $CollectionID -System $MySystem
            }

        }
    }
}
