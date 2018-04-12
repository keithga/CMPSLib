<#


https://blogs.technet.microsoft.com/breben/2010/09/29/what-does-this-advertisement-status-message-mean/

0 0 No Status No messages have been received
65535 -1 Accepted - No Further Status Program received - no further status
10073 8 Waiting Waiting for a Service Window
11170 11 Failed The task sequence manager could not successfully complete execution of the task sequence

11171 13 Succeeded The task sequence manager successfully completed execution of the task sequence

11142 9 Running The task sequence execution engine performed a system reboot initiated by an action

#>

[cmdletbinding(SupportsShouldProcess=$true)]
param(
    $hostname,
    $Database,
    $Path,
    $LogPath
)

if(-not (Get-Module PSCMLib)) { throw "missing $PSScriptRoot\..\PSCMLib" }

function Confirm-CollectionHasExpired {
    [cmdletbinding()]
    param( [parameter(Mandatory=$true)] [string] $Name )
    # Given a Colllection Name OSD_W10_Fall_DAY_XX_8PM, was the collection the past, or future?

    begin { 
        $Days = -10..-1 | % { [datetime]::Today.adddays($_).day }
    }
    process {
        $Name | ?{ $_ -match '.*_([0-3][0-9])_.*' } | % { $Matches[1] -in $Days }
    }
}

$Query = @"
    SELECT top 1000 Col.CollectionID
        , Col.Name as CollectionName
        , CCM.ResourceID
        , CCM.Name as ComputerName
        , LKS.LastStatusMessageID
        , LKS.LastStatusMessageIDName
        , LKS.LastState
        , LKS.LastStateName
        , LKS.LastStatusTime
    FROM [CM_CAS].[dbo].[v_ClientAdvertisementStatus] LKS
    JOIN [dbo].[v_Advertisement] adv on adv.AdvertisementID = LKS.AdvertisementID
    JOIN [dbo].[v_collection] col on adv.CollectionID = col.CollectionID
    JOIN [dbo].[v_ClientCollectionMembers] CCM on CCM.CollectionID = col.CollectionID and CCM.ResourceID = LKS.ResourceID
    WHERE LKS.LastStatusTime > DATEADD(Day, -10, getdate()) 
        AND col.Name LIKE 'OSD_W10_%_8PM'
        AND ( LKS.LastStatusMEssageID in ( 0,65535,11170 ) or LKS.LastState = 8 )
"@


Write-Verbose ("Process OSD_W10_%_DAY_XX_8PM to OSD_W10_%_Finished")
Invoke-SQLCMD -HostName $HostName -Database $Database -Query $Query |
    ? { Confirm-CollectionHasExpired $_.LastStatusTime } |
    Group-Object -Property CollectionName | 
    ForEach-Object {
        $Tomorrow = 'Day_{0:d2}_8PM' -f [datetime]::today.AddDays(1).day
        write-host "MOve $($_.Name) to $Tomorrow"
        $_.Group | Select CollectionID,CollectionName,ComputerName,LastStatusTime,LastStatusMessageID,LastState | ft
        # $_.Group | Move-CMDeviceToCollectionFromAny -CollectionPostFix $Tomorrow 
    }
