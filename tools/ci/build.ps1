if(!(Test-Path -Path "C:/byond")){
    bash tools/ci/download_byond.sh
    [System.IO.Compression.ZipFile]::ExtractToDirectory("C:/byond.zip", "C:/")
    Remove-Item C:/byond.zip
}

C:/byond/bin/dm.exe osseus.dme

exit $LASTEXITCODE
