
Function Remove-CMResourceFromCollection {
    <#

    https://keithga.wordpress.com/2018/01/25/a-replacement-for-sccm-add-cmdevicecollectiondirectmembershiprule-powershell-cmdlet/

    #>

    [CmdLetBinding()]
    Param(
        [string]   $CollectionName,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $System
    )

    begin {
        $WmiArgs = Get-CMSiteForWMI
        $CollectionQuery = Get-WmiObject @WMIArgs -Class SMS_Collection -Filter "Name = '$CollectionName' and CollectionType='2'"
        $InParams = $CollectionQuery.PSBase.GetMethodParameters('DeleteMembershipRules')
        $Cls = [WMIClass]"\\$($WMIArgs.ComputerName)\$($WmiArgs.NameSpace):SMS_CollectionRuleDirect"
        $Rules = @()
    }
    process {
        foreach ( $sys in $System ) {
            $NewRule = $cls.CreateInstance()
            $NewRule.ResourceClassName = "SMS_R_System"
            $NewRule.ResourceID = $sys.ResourceID
            $NewRule.Rulename = $sys.Name
            $Rules += $NewRule.psobject.BaseObject 
        }
    }
    end {
        $InParams.CollectionRules += $Rules.psobject.BaseOBject
        $CollectionQuery.PSBase.InvokeMethod('DeleteMembershipRules',$InParams,$null) | Out-null
        $CollectionQuery.RequestRefresh() | out-null
    }
}
