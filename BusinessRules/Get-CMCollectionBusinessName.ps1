function Get-CMCollectionBusinessName {
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Name,
        [string] $Postfix
    )

    $Name | Select-String -Pattern 'OSD_W10_(Spring|Fall)_(x86|x64)_' | % { $_.Matches.Value + $PostFix }

}
