function Move-CMItemsToDay {

    [cmdletbinding()]
    param(
        [dateTime] $TargetDay,
        [string]   $BusinessUnit = 'TST',
        [string]   $TargetFile,
        [int]      $first = 100,
        [switch]   $Silent
    )

    #region Wizard Page - Welcome

    $Count = get-random -Maximum 1000

    Clear-Host 

    $host.ui.RawUI.WindowTitle = "Welcome"

    Write-Host @"

Welcome to the $BusinessUnit Windows In-Place Upgrade Scheduling Wizard.

This program will assist in scheduling Computers for Deployment.

Currently there are [$Count] machines that have passed Pre-Assessment
and Pre-Compat scans, and are ready for actual deployment. 

"@

    if ( $Silent ) { 
    
    }
    elseif ( $Host.Name -eq 'Windows PowerShell ISE Host' ) {
        REad-Host "Press return to continue.."
    }
    else {
        $host.ui.RawUI.ReadKey() | out-null
    }

    #endregion

    #region Wizard Page - Select Computers

    Clear-Host 
    $host.ui.RawUI.WindowTitle = "Select Computers"
    Write-Host @"

There are [$Count] number of machines ready for scheduling 

"@

    if ( -not $Silent ) {
        $fields = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

        $f = New-Object System.Management.Automation.Host.FieldDescription "Numeric Value"
        $f.SetparameterType( [int] )
        $f.DefaultValue = $First.ToString()
        $f.HelpMessage  = "Number of machines to move"
        $fields.Add($f)

        $result = $Host.UI.Prompt( "", "", $fields )  
        $First =  $result.Values | select-object -first 1

    }

    #endregion

    #region Wizard Page - Date Select

    clear-host 
    $host.ui.RawUI.WindowTitle = "Date"
    write-host @"

Select the target Date for this batch of computers"

"@

    if ( -not $TargetDay ) { 
        [datetime]$TargetDay = 1..31 | %{ ([datetime]::Now).AddDays( $_ ) } | 
            Test-ForBankersDays  | 
            %{ $_.ToString('D') } | 
            Out-GridView -OutputMode Single

        clear-host
    }

    #endregion

    #region Work...

    $host.ui.RawUI.WindowTitle = "Working..."
    write-host "Start a sample progress going from 0% to 100%"

    foreach ( $i in 1..20 )
    {
        write-progress -ACtivity "Starting work $i" -percentcomplete ($i * 5)
        start-sleep -Milliseconds 100
    }

    #endregion

    #region Wizard Page - Done

    $host.ui.RawUI.WindowTitle = "Finished"
    1..80 | %{ write-host "" }

write-host @"

Moving the first $First number of $BusinessUnit 
machines for In-Place upgrade on $($TargetDay.TOString('d'))

Done!

"@
    
    if ( $Silent ) { 
    
    }
    elseif ( $Host.Name -eq 'Windows PowerShell ISE Host' ) {
        REad-Host "Press return to continue.."
    }
    else {
        $host.ui.RawUI.ReadKey() | out-null
    }

    #endregion

}