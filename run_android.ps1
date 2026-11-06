# Android emulyatorni yoqib, ilovani ishga tushiradi.
# Ishga tushirish:  powershell -ExecutionPolicy Bypass -File .\run_android.ps1
$env:Path = "C:\flutter\bin;C:\tools\git\cmd;C:\tools\node;$env:LOCALAPPDATA\Pub\Cache\bin;" + $env:Path
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
Set-Location $PSScriptRoot

function Booted { (& $adb shell getprop sys.boot_completed 2>$null) -match '1' }

if (-not (Booted)) {
    if (-not ((& $adb devices) -match 'emulator-')) {
        Write-Host 'Emulyator yoqilmoqda...' -ForegroundColor Cyan
        flutter emulators --launch Medium_Phone_API_37.0
    }
    Write-Host 'Emulyator to''liq yuklanishi kutilmoqda...' -ForegroundColor Cyan
    & $adb wait-for-device
    for ($i = 0; $i -lt 120; $i++) {
        if (Booted) { break }
        Start-Sleep 3
    }
}
$id = ((& $adb devices) | Select-String -Pattern '(emulator-\d+)\s+device').Matches[0].Groups[1].Value
Write-Host "Qurilma: $id" -ForegroundColor Green
flutter run -d $id
