<#
Naming convention for CM collections
#>

$OSDW10Prefix = 'OSD_W10'

function get-OSDW10Prefix { $OSDW10Prefix }
function get-EnumOSDOperations { @('Preassessment','Precache_Compat_Scan','Finished','Ready_For_Scheduling') }


###############################################################################

function Format-WAASStdName {
    param( $EnvName = '', $Season, $Name )
    '{0}{1}_{2}_{3}' -f $OSDW10Prefix, $envName,$Season,$Name
}

function Format-WAASStdErr {
    param( $EnvName = '', $Season, $Err )
    Format-WAASStdName -EnvName $EnvName -Season $Season -Name ('NonCompliant_{0}' -f $Err)
}

function Format-WAASStdDay  {
    param( $EnvName = '', $Season, $Day )
    Format-WAASStdName -EnvName $EnvName -Season $Season -Name ('{0:d2}_PM' -f $Day)
}


function Format-WAASPreAssessGroup  {
    param( $EnvName = '', $Season, $Group )
    Format-WAASStdName -EnvName $EnvName -Season $Season -Name ('Ready_for_PreAssessment_{0}' -f $Group)
}

function Format-WAASScheduling  {
    param( $EnvName = '', $Season, $Group )
    Format-WAASStdName -EnvName $EnvName -Season $Season -Name ('Ready_for_Scheduling_{0}' -f $Group)
}

