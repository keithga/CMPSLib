<#

Remove the requested machines from the entire process.
#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

foreach ( $File in get-childitem FileSystem::$Path\RemoveItems\*\*.clixml -Exclude Error,Done ) {

    Write-Verbose "File: $($File.FullName)"
    $removeFile = $True
    $ErrorFile = $False

    foreach ( $ProcessItem in Import-Clixml FileSystem::$file ) {

        try {

            if ( Test-Path "$PSScriptRoot\Test-XMLSecurity.ps1" ) {
                if ( -not ( & "$PSScriptRoot\Test-XMLSecurity.ps1" -path $File ) ) {
                    Write-Verbose "`tBad Security Check $($File.FullName)"
                    $ErrorFile = $False
                    Break
                }
            }

            $ProcessItem | Foreach-Object Systems |
                Get-CMDeviceFromAnyCollection | 
                Remove-CMDeviceFromAnyCollection -WhatIf:([bool]$WhatIfPreference.IsPresent)

        }
        catch {
            $errorFile = $true
        }
    }

    if ( $ErrorFile ) {
        new-item -ItemType directory -path FileSystem::$Path\MoveToDay\Error -ErrorAction SilentlyContinue | Out-Null
        move-item FileSystem::$File -Destination FileSystem::$Path\MoveToDay\Error -ErrorAction SilentlyContinue 
    }
    elseif ( $removeFile ) {
        new-item -ItemType directory -path FileSystem::$Path\MoveToDay\Done -ErrorAction SilentlyContinue | Out-Null
        MOve-Item -Path FileSystem::$File -Destination FileSystem::$Path\MoveToDay\Done -ErrorAction SilentlyContinue -Force | out-null
    }

}
