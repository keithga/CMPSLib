
function Write-ToLog {
    [cmdletbinding()]
    param( [parameter(Mandatory=$True, ValueFromPipeline=$true)] $Msg )

    process {
        $msg | Out-String  -Width 200 | write-Verbose
        if ( $LogPath ) { 
            $Msg | Out-File -Encoding ascii -Force -Append -FilePath $LogPath 
        }
    }
}