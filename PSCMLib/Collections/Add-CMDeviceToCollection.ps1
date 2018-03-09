
Function Add-CMDeviceToCollection {
    <#
    .SYNOPSIS
    Adds many members to a CM Collection with only one call
    .DESCRIPTION
    Uses WMI to add many Direct Membership rules to a SCCM Device Collection with just one DB action
    .EXAMPLE
    Add-CMDeviceFromCollection -CollectionID XXX00750 -System $ReadyForMigrationDevices[50..70] -passthru
    .NOTES
    Keith Garner with input from  Stephen Owen ( 1RedOne )
    .LINK
    https://keithga.wordpress.com/2018/01/25/a-replacement-for-sccm-add-cmdevicecollectiondirectmembershiprule-powershell-cmdlet/

    .PARAMETER CollectionID
    The SMS Collection ID to which the devices should be added
    .PARAMETER CollectionName
    The SMS Collection Name to which the devices should be added

    .PARAMETER SYSTEM
    An array of SMS_Resource Objects to add to the collection (must contain both a devicename and ResourceID property)
    .PARAMETER Credential
    Provide this credential to use an alternate credential for the WMI Operations
    .PARAMETER SiteCode
    Provide this Site Code for the specific Site.
    .PARAMETER ComputerName
    Server used to connect over WMI
    .PARAMETER PassThru
    Return the Member count before and after the additions
    #>

    [CmdLetBinding()]
    Param(

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $CollectionName,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $CollectionID,

        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollNameSet')]
        [parameter(Mandatory=$true,  ValueFromPipeline=$true, ParameterSetName = 'CollIDSet')]
        $System,

        [Alias('SMSSiteServerName')] 
        [string]    $ComputerName,
        [string]    $SiteCode,
        [pscredential]$Credential,

        [switch] $PassThru

    )

    begin {
        # Construct the connection arguments
        $WmiArgs = Get-CMSiteForWMI @PSBoundParameters

        if ( $CollectionName ) {
            $Filter = "Name = '$CollectionName' and CollectionType='2'"
        }
        else {
            $Filter = "CollectionID = '$CollectionID' and CollectionType='2'"
        }

        Write-Verbose "Get WMI SMS_Collection $CollectionName $COllectionID to $($WMIArgs| out-string)"
        $CollectionQuery = Get-WmiObject @WMIArgs -Class SMS_Collection -ErrorAction Stop -Filter $Filter

        ################ 

        Write-Verbose "Resolved Collection $($CollectionQuery.Name) with $($WmiArgs.NameSpace)"
        $InParams = $CollectionQuery.PSBase.GetMethodParameters('AddMembershipRules')
        Write-Verbose "Retrieving Class Object SMS_CollectionRuleDirect ..."
        $cls = Get-WmiObject @WMIArgs -Class SMS_CollectionRuleDirect -list -ErrorAction Stop
        $Rules = @()

        $MemberCount = Get-WmiObject @WMIArgs -Class SMS_Collection -ErrorAction Stop -Filter $Filter
        $MemberCount.Get()
        Write-Verbose "$Filter direct membership rule count: $($MemberCount.CollectionRules.Count)"
        $FoundList = $MemberCount.CollectionRules.ResourceID

    }
    process {
        foreach ( $sys in $System ) {
            if ( $sys.resourceID -notin $FOundList ) {
                $NewRule = $cls.CreateInstance()
                $NewRule.ResourceClassName = "SMS_R_System"
                $NewRule.ResourceID = $sys.ResourceID
                $NewRule.Rulename = $sys.Name
                $Rules += $NewRule.psobject.BaseObject 
            }
        }
    }
    end {
        if ( $Rules.Count -eq 0 ) { write-verbose "nothing to do"; exit }
        Write-Verbose "Adding $($Rules.Count) rules to Collection: $CollectionID"

        $InParams.CollectionRules += $Rules.psobject.BaseOBject
        $CollectionQuery.PSBase.InvokeMethod('AddMembershipRules',$InParams,$null) | out-string -Width 200 | write-verbose
        $CollectionQuery.RequestRefresh() | out-string -Width 200 | write-verbose

        if ( $VerbosePreference -eq 'continue' -or $PassThru ) {
            $MemberCount = Get-WmiObject @WMIArgs -Class SMS_Collection -ErrorAction Stop -Filter $Filter
            start-sleep -Seconds 1  # flush
            $MemberCount.Get()
            Write-Verbose "$Filter direct membership rule count: $($MemberCount.CollectionRules.Count)"
            if ( $PassThru ) { $MemberCount | Write-Output }
        }

    }
}
