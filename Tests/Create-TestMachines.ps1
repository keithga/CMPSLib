[cmdletbinding()]
param(
    $LimitingCollection = 'All Systems',
    $ComputeNameTemplate = 'PCTest{0:X6}',
    $CountMin = 1,
    $CountMax = 5000
    )

<#
Create 5000 machines within the existing CM environment
#>

$TempFile = [System.IO.Path]::GetTempFileName() + '.csv'


for ( $i = $CountMin; $i -lt $CountMax; $i = $i + 100 ) {

    write-verbose "Create a set of 100 machines at a time starting from $i"
    
    $i..($i..99) | % {
        [PSCustomObject] @{
            ComputerName = $ComputeNameTemplate -f $_
            'SMBIOS GUID' = [guid]::NewGuid().ToString()
            'MAC Address' =  $null 
            'Source Computer' = $null 
            'Role001' = 'Test'
        }
    } | convertto-csv -NoTypeInformation | 
        ForEach-Object { $_.replace('"','') } |
        select-object -Skip 1 |
        Out-File -FilePath $TempFile -Encoding ascii

    Import-CMComputerInformation -CollectionName $LimitingCollection -FileName $TempFile -VariableName Role001 # -EnableColumnHeading $true

}


