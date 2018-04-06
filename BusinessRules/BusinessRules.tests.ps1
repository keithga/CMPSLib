<#

Pester tests for collections

for the love of god, please do not run on a production machine

elevate sql studio and grant yourself db_owner role

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname = 'cm1.corp.contoso.com',
    $Database = 'ConfigMGR_CHQ',
    $Path = "$env:temp\BusinessRules",
    $PCNames1  = 'DTC00001*',
    $LogPath = "$env:userProfile\desktop\businessRules.log"
)

Import-Module "$PSScriptRoot\..\PSCMLib" -force -ErrorAction SilentlyContinue 
if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }

###########################

function Start-WaitForCount {
    param( $CollName, $Count )
    # Sometimes it takes a while for the collection membership to report a change. Wait!

    $i = 0
    while ( ( get-cmdevice -CollectionName $CollName | measure-object | ? Count -ne $Count ) -and ( $i -lt 30 ) ) {
        Write-Progress -Activity "CollectionMembershipChange $CollName $i"
        start-sleep 1
        $i += 1
    }
    write-progress -Activity 'CollectionMembershipChange' -Completed
    get-cmdevice -CollectionName $CollName | measure-object | % Count | Write-Output
}

function insert-SQLData {
    [cmdletbinding()]
    param ( $hostname, $Database, $CollectionName, $Name, [int] $Status = 11143 )

    $Dep  = get-cmdeployment -CollectionName $CollectionName | % DeploymentID
    $Res  = Get-CMDevice -name $Name | % ResourceID

    $SQL = @"
INSERT INTO [dbo].[TaskExecutionStatus]
           ([OfferID] ,[ItemKey]
           ,[ExecutionTime]
           ,[Step] ,[ActionName] ,[GroupName]
           ,[LastStatus] ,[ExitCode]
           ,[ActionOutput] ,[ActionTypeName])
     VALUES
           ('{0}' , {1}
           ,GetDate()
           ,20 ,'Some Action' ,'Some Group'
           ,{2} ,0
           ,'Hello WOrld' ,'SomeType')

"@ -f $Dep, $Res, $Status

    write-verbose $SQL
    Invoke-SQLCMD -HostName $HostName -Database $Database -Query $SQL
}

###########################

write-verbose "Clean Everything"

# get-cmdeviceobject -Name $PCNames1 | measure-object | % Count

$Found = Get-CMDeviceobject -Name $PCNames1 | Get-CMDeviceFromAnyCollection 
$Found | Remove-CMDeviceFromAnyCollection
$Found | Group -Property CollectionName | 
    ForEach-Object { Start-WaitForCount -CollName $_.Name -Count 0 }

if ( test-path $Path ) { remove-item -Path $path -Recurse -force -ErrorAction SilentlyContinue } 
if ( test-path $logPath ) { remove-item -Path $logPath -Recurse -force -ErrorAction SilentlyContinue } 


###########################

$myArgs = @{
    HostName = $HostName
    Database = $database
    Path = $Path
    LogPath = $LogPath
}

$PCNames1  = 'DTC00001*'
$MyDev1 = get-cmDeviceObject -Name $PCNames1

###########################

describe 'verify environment' {

    $MyDev1 | Measure-Object | % count | should be 10

    get-cmDeviceObject -Name $PCNames1 | % Name | should be (0..9 | %{ $PCNames1.replace('*','{0}') -f $_ })

    Get-CMDeviceobject -Name $PCNames1 | Get-CMDeviceFromAnyCollection | Measure-Object | % Count | should be 0

    get-cmdeployment -CollectionName ( Format-WAASStdName -Season '*' -Name Precache_Compat_Scan ) | should not be $null
    get-cmdeployment -CollectionName ( Format-WAASStdDay -Season '*' -Day 15 ) | should not be $null

    test-path $path | should be $False

}

###########################



describe 'Job 1 PreAssess Group to PreAssess - Mock' {

    $SourceName = Format-WAASPreAssessGroup -Season 'Fall' -Group 'ENG'
    $TargetName = Format-WAASStdName -Season 'Fall' -Name 'Preassessment'
    write-host "From: $SourceName    To: $TargetName"

    it 'add  PreAssess Group mock' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName -whatif
        Start-WaitForCount -CollName $SourceName -count 0 | should be 0
    }

    it 'add  PreAssess Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'remove all mock' {
        $MyDev1 | Remove-CMDeviceFromCollection -CollectionName $SourceName -whatif
        Start-WaitForCount -CollName $SourceName -count 10 | out-null
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
    }

}

describe 'Job 4a ready for scheduling to Day of... mock' {

    $SourceName = Format-WAASStdName -Season 'Fall' -Name 'Ready_For_Scheduling'
    $TargetName = Format-WAASStdDay -Season 'Fall' -Day 15
    $TargetFile = join-path $Path\ScheduleDay ([guid]::NewGuid().ToString() + '.clixml')

    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Go Time' {
        remove-item $path -ErrorAction SilentlyContinue -Recurse -Force | out-null
        new-item -ItemType directory -Path $path\ScheduleDay -erroraction SilentlyContinue | out-null

        @{
            Systems = $MyDev1
            SourceCollection = $SourceName
            TargetCollection = 'DAY_15_8PM'
            WaitUntil = [datetime]::now.AddDays(-1)
        } | Export-Clixml -Path $TargetFile -Force

    }

    it 'Run Job4b' {

        { & $PSScriptRoot\step-Job4scheduling.ps1 @MyArgs -whatif } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 10| should be 10
        Start-WaitForCount -CollName $TargetName -Count 0| should be 0

        test-path $TargetFile | should be $true
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
    }

}


describe 'Job 1 PreAssess Group to PreAssess' {

    $SourceName = Format-WAASPreAssessGroup -Season 'Fall' -Group 'ENG'
    $TargetName = Format-WAASStdName -Season 'Fall' -Name 'Preassessment'
    write-host "From: $SourceName    To: $TargetName"

    it 'add  PreAssess Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Run Job1' {

        { & $PSScriptRoot\step-Job1Start.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 10 | out-null
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $TargetName
        Start-WaitForCount -CollName $TargetName -count 0 | out-null
    }

}

describe 'Job 2 PreAssess to Precache_Compat_Scan' {

    # Does not really do anything... 

    $SourceName = Format-WAASStdName -Season 'Fall' -Name 'Preassessment'
    $TargetName = Format-WAASStdName -Season 'Fall' -Name 'Precache_Compat_Scan'
    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Run Job2' {
        # TBD ( currently does nothing )
        { & $PSScriptRoot\step-Job2PreAssessment.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
    }

}

describe 'Job 3 PReCache_Compat_Scan to ready for scheduling' {

    $SourceName = Format-WAASStdName -Season 'Fall' -Name 'Precache_Compat_Scan'
    $TargetName = Format-WAASStdName -Season 'Fall' -Name 'Ready_For_Scheduling'
    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Fake Data' {
        # Create 9 records for success, and one for failure
        { $MyDev1 | Select-object -first 9 |             
            %{ 
                insert-sqldata -hostname $hostname -Database $Database -CollectionName (Format-WAASStdName -Season 'Fall' -Name 'Precache_Compat_Scan') -name $_.Name 
            } }| should not throw
        { $MyDev1 | Select-object -last 1 |             
            %{ 
                insert-sqldata -hostname $hostname -Database $Database -CollectionName (Format-WAASStdName -Season 'Fall' -Name 'Precache_Compat_Scan') -name $_.Name -Status 11141
            } }| should not throw
    }

    it 'Run Job3' {

        { & $PSScriptRoot\step-Job3PreCacheCompat.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $TargetName -Count 9 | should be 9
        Start-WaitForCount -CollName $SourceName -count 1 | should be 1
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $TargetName
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
        Start-WaitForCount -CollName $TargetName -count 0 | out-null
    }

}

describe 'Job 4 ready for scheduling to Day of...' {

    $SourceName = Format-WAASStdName -Season 'Fall' -Name 'Ready_For_Scheduling'
    $TargetName = Format-WAASStdDay -Season 'Fall' -Day 15
    $TargetFile = join-path $Path\ScheduleDay ([guid]::NewGuid().ToString() + '.clixml')

    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Too Far in the future' {
        remove-item $path -ErrorAction SilentlyContinue -Recurse -Force | out-null
        new-item -ItemType directory -Path $path\ScheduleDay -erroraction SilentlyContinue | out-null

        @{
            Systems = $MyDev1
            SourceCollection = $SourceName
            TargetCollection = 'DAY_15_8PM'
            WaitUntil = [datetime]::now.AddDays(20)
        } | Export-Clixml -Path $TargetFile

    }

    it 'Run Job4a' {

        { & $PSScriptRoot\step-Job4scheduling.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 10| should be 10
        Start-WaitForCount -CollName $TargetName -Count 0| should be 0

        test-path $TargetFile | should be $True
    }

    it 'Go Time' {
        remove-item $path -ErrorAction SilentlyContinue -Recurse -Force | out-null
        new-item -ItemType directory -Path $path\ScheduleDay -erroraction SilentlyContinue | out-null

        @{
            Systems = $MyDev1
            SourceCollection = $SourceName
            TargetCollection = 'DAY_15_8PM'
            WaitUntil = [datetime]::now.AddDays(-1)
        } | Export-Clixml -Path $TargetFile -Force

    }

    it 'Run Job4b' {

        { & $PSScriptRoot\step-Job4scheduling.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 0| should be 0
        Start-WaitForCount -CollName $TargetName -Count 10| should be 10

        test-path $TargetFile | should be $false
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $TargetName
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
        Start-WaitForCount -CollName $TargetName -count 0 | out-null
    }

}

describe 'Job 5 ready for processing day of...' {

    $SourceName = Format-WAASStdDay -Season 'Fall' -Day 15
    $TargetName = Format-WAASStdName -Season 'Fall' -Name 'Finished'

    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | Add-CMDeviceToCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 10 | should be 10
    }

    it 'Fake Data' {
        # Create 9 records for success, and one for failure
        { $MyDev1 | Select-object -first 9 |             
            %{ 
                insert-sqldata -hostname $hostname -Database $Database -CollectionName (Format-WAASStdDay -Season 'Fall' -Day 15) -name $_.Name 
            } }| should not throw
        { $MyDev1 | Select-object -last 1 |             
            %{ 
                insert-sqldata -hostname $hostname -Database $Database -CollectionName (Format-WAASStdDay -Season 'Fall' -Day 15) -name $_.Name -Status 11141
            } }| should not throw
    }

    it 'Run Job5' {

        { & $PSScriptRoot\step-Job5DailyCleenup.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 1| should be 1
        Start-WaitForCount -CollName $TargetName -Count 9| should be 9
    }

    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $TargetName
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
        Start-WaitForCount -CollName $TargetName -count 0 | out-null
    }

}

describe 'Job 6 Cancel operation' {

    $SourceName = Format-WAASStdName -Season 'Fall' -Name 'Ready_For_Scheduling'
    $TargetName = Format-WAASStdDay -Season 'Fall' -Day 15
    $TargetFile = join-path $Path\RemoveItems ([guid]::NewGuid().ToString() + '.clixml')

    write-host "From: $SourceName    To: $TargetName"

    it 'add  source Group' {
        Start-WaitForCount -CollName $SourceName -Count 0 | out-null
        Start-WaitForCount -CollName $TargetName -Count 0 | out-null
        $MyDev1 | select -first 5 |Add-CMDeviceToCollection -CollectionName $SourceName
        $MyDev1 | select -last  5 |Add-CMDeviceToCollection -CollectionName $Targetname
        Start-WaitForCount -CollName $SourceName -count 5 | should be 5
        Start-WaitForCount -CollName $Targetname -count 5 | should be 5
    }

    it 'Create Cancel List' {
        remove-item $path -ErrorAction SilentlyContinue -Recurse -Force | out-null
        new-item -ItemType directory -Path $path\RemoveItems -erroraction SilentlyContinue | out-null

        @{
            Systems = $MyDev1[3],$MyDev1[8]
        } | Export-Clixml -Path $TargetFile -force

    }

    it 'Run Job6' {

        { & $PSScriptRoot\step-Job6Cancel.ps1 @MyArgs } | should not throw
        Start-WaitForCount -CollName $SourceName -Count 4| should be 4
        Start-WaitForCount -CollName $TargetName -Count 4| should be 4

        test-path $TargetFile | should be $false
    }


    it 'remove all' {
        Remove-CMAllDevicesFromCollection -CollectionName $TargetName
        Remove-CMAllDevicesFromCollection -CollectionName $SourceName
        Start-WaitForCount -CollName $SourceName -count 0 | out-null
        Start-WaitForCount -CollName $TargetName -count 0 | out-null
    }

}

###########################

Pop-Location -StackName CM -ErrorAction SilentlyContinue
