[cmdletbinding()]
param(
    $TargetZipFile = "$env:temp\CMPSLib.zip",
    $SrcZipFile = 'https://github.com/keithga/CMPSLib/archive/master.zip',
    $Target
)

#region Get wizard bits

if ( -not $Target ) { $Target = "$PSscriptRoot\Release" }


if ( -not ( Test-Path $Target ) ) {

    remove-item -Force $TargetZipFile -ErrorAction SilentlyContinue | Out-Null

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    iwr -Uri $SrcZipFile -OutFile $TargetZipFile

    Expand-Archive -Path $TargetZipFile -DestinationPath $Target -Force
}

#endregion

