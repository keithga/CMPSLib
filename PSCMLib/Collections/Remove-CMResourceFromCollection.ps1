<#
.Synopsis
   Removes many members from a CM Collection with only one call
.DESCRIPTION
   Uses WMI to Remove many Direct Membership rules from a SCCM Device Collection with just one DB action
.EXAMPLE
   Remove-CMDeviceFromCollection -CollectionID XXX00750 -SiteCode XXX -System $ReadyForMigrationDevices[50..70] -EchoCollectionCount 

   VERBOSE: Attempting to connect over WMI to FOXSCCM01.foxdeploy.local:\\root\SMS\Site_XXX using FoxDeploy\Admin01 credential
VERBOSE: Resolved Collection PreAssessment_Scan with root\SMS\Site_XXX
VERBOSE: Retrieving Class Object...
VERBOSE: XXX00750 direct membership rule count: 22
VERBOSE: Removing 21 rules from Collection: XXX00750
VERBOSE: XXX00750 direct membership rule count: 1

OldCount NewCount
-------- --------
      22        1
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
Function Remove-CMDeviceFromCollection {
    [CmdLetBinding()]
    Param(
        [string]   $CollectionID,
        [string]   $SiteCode,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $System,
        [pscredential]$Credential,
        [Switch]$EchoCollectionCount
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
        Write-Verbose "Removing $($Rules.Count) rules from Collection: $CollectionID"
    }
    end {
        $InParams.CollectionRules += $Rules.psobject.BaseOBject
        $CollectionQuery.PSBase.InvokeMethod('DeleteMembershipRules',$InParams,$null) | Out-null
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
