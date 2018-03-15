[cmdletbinding()]
param(
    $LimitingCollection = 'All Systems',
    $ComputeNameTemplate = 'DTC{0:D6}', # DeskTop Computer
    $CountMin = 1,
    $CountMax = 1000
    )

<#
Create XXXX machines within the existing CM environment

Danger, CM may be broken, ensure you are running the latest up to date CM:
https://social.technet.microsoft.com/Forums/en-US/fadf5381-793f-4a9b-865d-17c6b9cddbe4/cm-1702-importcmcomputerinformation?forum=ConfigMgrPowerShell

#>

#######

if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }

#######

$TempFile = [System.IO.Path]::GetTempFileName() + '.csv'

for ( [int]$i = $CountMin; $i -lt $CountMax; $i = $i + 100 ) {

    write-verbose "Create a set of 100 machines at a time starting from $i"
    
    $i..( $i + 100 ) | 
        Foreach-Object {
            [PSCustomObject] @{
                ComputerName = $ComputeNameTemplate -f $_
                'SMBIOS GUID' = [guid]::NewGuid().ToString()
                'MAC Address' =  $null 
                'Source Computer' = $null 
                'Role001' = 'Test'
            } 
        } |
        convertto-csv -NoTypeInformation |
        ForEach-Object { $_.replace('"','') } |
        select-object -Skip 1 |
        Out-File -FilePath $TempFile -Encoding ascii

    dir $tempfile | Write-Verbose
    Import-CMComputerInformation -CollectionName $LimitingCollection -FileName $TempFile -VariableName Role001 # -EnableColumnHeading $true

}

Pop-Location -StackName CM

