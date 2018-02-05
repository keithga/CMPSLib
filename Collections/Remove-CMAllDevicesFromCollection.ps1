
Function Remove-CMAllDevicesFromCollection {
    <#
    Nuke it!
    #>

    [CmdLetBinding()]
    Param(
        [string]   $CollectionName
    )

    Get-CMDevice -CollectionName $CollectionName | 
        Remove-CMResourceFromCollection -CollectionName $CollectionName
}
