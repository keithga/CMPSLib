
function Get-CMDeviceObject {

    <#
    Replacement for Get-CMDevice, but will not be affected by scoping issues.
    #>

    [CmdletBinding( DefaultParameterSetName='DeviceNameSet')]
    param(

        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ParameterSetName='DeviceNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]    $Name

    )

    begin {

        # Construct the connection arguments
        $WmiArgs = Get-CMSiteForWMI @PSBoundParameters
        $Names = @()

    }

    Process {
        $Names += $Name
    }

    end {

        $QueryGroup = @()

        if ( $Names.count -gt 0 ) {

            $Query = ''
            foreach ( $Name in $Names ) {

                if ( $Name -match '\*' ) {
                    $QUery += " or name LIKE '$($Name.Replace('*','%'))'"
                }
                else {
                    $Query += " or name='$($Name)'"
                }          

                if ( $Query.Length -gt 13000 ) {
                    $QUeryGroup += $Query.trim(' or')
                    $Query = ''
                }
            } 

            if ( $QUery.Length -gt 0 ) { 
                $QueryGroup += $QUery.trim(' or')
            }

        }

        $QUeryGroup | 
            ForEach-Object {
                write-verbose "QUery: $($_.Length)"
                gwmi @WmiArgs -class 'SMS_R_System' -filter $_ | Write-Output
            }
       

    }
}
