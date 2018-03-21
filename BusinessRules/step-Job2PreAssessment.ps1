<#

Pre-Assessment processing (TBD)

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

# TBD - External Rules...

