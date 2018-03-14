function Remove-CMItemsfromAnywhere {

    [cmdletbinding(DefaultParametersetname="Computer")]
    param(

        [parameter(Mandatory=$false, Position=0, ParameterSetName="File")]
        [string]    $InputFile,
        [parameter(Mandatory=$false, Position=0, ParameterSetName="Computer")]
        [string[]]  $ComputerName,

        [parameter(Mandatory=$false, Position=0, ParameterSetName="Collection")]
        [string]    $Collection,

        [string]   $SourceFilter = 'OSD_W10_Fall*'

    )

    <#

    There may be times when we will need to remove a computer or computers from the entire process. 

    This wizard is really only for internal use, individual business groups won't have access to remove direct memberships from all collections.

    #>


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

    Serarch Parameters: [$SourceFilter]

This operation is for CM ADMINS only.








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

    #region Wizard Page - Import Options

    $result = $null
    if ( -not ( $InputFile -or $ComputerName  -or $Collection ) ) { 

        clear-host
        # $host.ui.RawUI.WindowTitle = "Import Options"

        Write-Host @"

Choose an option for importing the list of computers into Configuration Manager

"@

        $List = @()
        $List += New-Object System.Management.Automation.Host.ChoiceDescription "Import Computer List from &File...", ""
        $List += New-Object System.Management.Automation.Host.ChoiceDescription "Import Computer List from &Clipboard", ""
        $List += New-Object System.Management.Automation.Host.ChoiceDescription "Import Computer List from &SCCM Collection...", ""

        $result = $host.ui.PromptForChoice("Import Options",$null,$List, 0) 
    }

    #endregion

    #region Wizard Page - Select Computers - File

    if ( $result -eq 0 -and ( -not $InputFile ) ) {

        Clear-Host 
        $host.ui.RawUI.WindowTitle = "   Add From File"
        Write-Host @"

Select a *.txt or *.csv file containing a list of computers to import.

"@

        $fields = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

        $f = New-Object System.Management.Automation.Host.FieldDescription "File List"
        $f.SetparameterType( [System.IO.FileInfo] )
        $fields.Add($f)

        $file = $Host.UI.Prompt( "", "", $fields )
        $InputFile = $file.Values | select-object -First 1 | ? { Test-Path $_ }

    }

    if ( $InputFile ) {
        if ( get-item  $InputFile | ? Extension -eq '.txt' ) {
            $ComputerName = get-content  $InputFile
        }
        elseif ( get-item .\testfile.txt | ? Extension -eq '.csv' ) {
            $ComputerName = Import-Csv -Path $InputFile | % ComputerName
        }
    }

    #endregion

    #region Wizard Page - Select Computers - Clipboard

    if ( $result -eq 1 ) {
        Clear-Host 
        $host.ui.RawUI.WindowTitle = "   Add from Clipboard"
        Write-Host @"

Now ready to import computers from the clipboard

"@

        Wait-ForUserConfirmation

        $ComputerName = get-clipboard | %{ $_ -split "`r`n" }

    }

    #endregion

    #region Wizard Page - Select Computers - Collection

    if ( $result -eq 2 ) {
        Clear-Host 
        $host.ui.RawUI.WindowTitle = "   Add from Collection"
        Write-Host @"

Start the installation from an existing collection

"@

        $Collection = Read-Host "Name:" | ? { -not [string]::IsNullOrEmpty($_) }

    }

    #endregion


    #region Confirmation

    if ( $Collection ) {

        Write-Host "COllection Name: [$Collection]"
        $Systems = get-cmdevice -CollectionName $Collection | Select-Object -Property ResourceID,Name,SiteCode,ResourceType

    }
    elseif ( $ComputerName ) {
        $Systems = $ComputerName | %{ Get-CMDevice -name $_ } 

    }
    else {
        throw "[10] No Computers found for addition!"
    }

    Clear-Host 
    $host.ui.RawUI.WindowTitle = "Verify"
    Write-Host "`r`nFound Systems  (Count: $($Systems.Count)):"
    $Systems |  Select-Object -Property ResourceID,Name,SiteCode,ResourceType | Out-GridView

    #########################
    Write-Host "`r`nSearch [$SourceFilter]:"


    $CollectionMembershipQuery = "SELECT SMS_Collection.*,SMS_FullCollectionMembership.* FROM SMS_FullCollectionMembership, SMS_Collection where ResourceID = '{0}' and SMS_Collection.name LIKE 'OSD_W10_%' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID"

    $Found = $Systems | %{ gwmi @wmiargs -query ( $CollectionMembershipQuery -f $_.ResourceID )  } | 
        %{ [pscustomobject] @{
            Name = $_.SMS_FullCollectionMembership.Name
            ResourceID   = $_.SMS_FullCollectionMembership.ResourceID
            CollectionName = $_.SMS_COllection.Name
            CollectionID   = $_.SMS_COllection.CollectionID
        }} # | group-object -Property COllectionID

    if ( -not $Found ) {
        throw "Did not find any items"
    }

    $Found | Out-GridView

    Write-Host "`r`nVerify and continue"

    Wait-ForUserConfirmation

    #endregion

    #region Procesing


    $host.ui.RawUI.WindowTitle = "Working..."

    Write-Host "working..."

    # XXX TBD - Future: use $SiteCode, $COmputerName and $Credential to connect to remote machines. Skip for now

    $Found | Group-Object -Property CollectionID | 
        ForEach-Object {
            $_.Group | Remove-CMResourceFromCollection -CollectionID $_.Name
        }

    Write-Host @"







    Finished

"@
 
    Wait-ForUserConfirmation

    #endregion


    #region Cleanup

    Pop-Location -StackName CM

    #endregion
}