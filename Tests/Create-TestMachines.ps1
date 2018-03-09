[cmdletbinding()]
param(
    $LimitingCollection = 'All Systems',
    $ComputeNameTemplate = 'DTC{0:X6}', # DeskTop Computer
    $CountMin = 1,
    $CountMax = 1000
    )

<#
Create 5000 machines within the existing CM environment
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

