function Add-CMItemsToStart {

    [cmdletbinding()]
    param(
        [string]   $BusinessUnit = 'TST',
        [string[]]   $ComputerName,
        [switch]   $Silent
    )

    #region Wizard Page - Welcome

    Clear-Host 

    $host.ui.RawUI.WindowTitle = "Welcome"

    Write-Host @"

Welcome to the $BusinessUnit Windows In-Place Upgrade Scheduling Wizard.

This program will assist in adding Computers for Windows 10 In-Place Upgrade

"@

    if ( $Silent ) { 

    }
    elseif ( $Host.Name -eq 'Windows PowerShell ISE Host' ) {
        #REad-Host "Press return to continue.."
    }
    else {
        $host.ui.RawUI.ReadKey() | out-null
    }

    #endregion

    #region Wizard Page - 

    clear-host
    $host.ui.RawUI.WindowTitle = "IMport Choice"

    Write-Host "How do you want to import the computer list:"

    if ( -not $ComputerName ) { 

        $title = "Import Type"
        $message = "IMport Computers"

        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Import Computer List from File", ""
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "Import Computer List from Clipboard", ""

        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

        $result = $host.ui.PromptForChoice("", "", $options, 0) 

    }

    #endregion

    #region Wizard Page - Select Computers - File
    
    if ( $result -eq 0 ) {
        Clear-Host 
        $host.ui.RawUI.WindowTitle = "Add Computers From File"
        Write-Host @"

Select a *.txt file containing a list of computers to import.

"@

        if ( -not $Silent ) {
            $fields = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

            $f = New-Object System.Management.Automation.Host.FieldDescription "File List"
            $f.SetparameterType( [System.IO.FileInfo] )
            $f.DefaultValue = "C:\Users\keith\OneDrive\Desktop\testfile.txt"
            $fields.Add($f)

            $file = $Host.UI.Prompt( "", "", $fields )
            $ComputerName = $file.Values | select-object -First 1 | ? { Test-Path $_ } | %{ get-content -path $_ }
        }

    }

    #endregion

    #region WIzard Page - Select Computers - Clipboard

    if ( $result -eq 1 ) {
        Clear-Host 
        $host.ui.RawUI.WindowTitle = "Add Computers from Clipboard"
        Write-Host @"

Now ready to import computers from the clipboard

Press Next when ready...

"@

        if ( $Silent ) { 

        }
        elseif ( $Host.Name -eq 'Windows PowerShell ISE Host' ) {
            #REad-Host "Press return to continue.."
        }
        else {
            $host.ui.RawUI.ReadKey() | out-null
        }


        $ComputerName = get-clipboard | %{ $_ -split "`r`n" }

    }

    #endregion

    #region Wizard Page - Select Computers - Clipboard

    Clear-Host

    Write-Host @"

Ready to import: [$($ComputerName.Count)] Systems

    Example:
"@

    $computername | Out-GridView -OutputMode None

    #endregion
}