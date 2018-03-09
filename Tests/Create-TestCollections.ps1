[cmdletbinding()]
param(
    $LimitingCollectionName = 'All Systems',
    $BusinessUnits = @('ENG','OPS','SEC') ,
    $Errors = @( 'OSVer','HWInvDate','FullDisk' ),
    $environments = @( '','_DEV','_UAT' ),
    $seasons = @('Fall','Spring'),
    [switch] $PrintOnly
)

<#

Use this script to generate the collections locally for testing.
C:\Users\keith\source\repos\CMPSLib\Tests\Create-TestCollections.ps1  -environments @('')

To print this list: 
.\Create-TestCollections.ps1 -printonly -seasons @('Fall') -environments @('') | sort

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

#######

if(-not (Get-Module ConfigurationManager)) { Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" }
if (get-location | ? Provider -notlike '*CMSite') { get-PSDrive -PSProvider CMSite | Select -First 1 | %{ Push-Location "$($_)`:" -StackName CM } }

#######

# for every season turn! turn! turn!
Foreach ( $Season in $seasons ) {
    
    # Regular, Development, and UAT (Testing)
    Foreach ( $Environment in $environments ) {

        Foreach ( $Day in 1..31 ) {
            $List += 'OSD_W10{0}_{1}_Day_{2:d2}_PM' -f $Environment,$Season,$Day
        }

        Foreach ( $Operation in 'Preassessment','Precache_Compat_Scan','Finished','Ready_For_Scheduling' ) {
            $List += 'OSD_W10{0}_{1}_{2}' -f $Environment,$Season,$Operation
        }

        Foreach ( $BusinessUnit in $BusinessUnits ) {
            $List += 'OSD_W10{0}_{1}_Ready_for_PreAssessment_{2}' -f $Environment,$Season,$BusinessUnit
            $List += 'OSD_W10{0}_{1}_Ready_for_Scheduling_{2}' -f $Environment,$Season,$BusinessUnit
        }

        foreach ( $Error in $Errors ) { 
            $List += 'OSD_W10{0}_{1}_NonCompliant_{2}' -f $Environment,$Season,$Error
        }

    }

}

if ( $PrintOnly ) { $list | Write-output ; exit }

$List |
    ? { -not ( get-CMDeviceCollection -Name $_ ) } |
    % { write-verbose $_; new-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -Name $_ } |
    % Name | write-host 
