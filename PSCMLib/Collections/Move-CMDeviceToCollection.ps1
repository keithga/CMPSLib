
function Move-CMDeviceToCollection {
    [CmdLetBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true, Position=1, ParameterSetName='CollPostFixSet')]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $CollectionName,

        [Parameter(Mandatory=$true, Position=1, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('TargetName')] 
        [string]    $DestCollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $CollectionID,

        [Parameter(Mandatory=$true, Position=1, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('TargetID')] 
        [string]    $DestCollectionID,

        [Parameter(Mandatory=$true, Position=1, ParameterSetName='CollPostFixSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]    $DestCollectionPostFix,

        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollNameSet')]
        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollIDSet')]
        [Parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName ='CollPostFixSet')]
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

            if ( $PSCmdlet.ShouldProcess($MySystem.Name -join ' ',"MOve") ) { 

                if ( $CollectionName ) {
                    $removedFrom = $CollectionName
                    Remove-CMDeviceFromCollection -CollectionName $CollectionName -System $MySystem -skipLog
                }
                else {
                    $removedFrom = $CollectionID
                    Remove-CMDeviceFromCollection -CollectionID $CollectionID -System $MySystem -skipLog
                }

                Write-Verbose "Write to $DestCollectionName $DestCollectionID"
                if ( $DestCollectionName ) {
                    write-toLog ( "Mov,$RemovedFrom,$DestCollectionName,$($MySystem.Name -join ' ')" )
                    Add-CMDeviceToCollection -CollectionName $DestCollectionName -System $MySystem -skipLog
                }
                elseif ( $DestCollectionPostFix ) {
                    $NewTargetCollection = Get-CMCollectionBusinessName -Name $CollectionName -PostFix $DestCollectionPostFix
                    write-toLog ( "Mov,$RemovedFrom,$NewTargetCollection,$($MySystem.Name -join ' ')" )
                    Add-CMDeviceToCollection -CollectionName $NewTargetCollection -System $MySystem -skipLog
                }
                else {
                    write-toLog ( "Mov,$RemovedFrom,$DestCollectionID,$($MySystem.Name -join ' ')" )
                    Add-CMDeviceToCollection -CollectionID $DestCollectionID -System $MySystem -skipLog
                }

            }

        }
    }
}
