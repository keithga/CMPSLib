
<#

.SYNOPSIS 
Configuration Manager Libary - Main Build Scripts

.DESCRIPTION
Build script for Configuration Manager Libary Scripts.
Build environment

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/CMPSLib

#>

[cmdletbinding()]
param(
)

$ModuleCommon = @{
    Author = "Keith Garner (KeithGa@DeploymentLive.com)"
    CompanyName  = "https://github.com/keithga/CMPSLib" 
    Copyright = "Copyright Keith Garner (KeithGa@DeploymentLive.com), all Rights Reserved."
    ModuleVersion = ("1.1." + (get-date -Format "yyMM.ddHH"))
    PowershellVersion = "2.0"
    Description = "DeployShared Powershell Library"
    GUID = [GUID]::NewGUID()
}

Foreach ( $libPath in get-childitem -path $PSScriptRoot -Directory )
{
    Write-Verbose "if not exist $($libPath.FullName)\*.psm1, then create"

    $ImportDirectories = get-childitem -Directory -path .\DeployShared |
        Where-Object { test-path  "$($_.fullname)\*.ps1" } | 
        ForEach-Object { "`$PSScriptRoot\$($_.Name)" }

@"

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
    [parameter(Position=0,Mandatory=`$false)]
    [Switch] `$Verbose = `$false
)

if (`$Verbose) { `$VerbosePreference = 'Continue' }

@( "$( $ImportDirectories -join '", "' )" )  | 
    ForEach-Object { get-childitem -path "`$_\*.ps1" -exclude *.tests.ps1 } |
    ForEach-Object {
        Write-Verbose "Importing function `$(`$_.FullName)"
        . `$_.FullName | Out-Null
    }

Export-ModuleMember -Function * 

"@ | Out-File -Encoding ascii -FilePath "$($LibPath.FullName)\$($LibPath.Name).psm1"


    $ManifestName = "$($LibPath.FullName)\$($LibPath.Name).psd1"
    New-ModuleManifest @Modulecommon -path $ManifestName -ModuleToProcess "$($LibPath.Name).psm1" -FileList $FileList -ModuleList $FileList

}

