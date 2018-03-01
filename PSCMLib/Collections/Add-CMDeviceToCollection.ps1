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
.PARAMETER Credential
    Provide this credential to use an alternate credential for the WMI Operations
#>
Function Add-CMDeviceToCollection {
    [CmdLetBinding()]
    Param(
        [string]   $CollectionID,
        [string]   $SiteCode,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $System,
        [pscredential]$Credential,
        [switch]$EchoCollectionCount
    )

    begin {               
        if ($Credential){
            $WmiArgs = @{ NameSpace = "root\SMS\Site_$SiteCode"; ComputerName = $CMDBServer; Credential = $Credential }
            Write-Verbose "Will be using $($Credential.UserName) for this connection"
        }
        else {
            $WmiArgs = @{ NameSpace = "root\SMS\Site_$SiteCode"; ComputerName = $CMDBServer}
        }
        
        Write-Verbose "Attempting to connect over WMI to $($WmiArgs.ComputerName):\\$($WmiArgs.NameSpace)"
        $CollectionCount = [pscustomObject]@{'OldCount'=$null;'NewCount'=$null}
        $CollectionQuery = Get-WmiObject @WMIArgs -Class SMS_Collection -Filter "CollectionID = '$CollectionID' and CollectionType='2'" -ErrorAction Stop 
        if ($CollectionQuery){
            Write-Verbose "Resolved Collection $($CollectionQuery.Name) with $($WmiArgs.NameSpace)"
            $InParams = $CollectionQuery.PSBase.GetMethodParameters('AddMembershipRules')
            Write-Verbose "Retrieving Class Object..."
            $cls = Get-WmiObject @WMIArgs -Class SMS_CollectionRuleDirect -list -ErrorAction Stop       
            $Rules = @()
        }
        else{
            throw
        }
        
        if ($EchoCollectionCount){
            $MemberCount = Get-WmiObject @WMIArgs -class 'SMS_Collection' -Filter "CollectionID='$CollectionID'"
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
        Write-Verbose "Adding $($Rules.Count) rules to Collection: $CollectionID"
    }
    end {
        $InParams.CollectionRules += $Rules.psobject.BaseOBject
        $CollectionQuery.PSBase.InvokeMethod('AddMembershipRules',$InParams,$null) | Out-null
        $CollectionQuery.RequestRefresh() | out-null

        if ($EchoCollectionCount){
            $MemberCount = Get-WmiObject @WMIArgs -class 'SMS_Collection' -Filter "CollectionID='$CollectionID'" 
            $MemberCount.Get()
            $CollectionCount.NewCount = $MemberCount.CollectionRules.Count
            Write-Verbose "$CollectionID direct membership rule count: $($CollectionCount.NewCount)"
            return $CollectionCount
        }
    }
}
