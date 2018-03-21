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

foreach ( $File in get-childitem $Path\ScheduleDay\*.clixml ) {

    Write-ToLog "File(Del): $($File.FullName)"
    $removeFile = $True
    $ErrorFile = $False

    foreach ( $ProcessItem in Import-Clixml $file ) {
        # ToDo - Verify SourceColl

        try {
            if ( $ProcessItem.SourceCollection -notmatch 'Ready_For_Scheduling' ) {
                write-ToLog "`tBad Source Collection: $ProcessItem.SourceCollection"
                $ErrorFile = $True
                break
            }
            if ( $ProcessItem.TargetCollection -notmatch '[0-9][0-9]_PM' ) {
                write-ToLog "`tBad Target Collection: $ProcessItem.TargetCollection"
                $ErrorFile = $True
                break
            }
            If ( $ProcessItem.WaitUntil ) {
                If ( $ProcessItem.WaitUntil -gt [datetime]::now ) {
                    write-ToLog "`tNot Time Yet: $ProcessItem.WaitUntil"
                    $removeFile = $False
                    break
                }
            }

            $ProcessItem | Foreach-Object Systems |
                Get-CMDeviceFromAnyCollection | 
                Move-CMDeviceToCollection -CollectionName ($ProcessItem.SourceCollection) -DestCollectionPostFix ($ProcessItem.TargetCollection)
        }
        catch {
            $ErrorFile = $True
        }
    }

    if ( $ErrorFile ) {
        new-item -ItemType directory -path $Path\ScheduleDay\Error -ErrorAction SilentlyContinue | Out-Null
        move-item $File -Destination $Path\ScheduleDay\Error -ErrorAction SilentlyContinue 
    }
    elseif ( $removeFile ) {
        new-item -ItemType directory -path $Path\ScheduleDay\Done -ErrorAction SilentlyContinue | Out-Null
        MOve-Item -Path $File -Destination $Path\ScheduleDay\Done -ErrorAction SilentlyContinue -Force | out-null
    }

}
