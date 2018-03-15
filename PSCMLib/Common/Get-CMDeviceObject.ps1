
function Get-CMDeviceObject {

    <#
    Replacement for Get-CMDevice, but will not be affected by scoping issues.
    #>

    [CmdletBinding( DefaultParameterSetName='DeviceNameSet')]
    param(

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='DeviceNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]    $Name,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='ResourceIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]    $ResourceID

    )

    begin {

        # Construct the connection arguments
        $WmiArgs = Get-CMSiteForWMI @PSBoundParameters

    }

    Process {

        if ( $Name ) {
            $Name | 
                foreach-object { 
                    write-verbose "SELECT * FROM SMS_R_SYSTEM Where Name = $_ "
                    if ( $_ -match '\*' ) {
                        gwmi @WmiArgs -class 'SMS_R_System' -filter "name LIKE '$($_.Replace('*','%'))'"
                    }
                    else {
                        gwmi @WmiArgs -class 'SMS_R_System' -filter "name = '$($_)'"
                    }
                } | 
                Write-Output
        }
        else {
            $ResourceID | 
                foreach-object { 
                    write-verbose "SELECT * FROM SMS_R_SYSTEM Where ResourceID  = $ResourceID "
                    gwmi @WmiArgs -class 'SMS_R_System' -filter "ResourceID='$($ResourceID)'"
                } | 
                Write-Output

        }

    }

}
