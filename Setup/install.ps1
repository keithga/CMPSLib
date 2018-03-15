[cmdletbinding()]
param(
    $TargetZipFile = "$env:temp\CMPSLib.zip",
    $SrcZipFile = 'https://github.com/keithga/CMPSLib/archive/master.zip'
)

#region Get wizard bits

if ( -not ( Test-Path "$PSscriptRoot\release" ) ) {

    remove-item -Force $TargetZipFile -ErrorAction SilentlyContinue | Out-Null

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    iwr -Uri $SrcZipFile -OutFile $TargetZipFile

    Expand-Archive -Path $TargetZipFile -DestinationPath "$PSscriptRoot\release" -Force
}

#endregion

