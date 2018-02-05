[cmdletbinding()]
param(
    $LimitingCollectionName = 'All Systems'
)

<#

OSD_W10_Spring_x64_Day_01_PM
OSD_W10_Spring_x64_Day_02_PM
OSD_W10_Spring_x64_Day_03_PM
OSD_W10_Spring_x64_Day_04_PM
OSD_W10_Spring_x64_Day_05_PM
OSD_W10_Spring_x64_Day_06_PM
OSD_W10_Spring_x64_Day_07_PM
OSD_W10_Spring_x64_Day_08_PM
OSD_W10_Spring_x64_Day_09_PM
OSD_W10_Spring_x64_Day_10_PM
OSD_W10_Spring_x64_Day_11_PM
OSD_W10_Spring_x64_Day_12_PM
OSD_W10_Spring_x64_Day_13_PM
OSD_W10_Spring_x64_Day_14_PM
OSD_W10_Spring_x64_Day_15_PM
OSD_W10_Spring_x64_Day_16_PM
OSD_W10_Spring_x64_Day_17_PM
OSD_W10_Spring_x64_Day_18_PM
OSD_W10_Spring_x64_Day_19_PM
OSD_W10_Spring_x64_Day_20_PM
OSD_W10_Spring_x64_Day_21_PM
OSD_W10_Spring_x64_Day_22_PM
OSD_W10_Spring_x64_Day_23_PM
OSD_W10_Spring_x64_Day_24_PM
OSD_W10_Spring_x64_Day_25_PM
OSD_W10_Spring_x64_Day_26_PM
OSD_W10_Spring_x64_Day_27_PM
OSD_W10_Spring_x64_Day_28_PM
OSD_W10_Spring_x64_Day_29_PM
OSD_W10_Spring_x64_Day_30_PM
OSD_W10_Spring_x64_Day_31_PM
OSD_W10_Spring_x64_Preassessment
OSD_W10_Spring_x64_Precache_Compat_Scan
OSD_W10_Spring_x64_Finished
OSD_W10_Spring_x64_Ready_For_Scheduling
OSD_W10_Spring_x64_ENG_Ready_for_PreAssessment
OSD_W10_Spring_x64_OPS_Ready_for_PreAssessment
OSD_W10_Spring_x64_SEC_Ready_for_PreAssessment
OSD_W10_Fall_x64_Day_01_PM
OSD_W10_Fall_x64_Day_02_PM
OSD_W10_Fall_x64_Day_03_PM
OSD_W10_Fall_x64_Day_04_PM
OSD_W10_Fall_x64_Day_05_PM
OSD_W10_Fall_x64_Day_06_PM
OSD_W10_Fall_x64_Day_07_PM
OSD_W10_Fall_x64_Day_08_PM
OSD_W10_Fall_x64_Day_09_PM
OSD_W10_Fall_x64_Day_10_PM
OSD_W10_Fall_x64_Day_11_PM
OSD_W10_Fall_x64_Day_12_PM
OSD_W10_Fall_x64_Day_13_PM
OSD_W10_Fall_x64_Day_14_PM
OSD_W10_Fall_x64_Day_15_PM
OSD_W10_Fall_x64_Day_16_PM
OSD_W10_Fall_x64_Day_17_PM
OSD_W10_Fall_x64_Day_18_PM
OSD_W10_Fall_x64_Day_19_PM
OSD_W10_Fall_x64_Day_20_PM
OSD_W10_Fall_x64_Day_21_PM
OSD_W10_Fall_x64_Day_22_PM
OSD_W10_Fall_x64_Day_23_PM
OSD_W10_Fall_x64_Day_24_PM
OSD_W10_Fall_x64_Day_25_PM
OSD_W10_Fall_x64_Day_26_PM
OSD_W10_Fall_x64_Day_27_PM
OSD_W10_Fall_x64_Day_28_PM
OSD_W10_Fall_x64_Day_29_PM
OSD_W10_Fall_x64_Day_30_PM
OSD_W10_Fall_x64_Day_31_PM
OSD_W10_Fall_x64_Preassessment
OSD_W10_Fall_x64_Precache_Compat_Scan
OSD_W10_Fall_x64_Finished
OSD_W10_Fall_x64_Ready_For_Scheduling
OSD_W10_Fall_x64_ENG_Ready_for_PreAssessment
OSD_W10_Fall_x64_OPS_Ready_for_PreAssessment
OSD_W10_Fall_x64_SEC_Ready_for_PreAssessment
#>

$List = @()

# for every season turn! turn! turn!
Foreach ( $Season in 'Spring','Fall' ) {
    
    # For now, only x64
    Foreach ( $Platform in 'x64' ) {

        Foreach ( $Day in 1..31 ) {
            $List += 'OSD_W10_{0}_{1}_Day_{2:d2}_PM' -f $Season,$Platform,$Day
        }

        Foreach ( $Operation in 'Preassessment','Precache_Compat_Scan','Finished','Ready_For_Scheduling' ) {
            $List += 'OSD_W10_{0}_{1}_{2}' -f $Season,$Platform,$Operation
        }

        Foreach ( $BusinessUnit in 'ENG','OPS','SEC' ) {
            $List += 'OSD_W10_{0}_{1}_{2}_Ready_for_PreAssessment' -f $Season,$Platform,$BusinessUnit
        }

    }

}

$List |
    ? { -not ( get-CMDeviceCollection -Name $_ ) } |
    % { write-verbose $_; new-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -Name $_ } |
    % Name | write-host 
