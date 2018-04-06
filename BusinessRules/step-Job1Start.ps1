<#
Devices are in the Ready_FOr_PreAssessment_<Group> colleciton, 
move the computer to the Preassessment collection (easy).
#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

Write-Verbose "Move from Ready_For_PreAssess_<Group> to PreAssessment"
foreach ( $CollectionName in Get-CMCollection -CollectionType Device -Name (Format-WAASPreAssessGroup -season '*' -group '*') | % Name ) { 
    Get-CMDevice -CollectionName $CollectionName  | 
        Move-CMDeviceToCollection -CollectionName $CollectionName -DestCollectionPostFix 'Preassessment' -WhatIf:([bool]$WhatIfPreference.IsPresent)
}

