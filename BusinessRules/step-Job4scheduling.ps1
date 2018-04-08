<#

Ready for scehduling...

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

foreach ( $File in get-childitem FileSystem::$Path\MoveToDay\*\*.clixml -Exclude Error,Done ) {

    Write-Verbose "File: $($File.FullName)"
    $removeFile = $True
    $ErrorFile = $False

    foreach ( $ProcessItem in Import-Clixml FileSystem::$file ) {

        try {
            if ( $ProcessItem.SourceCollection -notmatch 'Ready_For_Scheduling' ) {
                write-Verbose "`tBad Source Collection: $ProcessItem.SourceCollection"
                $ErrorFile = $True
                break
            }
            if ( $ProcessItem.TargetCollection -notmatch 'DAY_[0-9][0-9]_8PM' ) {
                write-Verbose "`tBad Target Collection: $ProcessItem.TargetCollection"
                $ErrorFile = $True
                break
            }
            If ( $ProcessItem.WaitUntil ) {
                If ( $ProcessItem.WaitUntil -gt [datetime]::now ) {
                    write-Verbose "`tNot Time Yet: $ProcessItem.WaitUntil"
                    $removeFile = $False
                    break
                }
            }

            if ( Test-Path "$PSScriptRoot\Test-XMLSecurity.ps1" ) {
                if ( -not ( & "$PSScriptRoot\Test-XMLSecurity.ps1" -path $File ) ) {
                    Write-Verbose "`tBad Security Check $($File.FullName)"
                    $ErrorFile = $False
                    Break
                }
            }

            $ProcessItem | Foreach-Object Systems |
                Get-CMDeviceFromAnyCollection  | 
                Move-CMDeviceToCollection -CollectionName ($ProcessItem.SourceCollection) -DestCollectionPostFix ($ProcessItem.TargetCollection) -WhatIf:([bool]$WhatIfPreference.IsPresent)
        }
        catch {
            $ErrorFile = $True
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

