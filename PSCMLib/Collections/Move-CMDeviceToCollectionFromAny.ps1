
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
        if ( $CollectionID ) {
            $MySystem += $AnySystem | ? CollectionID -NE $CollectionID
        }
        elseif ( $CollectionPostFix ) {
            $MySystem += $AnySystem | ? { -not $_.COllectionName.EndsWith($CollectionPostFix) } 
        }
        else {
            $MySystem += $AnySystem | ? CollectionName -NE $CollectionName
        }
    }
    end {
        if ( $MySystem.Count -gt 0 ) {
            $MySystem |
                Group-Object -Property CollectionName | 
                ForEach-Object {
                    if ( $CollectionName ) {
                        $_.Group | Move-CMDeviceToCollection -CollectionName $_.Name -DestCollectionName $CollectionName -WhatIf:([bool]$WhatIfPreference.IsPresent)
                    }
                    elseif ( $CollectionPostFix ) {
                        $_.Group | Move-CMDeviceToCollection -CollectionName $_.Name -DestCollectionPostFix $CollectionPostFix -WhatIf:([bool]$WhatIfPreference.IsPresent)
                    }
                    else {
                        $_.Group | Move-CMDeviceToCollection -CollectionID $_.Group[0].CollectionID -DestCollectionID $CollectionID -WhatIf:([bool]$WhatIfPreference.IsPresent)
                    }
                }

        }
    }
}
