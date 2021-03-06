function Request-CMMoveToDay {

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false, Position=0)]
        [string]    $InputFile,

        [string[]]  $ComputerName,

        [string]   $SourceCollection,

        [string]   $StripeCollection,

        [dateTime] $TargetDay,

        [string]   $Path

    )

    #region Support routines

    function Wait-ForUserConfirmation {
        if ( $Host.Name -eq 'Windows PowerShell ISE Host' ) {
            Write-Verbose "PowerShell ISE does not have a ReadKey() function"
            REad-Host "Press return to continue..."
        }
        else {
            if ( $Host.Name -eq 'ConsoleHost' ) {
                Write-host "Press Any Key to Continue..."
            }
            $host.ui.RawUI.ReadKey() | out-null
        }
    }

    #endregion 

    #region Wizard Page - Welcome and Load

    Clear-Host
    $host.ui.RawUI.WindowTitle = "Welcome"

    Write-Host @"

Welcome to the Windows In-Place Upgrade Day of Target Wizard.

This program will assist in moving computers from:

    Source: [$SourceCollection]
$(if ($StripeCollection) { "    Stripe: [$StripeCollection]  (Optional)" })

If this is not your approved Business Unit, exit now.

$INputFile






    Loading CM PowerShell Modules...
"@

    ############################

    if(-not (Get-Module ConfigurationManager)) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -verbose:$false
    }
    if (get-location | ? Provider -notlike '*CMSite') {
        get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } 
        if (get-location | ? Provider -notlike '*CMSite') {
            throw "Unable to locate Local ConfigMgr Provider"
        }
    }

    $WMIArgs = Get-CMSiteForWMI

    ############################

    Write-Host "`r`n`r`n`tReady: $(Get-Location)"

    if ( -not ( $TargetDay ) ) {
        Wait-ForUserConfirmation
    }

    #endregion

    #region Find Systems

    write-host "`r`n`r`n Searching [$SourceCollection] ..."

    $SrcColl = get-CMCollection -name $SourceCollection
    if (-not $SrcColl ) { throw "Missing Collection $SourceCollection" }

    if ( $StripeCollection ) {
        $StripeColl = Get-CMCollection -Name $StripeCollection
        if (-not $StripeColl ) { throw "Missing Collection $StripeCollection" }

        if ( $StripeColl.Count -gt 1 ) {
            Clear-Host 
            $host.ui.RawUI.WindowTitle = "Striping"
            Write-Host "Please choose a Striping Collection:"
            $StripeColl = $StripeColl | % Name | Out-GridView -OutputMode Single | % { Get-CMCOllection -Name $_ }
        }
        $Systems = Get-CMDeviceFromTwoCollections -CollectionID $SrcColl.CollectionID -StripeCollectionID $StripeColl.CollectionID
    }
    else {
        $Systems = Get-CMDevice -CollectionID $SrcColl.CollectionID

        if ( $Systems.count -gt 5 ) {

            if ( $InputFile ) {
                if ( get-item  $InputFile | ? Extension -eq '.txt' ) {
                    $ComputerName = get-content  $InputFile
                }
                elseif ( get-item $InputFile | ? Extension -eq '.csv' ) {
                    $ComputerName = Import-Csv -Path $InputFile | % ComputerName
                }
            }

            if ( -not $COmputerName ) {
                Clear-Host 
                # $host.ui.RawUI.WindowTitle = "Import Computers"
                Write-Host @"
Found $($Systems.Count) number of devices, 
If you already KNOW the machines, enter the names here:
     (Leave Blank and Press Next to manually select the machines)

"@
                [PowerShell_Wizard_Host.PSHostCallBack]::ForceMultilineOnReadLine(20)   # Hack

                $ComputerName = ( Read-Host ).Trim("`r`n") -Split "`r`n" | ? { -not [string]::IsNullOrEmpty($_) } | %{  $_.Trim() }

            }

            if ( $ComputerName ) {
                $ComputerName | Write-verbose 
                Write-Host "Found [$($ComputerName.Count)]"

                $Systems = $Systems | ? Name -In $ComputerName 
            }

        }

        if ( -not $COmputerName ) {
            Clear-Host
            $host.ui.RawUI.WindowTitle = "    Manual Selection"
            Write-Host "Manual Selection of systems (use ctrl key to select more than one)"
            $Systems = Get-CMDevice -CollectionID $SrcColl.CollectionID |  Select-Object -Property ResourceID,Name,SiteCode | Out-GridView -OutputMode Multiple 
        }

    }

    #endregion

    #region Quick SubSystem confirmation 

    Clear-Host
    $host.ui.RawUI.WindowTitle = "SubSet of Systems"
    Write-Host "`r`nFound Systems(Count: $($Systems.Count)):`r`rCONFIRM SYSTEMS"
    $Systems |  Select-Object -Property ResourceID,Name,SiteCode | Out-GridView

    Wait-ForUserConfirmation

    #endregion 

    #region Date Selection 

    clear-host 
    $host.ui.RawUI.WindowTitle = "Date"
    write-host @"

Select the target Date for this batch of computers"

"@

    if ( -not $TargetDay ) { 
        [datetime]$TargetDay = 1..16 | %{ ([datetime]::Now).AddDays( $_ ) } | 
            # Test-ForBankersDays  | 
            %{ $_.ToString('D') } | 
            Out-GridView -OutputMode Single

    }

    if ( $TargetDay.Day -isnot [int] ) {
        throw "Did not select a valid day"
    }

    $DateCOllection = "DAY_{0:d2}_8PM" -f $TargetDay.Day 

    #endregion

    #region Target Output

    if ( -not $Path ) {

        Clear-Host 
        $host.ui.RawUI.WindowTitle = "Target Path"
        Write-Host @"

Select a target destination for this request

"@

        $fields = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

        $f = New-Object System.Management.Automation.Host.FieldDescription "File List"
        $f.SetparameterType( [System.IO.DirectoryInfo] )
        $fields.Add($f)

        $file = $Host.UI.Prompt( "", "", $fields )
        $Path = $file.Values | select-object -First 1 | ? { Test-Path $_ }

    }

    #endregion

    #region Confirmation 

    Clear-Host 

    $host.ui.RawUI.WindowTitle = "Verify"

    Write-Host @"

One final verification before submitting the request to the Background service:

        Machine Count: [$($Systems.Count)] Machines to be moved
        Output Path: [$path]
        Target Date: [$DateCOllection]

        Press Next to contiune, otherwise cancel
"@
    Wait-ForUserConfirmation

    #endregion

    #region Cleanup

    Pop-Location -StackName CM

    #endregion

    #region PRocess

    $host.ui.RawUI.WindowTitle = "Procesing"

    $CLIXMLFile = Join-Path $Path ([guid]::NewGuid().ToString() + '.clixml')

    if ( -not ( test-path $path ) ) { new-item -ItemType Directory -path $Path -Force -ErrorAction SilentlyContinue | out-null }

    @{
        Requestor = $env:USERNAME
        Approver = ''
        RequestedTime = [datetime]::now
        SourceCollection = $SrcColl.Name
        StripeCollection = $StripeColl.Name
        TargetCollection = $DateCOllection 
        Systems = $Systems | Select -Property Name,ResourceID
    } | Export-Clixml -Path $CLIXMLFile

    ############################

    Write-Host @"


























    Finished

    Protip: use Powershell to review the file before submitting:
        import-clixml <path>

"@

    if( $Host.Name -eq "PowershellWizardHost" ) {
        Write-host "Output:"
        [PowerShell_Wizard_Host.PSHostCallBack]::DisplayHyperLink($CLIXMLFile,"Notepad.exe",$CLIXMLFile)
    }

    Wait-ForUserConfirmation
    #endregion


}
