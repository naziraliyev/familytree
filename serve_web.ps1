# Ilovani brauzerda ishga tushiradi: http://localhost:8080
$env:Path = "C:\flutter\bin;C:\tools\git\cmd;C:\tools\node;" + $env:Path
Set-Location $PSScriptRoot
flutter run -d web-server --web-port 8080 --web-hostname localhost
