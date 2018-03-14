<#
Naming convention for CM collections
#>

$OSDW10Prefix = '{0}'

function Format-WAASStdName {
    param( $EnvName = '', $Season, $Name )
    '{0}{1}_{2}_{3}' -f $OSDW10Prefix, $envName,$Season,$Name
}

function Format-WAASStdErr {
    param( $EnvName = '', $Season, $Err )
    '{0}{1}_{2}_NonCompliant_{3}' -f $OSDW10Prefix, $envName,$Season,$Err
}

function Format-WAASStdDay  {
    param( $EnvName = '', $Season, $Day )
    '{0}{1}_{2}_Day_{3:d2}_PM' -f $OSDW10Prefix, $envName,$Season,$Day
}

