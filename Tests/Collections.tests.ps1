<#

Pester tests for collections

#>

[cmdletbinding()]
param(
    $CollName = 'OSD_W10_Fall_Finished',
    $CollName1 = 'OSD_W10_Fall_Preassessment',
    $Stripes   = @( 'ENG_OSD_W10_Alpha', 'ENG_OSD_W10_Bravo', 'ENG_OSD_W10_Charlie', 'ENG_OSD_W10_Delta' ) ,
    $PCNames1  = 'DTC00001*',
    $PCNames2  = 'DTC00002*'
)

Import-Module "$PSScriptRoot\..\PSCMLib" -force -ErrorAction SilentlyContinue 
if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }

###########################

function Start-WaitForCount {
    param( $CollName, $Count )
    # Sometimes it takes a while for the collection membership to report a change. Wait!

    $i = 0
    while ( get-cmdevice -CollectionName $CollName | measure-object | ? Count -ne $Count ) {
        Write-Progress -Activity "CollectionMembershipChange $CollName $i"
        start-sleep 1
        $i += 1
    }
    write-progress -Activity 'CollectionMembershipChange' -Completed
    return $count
}

###########################

foreach ( $Col in $CollName,$CollName1,$Stripes[0] ) {
    write-verbose "Clean $COl first"

    if ( get-cmdevice -CollectionName $Col | measure-object | ? Count -gt 0 ) {
        write-warning "remove stuff from old collection $Col"
        Remove-CMAllDevicesFromCollection -CollectionName $Col
        Start-WaitForCount -CollName $Col -count 0 | out-null
        get-cmdevice -CollectionName $Col | Measure-Object | % Count
    }
}

$MyColl = get-CMCollection -Name $CollName
$MyColl1 = get-CMCollection -Name $CollName1
$MyStripe = Get-CMCollection -name $Stripes[0]

$MyDev1 = get-cmDeviceObject -Name $PCNames1
$MyDev2 = get-cmDeviceObject -Name $PCNames2

###########################

describe 'verify environment' {

    $MyColl | % Name  | should be $CollName
    $MyCOll | Measure-Object | % count | should not be 0
    get-cmdevice -CollectionName $CollName | Measure-Object | % Count | should be 0

    $MyColl1 | % Name  | should be $CollName1
    $MyCOll1 | Measure-Object | % count | should not be 0
    get-cmdevice -CollectionName $CollName1 | Measure-Object | % Count | should be 0

    $MyDev1 | Measure-Object | % count | should be 10
    $MyDev2 | Measure-Object | % count | should be 10

    get-cmDeviceObject -Name $PCNames1 | % Name | should be (0..9 | %{ $PCNames1.replace('*','{0}') -f $_ })
   
    $MyStripe | % Name | should be $Stripes[0] 
    $MyStripe | Measure-Object | % count | should not be 0
    get-cmdevice -CollectionName $Stripes[0] | Measure-Object | % Count | should be 0
}



describe 'Striping Collections' {

    it 'add group1' {
        $MyDev1 + $MyDev2 | Add-CMDeviceToCollection -CollectionID $MyColl.CollectionID
        Start-WaitForCount -CollName $CollName -count 20 | should be 20
        get-cmdevice -CollectionID $MyColl.CollectionID | % Name | Should be ($MyDev1.Name + $MyDev2.Name)
    }

    it 'Make Stripes' {
        get-cmdevice -name DTC* | ? { $_.Name.substring(4) % 4 -eq 1 } | Add-CMDeviceToCollection -CollectionName $Stripes[0]
        #get-cmdevice -name DTC* | ? { $_.Name.substring(4) % 4 -eq 2 } | Add-CMDeviceToCollection -CollectionName $Stripes[1]
        #get-cmdevice -name DTC* | ? { $_.Name.substring(4) % 4 -eq 3 } | Add-CMDeviceToCollection -CollectionName $Stripes[2]
        #get-cmdevice -name DTC* | ? { $_.Name.substring(4) % 4 -eq 4 } | Add-CMDeviceToCollection -CollectionName $Stripes[3]
        Start-WaitForCount -CollName $Stripes[0] -count 26
    }

    it 'get Stripes' {
        Get-CMDeviceFromTwoCollections -Name $COllName -StripeName $Stripes[0] | Measure-Object | % Count | should be 5
        Get-CMDeviceFromTwoCollections -Name $COllName -StripeName $Stripes[0] | % Name | should be @('DTC000013','DTC000017','DTC000021','DTC000025','DTC000029')
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionID $MyColl.CollectionID
        Remove-CMAllDevicesFromCollection -CollectionName $Stripes[0]
        Start-WaitForCount -CollName $CollName -count 0 | out-null
        Start-WaitForCount -CollName $Stripes[0] -count 0 | out-null
    }

}


describe 'Add some stuff with IDs' {

    it 'add group1' {
        $MyDev1 | Add-CMDeviceToCollection -CollectionID $MyColl.CollectionID
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        get-cmdevice -CollectionID $MyColl.CollectionID | % Name | Should be $MyDev1.Name
    }

    it 'add group2' {
        $MyDev2 | Add-CMDeviceToCollection -CollectionID $MyColl.CollectionID 
        Start-WaitForCount -CollName $CollName -count 20 | should be 20
        get-cmdevice -CollectionID $MyColl.CollectionID | % Name | Should be ($MyDev1.Name + $MyDev2.Name)
    }

    it 'Move group1' {
        $MyDev1 | Move-CMDeviceToCollection -CollectionID $MyColl.CollectionID -DestCollectionID $MyColl1.CollectionID
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10
        get-cmdevice -CollectionID $MyColl.CollectionID | % Name | Should be $MyDev2.Name
        get-cmdevice -CollectionID $MyColl1.CollectionID | % Name | Should be $MyDev1.Name
    }


    it 'remove group1' {
        $MyDev1 | Remove-CMDeviceFromCollection -CollectionID $MyColl1.CollectionID
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10
        get-cmdevice -CollectionID $MyColl.CollectionID | % Name | Should be $MyDev2.Name
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionID $MyColl.CollectionID
        Start-WaitForCount -CollName $CollName -count 0 | out-null
    }
}

describe 'Add some all stuff' {

    it 'add group1' {
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $CollName
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        get-cmdevice -CollectionName $CollName | % Name | Should be $MyDev1.Name
    }

    it 'add group2' {
        $MyDev2 | Add-CMDeviceToCollection -CollectionName $CollName1
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10
        get-cmdevice -CollectionName $CollName1 | % Name | Should be $MyDev2.Name
    }

    it 'Get From any' {
        $Any = $MyDev1 + $MyDev2 | Get-CMDeviceFromAnyCollection 
        $Any | % Name | write-host
        $Any | Measure-Object | % COunt | should be 20

        $any.CollectionName[0] | should be $MyColl.Name
        $any.CollectionName[-1] | should be $MyColl1.Name

    }

    it 'Swaps' {
        $MyDev1 | Get-CMDeviceFromAnyCollection | Move-CMDeviceToCollectionFromAny -CollectionName $CollName1
        Start-WaitForCount -CollName $CollName -count 0 | should be 0
        Start-WaitForCount -CollName $CollName1 -count 20 | should be 20
    }

    it 'Swaps2' {

        $MyDev2 | Get-CMDeviceFromAnyCollection | Move-CMDeviceToCollectionFromAny -CollectionName $CollName
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10

    }

    it 'Full Purge' {
        $MyDev1 + $MyDev2 | Get-CMDeviceFromAnyCollection | Remove-CMDeviceFromAnyCollection

        Start-WaitForCount -CollName $CollName  -count 0 | Should be 0
        Start-WaitForCount -CollName $CollName1 -count 0 | Should be 0

    }
   
}

describe 'Add some stuff' {

    it 'add group1' {
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $CollName
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        get-cmdevice -CollectionName $CollName | % Name | Should be $MyDev1.Name
    }

    it 'add group2' {
        $MyDev2 | Add-CMDeviceToCollection -CollectionName $CollName 
        Start-WaitForCount -CollName $CollName -count 20 | should be 20
        get-cmdevice -CollectionName $CollName | % Name | Should be ($MyDev1.Name + $MyDev2.Name)
    }

    it 'Move group1' {
        $MyDev1 | Move-CMDeviceToCollection -CollectionName $CollName -DestCollectionName $CollName1
        Start-WaitForCount -CollName $CollName -count 10 | should be 10
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10
        get-cmdevice -CollectionName $CollName | % Name | Should be $MyDev2.Name
        get-cmdevice -CollectionName $CollName1 | % Name | Should be $MyDev1.Name
    }


    it 'remove group1' {
        $MyDev1 | Remove-CMDeviceFromCollection -CollectionName $CollName1
        Start-WaitForCount -CollName $CollName1 -count 10 | should be 10
        get-cmdevice -CollectionName $CollName | % Name | Should be $MyDev2.Name
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $CollName
        Start-WaitForCount -CollName $CollName -count 0 | out-null
    }
}



###########################

Pop-Location -StackName CM -ErrorAction SilentlyContinue
