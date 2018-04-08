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

write-verbose "Dir: FileSystem::$Path\MoveToDay\*\*.clixml"
foreach ( $File in get-childitem FileSystem::$Path\RemoveItems\*\*.clixml -Exclude Error,Done ) {

    Write-Verbose "File: $($File.FullName)"
    $removeFile = $True
    $ErrorFile = $False

    foreach ( $ProcessItem in Import-Clixml FileSystem::$file ) {

        try {

            if ( Test-Path "$PSScriptRoot\Test-XMLSecurity.ps1" ) {
                if ( -not ( & "$PSScriptRoot\Test-XMLSecurity.ps1" -path FileSystem::$File ) ) {
                    Write-Verbose "`tBad Security Check $($File.FullName)"
                    $ErrorFile = $True
                    Break
                }
            }

            $ProcessItem | Foreach-Object Systems -whatif:$False |
                Get-CMDeviceFromAnyCollection | 
                Remove-CMDeviceFromAnyCollection -WhatIf:([bool]$WhatIfPreference.IsPresent)

        }
        catch {
            Write-Error $_.Exception.Message
            Write-Error $_.Exception.ItemName
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
