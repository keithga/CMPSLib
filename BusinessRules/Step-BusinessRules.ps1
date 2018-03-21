<#

Process ALL the rules

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

Import-Module "$PSScriptRoot\..\PSCMLib" -force -ErrorAction SilentlyContinue 
if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }

# PRocess all rules...

& $PSScriptRoot\step-Job1Start.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job2PreAssessment.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job3PreCacheCompat.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job4scheduling.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job5DailyCleenup.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job6Cancel.ps1 @PSBoundParameters
& $PSScriptRoot\step-Job7ReSchedule.ps1 @PSBoundParameters

Pop-Location -StackName CM

