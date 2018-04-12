function Add-CMItemsToStart {

    [cmdletbinding(DefaultParametersetname="File")]
    param(

        [parameter(Mandatory=$false, Position=0, ParameterSetName="File")]
        [string]    $InputFile,
        [parameter(Mandatory=$false, Position=0, ParameterSetName="Computer")]
        [string[]]  $ComputerName,
        [parameter(Mandatory=$false, Position=0, ParameterSetName="Collection")]
        [string]    $Collection,


        [parameter(Mandatory=$true, ParameterSetName="File")]
        [parameter(Mandatory=$true, ParameterSetName="Computer")]
        [parameter(Mandatory=$true, ParameterSetName="Collection")]
        [string]    $Target

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

Welcome to the Windows In-Place Upgrade Import Wizard.

This program will assist in adding Computers for Windows 10 In-Place Upgrade process.

    Destination: [$Target]

If this is not your approved Target Collection, exit now.








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

    if ( -not ( $InputFile -or $ComputerName -or $Collection ) ) {
        Wait-ForUserConfirmation
    }

    #endregion

    #region Wizard Page - Select Computers - File

    if ( $InputFile ) {
        if ( get-item  $InputFile | ? Extension -eq '.txt' ) {
            $ComputerName = get-content  $InputFile
        }
        elseif ( get-item $InputFile | ? Extension -eq '.csv' ) {
            $ComputerName = Import-Csv -Path $InputFile | % ComputerName
        }
    }

    #endregion

    #region Wizard Page - Import Options

    $result = $null
    if ( -not ( $InputFile -or $ComputerName -or $Collection ) ) { 

        clear-host
        # $host.ui.RawUI.WindowTitle = "Import Computers"

        Write-Host "Please input the list of computers, in the box below, one computername per line:`r`n(Press Next to continue)"

        [PowerShell_Wizard_Host.PSHostCallBack]::ForceMultilineOnReadLine(20)   # Hack

        $ComputerName = ( Read-Host ).Trim("`r`n") -Split "`r`n" | ? { -not [string]::IsNullOrEmpty($_) }

        $ComputerName | Write-verbose 
        Write-Host "Found [$($ComputerName.Count)]"

    }

    #endregion

    #region Confirmation

    if ( $Collection ) {

        Write-Host "COllection Name: [$Collection]"
        $Systems = get-cmdevice -CollectionName $Collection | Select-Object -Property ResourceID,Name,SiteCode,ResourceType

    }
    elseif ( $ComputerName ) {
        $Systems = $ComputerName | %{ get-CMDeviceObject -Name $_ }
    }
    else {
        throw "[10] No Computers found for addition!"
    }

    Clear-Host 
    $host.ui.RawUI.WindowTitle = "Verify"
    Write-Host "`r`nVERIFY!`r`n`r`nFound Systems  (Count: $($Systems.Count)):"
    $Systems |  Select-Object -Property ResourceID,Name,SiteCode,ResourceType | Out-GridView

    #########################
    Write-Host "`r`nTarget [$target]:"
    $Found = Get-CMCollection -Name $Target -collectionType Device
    if ( -not $Found ) {
        throw "Missing Target Collection $Target"
    }
    $Found | Select-Object -Property CollectionID,Name,LocalMemberCount,LimitToCollectionID,LimitToCollectionName | out-gridview

    Write-Host "`r`nVerify and continue"

    Wait-ForUserConfirmation

    #endregion

    #region Procesing

    $host.ui.RawUI.WindowTitle = "Working..."

    Write-Host "working..."

    # XXX TBD - Future: use $SiteCode, $COmputerName and $Credential to connect to remote machines. Skip for now

    $results = $Systems | Add-CMDeviceToCollection -CollectionName $Target -passThru

    $Count = 'Unknown'
    if ( $Results.count -eq 2 ) {
        $results | Out-String -Width 200 | Write-Verbose
        $Count = $Results[1].CollectionRules.Count - $Results[0].CollectionRules.Count
    }

    Write-Host @"







    Finished

    Was Count: $($Results[0].CollectionRules.Count)

    Now Count: $($Results[1].CollectionRules.Count)

"@

    Wait-ForUserConfirmation

    #endregion


    #region Cleanup

    Pop-Location -StackName CM

    #endregion
}