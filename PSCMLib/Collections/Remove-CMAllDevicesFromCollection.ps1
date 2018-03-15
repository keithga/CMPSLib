
Function Remove-CMAllDevicesFromCollection {
    <#
    Nuke it!
    #>

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
        [string]    $CollectionID

    )

    Get-CMDevice @PSBoundParameters | Remove-CMDeviceFromCollection @PSBoundParameters
}
