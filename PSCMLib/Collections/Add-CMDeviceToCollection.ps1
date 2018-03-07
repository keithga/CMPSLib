<#
.Synopsis
   Adds many members to a CM Collection with only one call
.DESCRIPTION
   Uses WMI to add many Direct Membership rules to a SCCM Device Collection with just one DB action
.EXAMPLE
   Add-CMDeviceToCollection -CollectionID XXX00750 -SiteCode XXX -System $ReadyForMigrationDevices[50..70] -EchoCollectionCount 
.EXAMPLE
   Another example of how to use this cmdlet
.NOTES
   Author Keith Garner
          Stephen Owen

    URL   https://keithga.wordpress.com/2018/01/25/a-replacement-for-sccm-add-cmdevicecollectiondirectmembershiprule-powershell-cmdlet/
.PARAMETER CollectionID
    The SMS Collection ID to which the devices should be added
.PARAMETER SITECODE
    The SMS_XXX SiteCode of the CM Instance
.PARAMETER SYSTEM
    An array of SMS_Resource Objects to add to the collection (must contain both a devicename and ResourceID property)
.PARAMETER EchoCollectionCount    
    When this switch is present detailed collection count information will be displayed before and after operations
.PARAMETER ComputerName
    This command supports operating against remote computers.  Provide the computer name of the SCCM Site Server with this param.
.PARAMETER Credential
    Provide this credential to use an alternate credential for the WMI Operations
#>
Function Add-CMDeviceToCollection {
    [CmdLetBinding()]
    Param(
        
        [Parameter(Mandatory=$true, 
                   Position=0,
                   ParameterSetName='CollNameSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')] 
        [string]    $CollectionName,
        [Parameter(Mandatory=$true, 
                   Position=0,
                   ParameterSetName='CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string]    $CollectionID,
        [parameter(Mandatory=$true,
                   ParameterSetName = 'CollNameSet')]
        [parameter(ParameterSetName = 'CollIDSet')]
        [string]    $SiteCode,
        [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ParameterSetName = 'CollNameSet')]
        [parameter(ParameterSetName = 'CollIDSet')]
        [string[]]  $System,
        [pscredential]$Credential,
        [parameter(Mandatory=$false, 
                   ParameterSetName = 'CollNameSet')]
        [parameter(ParameterSetName = 'CollIDSet')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('SMSSiteServerName')] 
        [string]    $ComputerName, 
        [switch]    $EchoCollectionCount
    )

    begin {               
        $WmiArgs = @{ NameSpace = "root\SMS\Site_$SiteCode"}
        $CollectionCount = [pscustomObject]@{'OldCount'a=$null;'NewCount'=$null}

        if ($PSBoundParameters.ContainsKey('CollectionID')){
            $WMIArgs.Add('Filter', "CollectionID = '$CollectionID' and CollectionType='2'")
        }
        
        if ($PSBoundParameters.ContainsKey('CollectionName')){{
            $WMIArgs.Add('Filter', "CollectionName = '$CollectionName' and CollectionType='2'")
        }
        
        if ($PSBoundParameters.ContainsKey('ComputerName')){
            $WmiArgs.Add('ComputerName', $ComputerName)
        }

        if ($PSBoundParameters.ContainsKey('Credential')){
            $WmiArgs.Add(Credential, $Credential)
            Write-Verbose "Will be using $($Credential.UserName) for this connection"
        }
        write-debug "test param build out here"
        
        $CollectionRef = Get-WmiObject @WMIArgs -Class SMS_Collection -Filter $WMIFilter -ErrorAction Stop 
        if ($CollectionRef){
            Write-Verbose "Resolved Collection $($CollectionRef.Name) with $($WmiArgs.NameSpace)"
            $InParams = $CollectionQuery.PSBase.GetMethodParameters('AddMembershipRules')
            Write-Verbose "Retrieving Class Object..."
            $cls = Get-WmiObject @WMIArgs -Class SMS_CollectionRuleDirect -list -ErrorAction Stop       
            $Rules = @()
        }
        else{
            throw
        }
        
        if ($EchoCollectionCount){
            $MemberCount = Get-WmiObject @WMIArgs -class 'SMS_Collection' -Filter "CollectionID='$($CollectionRef.CollectionID)'"
            $MemberCount.Get()
            $CollectionCount.OldCount = $MemberCount.CollectionRules.Count
            Write-Verbose "$CollectionID direct membership rule count: $($CollectionCount.OldCount)"
        }
    }
    process {
        foreach ( $sys in $System ) {
            $NewRule = $cls.CreateInstance()
            $NewRule.ResourceClassName = "SMS_R_System"
            $NewRule.ResourceID = $sys.ResourceID
            $NewRule.Rulename = $sys.Name
            $Rules += $NewRule.psobject.BaseObject 
        }
        Write-Verbose "Adding $($Rules.Count) rules to Collection: $($CollectionID,$CollectionName)"
    }
    end {
        $InParams.CollectionRules += $Rules.psobject.BaseOBject
        $CollectionRef.PSBase.InvokeMethod('AddMembershipRules',$InParams,$null) | Out-null
        $CollectionRef.RequestRefresh() | out-null

        if ($EchoCollectionCount){
            $MemberCount = Get-WmiObject @WMIArgs -class 'SMS_Collection' -Filter "CollectionID='$($CollectionRef.CollectionID)'"
            $MemberCount.Get()
            $CollectionCount.NewCount = $MemberCount.CollectionRules.Count
            Write-Verbose "$CollectionID direct membership rule count: $($CollectionCount.NewCount)"
            return $CollectionCount
        }
    }
}
