
function Get-CMSiteForWMI {
    <#
    Return the NameSpace and ComputerName arguments for any GWMI call to CM Site.
    #>

    get-CMSite | %{ @{ NameSpace = "root\SMS\Site_$($_.SiteCode)"; ComputerName = $_.ServerName } }
}

