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

foreach ( $File in get-childitem $Path\RemoveItems\*.clixml ) {

    Write-Verbose "File(Del): $($File.FullName)"
    $removeFile = $True
    $ErrorFile = $False

    foreach ( $ProcessItem in Import-Clixml $file ) {

        try {
            $ProcessItem | Foreach-Object Systems |
            Get-CMDeviceFromAnyCollection | 
            Remove-CMDeviceFromAnyCollection

        }
        catch {
            $errorFile = $true
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
