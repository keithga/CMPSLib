[cmdletbinding()]
param(
    $TargetZipPath = "$env:temp\ps2wiz",
    $TargetZipFile = "$env:temp\ps2wiz.zip",
    $targets = @('ENG','OPS','SEC'),
    $Season = 'Fall'
)

<#

quick script to buildout the wizard environment

#>

$ErrorActionPreference = 'stop'

if(-not (Get-Module PSCMLib)) { Import-Module "$PSScriptRoot\..\PSCMLib" }

#region Get wizard bits


if ( -not ( Test-Path "$PSscriptRoot\..\bin\PowerShell Wizard Host.exe" ) ) {

    if ( -not ( test-path "$PSscriptRoot\..\bin" ) ) { 
        new-item -ItemType directory "$PSscriptRoot\..\bin" -ErrorAction SilentlyContinue | out-null
    }

    remove-item -Force -Recurse $TargetZipPath -ErrorAction SilentlyContinue | Out-Null
    remove-item -Force $TargetZipFile -ErrorAction SilentlyContinue | Out-Null

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    iwr -Uri 'https://github.com/keithga/PS2Wiz/archive/master.zip' -OutFile $TargetZipFile

    Expand-Archive -Path $TargetZipFile -DestinationPath $TargetZipPath -Force

    & $TargetZipPath\PS2Wiz-master\ps2wiz.ps1 "$TargetZipPath\PS2Wiz-master\Examples\Demo-Wrapper.ps1" -OutputFolder "$PSscriptRoot\..\bin"  | Out-Null
    remove-item -Force -Recurse $TargetZipPath | Out-Null
    remove-item -Force $TargetZipFile | Out-Null

    if ( -not ( Test-Path "$PSscriptRoot\..\bin\PowerShell Wizard Host.exe" ) ) {
        throw "not found $PSscriptRoot\..\bin\PowerShell Wizard Host.exe"
    }

}

#endregion


#region Create BatFiles

new-item -ItemType Directory -Path "$PSscriptRoot\..\BusinessActions" -ErrorAction SilentlyContinue | out-null


########################

foreach ( $Target in $Targets ) {

@"
@if not defined debug echo off

:: Batch script to call wizard for type $Target

"%~dps0\..\Bin\PowerShell Wizard Host.exe" "(import-module '%~dps0\..\PSCMLib');(add-cmitemstostart -Target '$(Format-WAASPreAssessGroup -Season $Season -Group $Target)' -InputFile '%~f1' )"
"@ | Out-File -Encoding ascii -Force "$PSscriptRoot\..\BusinessActions\Import_Ready_For_PreAssessment_$Target.cmd"

@"
@if not defined debug echo off

:: Batch script to call wizard for type $Target
"%~dps0\..\Bin\PowerShell Wizard Host.exe" "(import-module '%~dps0\..\PSCMLib');(request-CMMoveToDay -SourceCollection '$(Format-WAASScheduling -Season $Season -Group $Target)' )"
"@ | Out-File -Encoding ascii -Force "$PSscriptRoot\..\BusinessActions\Import_Ready_For_Scheduling_$Target.cmd"

@"
@if not defined debug echo off

:: Batch script to call wizard for type $Target
"%~dps0\..\Bin\PowerShell Wizard Host.exe" "(import-module '%~dps0\..\PSCMLib');(request-CMMoveToDay -SourceCollection '$(Format-WAASScheduling -Season $Season -Group $Target)' -StripeCollection '$($Target)_OSD_W10_*' )"
"@ | Out-File -Encoding ascii -Force "$PSscriptRoot\..\BusinessActions\Import_Ready_For_Scheduling_With_Stripes_$Target.cmd"

}

########################

@"
@if not defined debug echo off

:: Batch script to call wizard for type Remove

"%~dps0\..\Bin\PowerShell Wizard Host.exe" "(import-module '%~dps0\..\PSCMLib');(Remove-CMItemsfromAnywhere -InputFile '%~f1' )"
"@ | Out-File -Encoding ascii -Force "$PSscriptRoot\..\BusinessActions\Remove_System_From_Anywhere_ADMINONLY.cmd"


#endregion