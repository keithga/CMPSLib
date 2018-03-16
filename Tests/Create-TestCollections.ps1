[cmdletbinding()]
param(
    $LimitingCollectionName = 'All Systems',
    $BusinessUnits = @('ENG','OPS','SEC') ,
    $Errors = @( 'OSVer','HWInvDate','FullDisk' ),
    $environments = @( '','_DEV','_UAT' ),
    $seasons = @('Fall','Spring'),
    [switch] $Stripe,
    [switch] $PrintOnly
)

<#

Use this script to generate the collections locally for testing.
C:\Users\keith\source\repos\CMPSLib\Tests\Create-TestCollections.ps1  -environments @('')

To print this list: 
.\Create-TestCollections.ps1 -printonly -seasons @('Fall') -environments @('') | sort

Get-CMCollection -name osd_w10* | % Name | sort

OSD_W10_Fall_Ready_for_PreAssessment_ENG
OSD_W10_Fall_Ready_for_PreAssessment_OPS
OSD_W10_Fall_Ready_for_PreAssessment_SEC

OSD_W10_Fall_Preassessment

OSD_W10_Fall_Precache_Compat_Scan

OSD_W10_Fall_Ready_For_Scheduling

OSD_W10_Fall_Ready_for_Scheduling_ENG
OSD_W10_Fall_Ready_for_Scheduling_OPS
OSD_W10_Fall_Ready_for_Scheduling_SEC

OSD_W10_Fall_Day_01_PM
OSD_W10_Fall_Day_02_PM
OSD_W10_Fall_Day_03_PM
OSD_W10_Fall_Day_04_PM
OSD_W10_Fall_Day_05_PM
OSD_W10_Fall_Day_06_PM
OSD_W10_Fall_Day_07_PM
OSD_W10_Fall_Day_08_PM
OSD_W10_Fall_Day_09_PM
OSD_W10_Fall_Day_10_PM
OSD_W10_Fall_Day_11_PM
OSD_W10_Fall_Day_12_PM
OSD_W10_Fall_Day_13_PM
OSD_W10_Fall_Day_14_PM
OSD_W10_Fall_Day_15_PM
OSD_W10_Fall_Day_16_PM
OSD_W10_Fall_Day_17_PM
OSD_W10_Fall_Day_18_PM
OSD_W10_Fall_Day_19_PM
OSD_W10_Fall_Day_20_PM
OSD_W10_Fall_Day_21_PM
OSD_W10_Fall_Day_22_PM
OSD_W10_Fall_Day_23_PM
OSD_W10_Fall_Day_24_PM
OSD_W10_Fall_Day_25_PM
OSD_W10_Fall_Day_26_PM
OSD_W10_Fall_Day_27_PM
OSD_W10_Fall_Day_28_PM
OSD_W10_Fall_Day_29_PM
OSD_W10_Fall_Day_30_PM
OSD_W10_Fall_Day_31_PM

OSD_W10_Fall_Finished

OSD_W10_Fall_NonCompliant_FullDisk
OSD_W10_Fall_NonCompliant_HWInvDate
OSD_W10_Fall_NonCompliant_OSVer

#>

$List = @()

$ErrorActionPreference = 'stop'

if(-not (Get-Module PSCMLib)) { Import-Module "$PSScriptRoot\..\PSCMLib" }

#######
if ( -not $PrintOnly ) {
    if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
    if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }
}

#######

# for every season turn! turn! turn!
Foreach ( $Season in $seasons ) {
    
    # Regular, Development, and UAT (Testing)
    Foreach ( $Environment in $environments ) {

        Foreach ( $Day in 1..31 ) {
            # 'OSD_W10{0}_{1}_Day_{2:d2}_PM' -f $Environment,$Season,$Day
            $List += Format-WAASStdDay -EnvName $environment -Season $Season -Day $Day
        }

        Foreach ( $Operation in (get-EnumOSDOperations) ) {
            # 'OSD_W10{0}_{1}_{2}' -f $Environment,$Season,$Operation 
            $List += Format-WAASStdName -EnvName $environment -Season $Season -Name $Operation
        }

        Foreach ( $BusinessUnit in $BusinessUnits ) {
            # 'OSD_W10{0}_{1}_Ready_for_PreAssessment_{2}' -f $Environment,$Season,$BusinessUnit
            $List += Format-WAASPreAssessGroup -EnvName $environment -Season $Season -Group $BUsinessUnit
            # 'OSD_W10{0}_{1}_Ready_for_Scheduling_{2}' -f $Environment,$Season,$BusinessUnit
            $List += Format-WAASScheduling -EnvName $environment -Season $Season -Group $BUsinessUnit
        }

        foreach ( $Err in $Errors ) { 
            # $List += 'OSD_W10{0}_{1}_NonCompliant_{2}' -f $Environment,$Season,$Err
            $List += Format-WAASStdErr -EnvName $environment -Season $Season -Err $Err
        }

    }

}

if ( $Stripe ) {
    foreach ( $Unit in $BusinessUnits ) {
        Foreach ( $Group  in "Alpha","Bravo","Charlie","Delta" ) { 
            $List += '{0}_OSD_W10_{1}' -f $unit,$Group
        }
    }
}

if ( $PrintOnly ) { $list | Write-output ; exit }

$List |
    ? { -not ( get-CMDeviceCollection -Name $_ ) } |
    % { write-verbose $_; new-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -Name $_ } |
    % Name | write-host 
