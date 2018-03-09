
function Get-CMSiteForWMI {
    <#
    .SYNOPSIS
    Get the WMI arguments for the CM Site
    .DESCRIPTION
    Returns the NameSpace, Comptuername, and credntials used for GWMI Spaltting
    .NOTES
    THis function should be smart enough to find the Site if running from 
    the CM PowerShell Drive, if the Site is local, or if the computername and/or
    site code are specified on the command line
    .EXAMPLE
    PS CHQ:\> get-cmsite
    get the site while in the CHQ: provider

    #>

    [cmdletbinding()]
    param( 
        [string] $SiteCode,
        [string] $ComputerName,
        [pscredential] $Credential,
        [parameter(ValueFromRemainingArguments=$true)]
        $JunkArgs
    )

    if ( get-location | ? Provider -like '*CMSite' ) {
        write-verbose 'Running within a CM Powershell instance'
        $result = get-CMSite -SiteCode (Get-Location).Drive | 
            ForEach-Object { 
                @{ NameSpace = "root\SMS\Site_$($_.SiteCode)"; ComputerName = $_.ServerName }
            }
    }
    elseif ( $siteCode ) {
        if ( $ComputerName ) {
            $result = @{ NameSpace = "root\SMS\Site_$($SiteCode)"; ComputerName = $ComputerName }
        }
        else {
            $result = @{ NameSpace = "root\SMS\Site_$($SiteCode)"; ComputerName = $env:computerName }
        }
    }
    else {
        $FindArgs = @{}
        if ( $ComptuerName ) { $FindArgs.Add('ComputerName',$ComputerName) }
        if ( $Credential ) { $FindArgs.Add('Credential',$Credential) }
        $result = gwmi @FindArgs -Namespace 'root\sms' -class SMS_ProviderLocation -Filter 'ProviderForLocalSite=true' | 
            foreach-Object { $_.NameSpacePath -split '\\',4 } | 
            Select-Object -last 1 | 
            ForEach-Object { GWMI @FindArgs -namespace $_ -class 'sms_site' } | 
            Sort-Object -Property Type -Descending | 
            Select-Object -First 1 |
            ForEach-Object {
                @{ NameSpace = "root\SMS\Site_$($_.SiteCode)"; ComputerName = $_.ServerName }
            }
    }

    if ( $credential ) {
        $result.add('credential',$Credential)
    }

    write-verbose "Quick test"
    if ( -not ( gwmi @result -class sms_site ) ) { throw "Site not found: $( $Result | out-string )" }

    $result | Write-Output
}