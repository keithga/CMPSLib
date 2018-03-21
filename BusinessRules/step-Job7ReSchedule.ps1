<#

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

Import-Module "$PSScriptRoot\..\PSCMLib" -force -ErrorAction SilentlyContinue 

# TBD

