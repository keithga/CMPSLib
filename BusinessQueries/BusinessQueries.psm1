
<#
.SYNOPSIS 
PowerShell Configuration Manager Libary

.DESCRIPTION
Libary for Configuration Manager

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/CMPSLib

#>

[CmdletBinding()]
param(
    [parameter(Position=0,Mandatory=$false)]
    [Switch] $Verbose = $false
)

if ($Verbose) { $VerbosePreference = 'Continue' }

@( "$PSScriptRoot\BusinessRules", "$PSScriptRoot\Collections", "$PSScriptRoot\Common", "$PSScriptRoot\SQLQuery", "$PSScriptRoot\Wizards" )  | 
    ForEach-Object { get-childitem -path "$_\*.ps1" -exclude *.tests.ps1 } |
    ForEach-Object {
        Write-Verbose "Importing function $($_.FullName)"
        . $_.FullName | Out-Null
    }

Export-ModuleMember -Function * 

