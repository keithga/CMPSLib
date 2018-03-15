function Get-CMCollectionBusinessName {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Name,
        [string] $Postfix
    )

    $Name | Select-String -Pattern '$($OSDW10Prefix)_([^_]*_)?(Spring|Fall)_' | % { $_.Matches.Value + $PostFix }

}
