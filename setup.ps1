# Oila Daraxti - avtomatik sozlash skripti (Windows PowerShell)
# Ishga tushirish:  powershell -ExecutionPolicy Bypass -File .\setup.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Has($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# 1. Flutter
Step '1/7 Flutter tekshirilmoqda'
if (-not (Has 'flutter')) {
    Write-Host 'Flutter topilmadi. https://docs.flutter.dev/get-started/install/windows dan o''rnating va PATH ga qo''shing.' -ForegroundColor Red
    exit 1
}
flutter --version

# 2. Platforma papkalari (android, ios, web). Mavjud lib/ fayllar o'zgarmaydi.
Step '2/7 Platforma papkalari yaratilmoqda'
flutter create --org uz.oiladaraxti --project-name family_tree --platforms android,ios,web .
$wt = 'test\widget_test.dart'
if ((Test-Path $wt) -and (Select-String -Path $wt -Pattern 'MyApp' -Quiet)) { Remove-Item $wt -Force }

# 3. Android minSdk = 23 (Firebase Auth talabi)
Step '3/7 Android minSdk sozlanmoqda'
foreach ($g in 'android\app\build.gradle.kts', 'android\app\build.gradle') {
    if (Test-Path $g) {
        $c = Get-Content $g -Raw
        $c = $c -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
        $c = $c -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23'
        [IO.File]::WriteAllText((Resolve-Path $g), $c)
        Write-Host "  $g yangilandi"
    }
}

# 4. Paketlar
Step '4/7 Paketlar yuklanmoqda'
flutter pub get

# 5. Firebase CLI + FlutterFire CLI
Step '5/7 Firebase CLI tekshirilmoqda'
if (-not (Has 'firebase')) {
    if (Has 'npm') { npm install -g firebase-tools }
    else {
        Write-Host 'Node.js (npm) topilmadi. https://nodejs.org dan o''rnating yoki https://firebase.tools dan firebase CLI ni yuklang.' -ForegroundColor Red
        exit 1
    }
}
firebase login
dart pub global activate flutterfire_cli
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"

# 6. Firebase loyihasiga ulash (lib/firebase_options.dart avtomatik yoziladi)
Step '6/7 flutterfire configure (Firebase loyihasini tanlang yoki yarating)'
flutterfire configure --platforms=android,ios,web

$opts = Get-Content 'lib\firebase_options.dart' -Raw
$m = [regex]::Match($opts, "projectId:\s*'([^']+)'")
if (-not $m.Success) { Write-Host 'projectId topilmadi - flutterfire configure muvaffaqiyatsiz.' -ForegroundColor Red; exit 1 }
$projectId = $m.Groups[1].Value
Write-Host "  Firebase loyiha: $projectId" -ForegroundColor Green

# 7. Firestore bazasi va xavfsizlik qoidalari
Step '7/7 Firestore sozlanmoqda'
try { firebase firestore:databases:create '(default)' --location=eur3 --project $projectId } catch { Write-Host '  (Baza allaqachon mavjud bo''lishi mumkin)' }
firebase deploy --only firestore:rules --project $projectId

Write-Host "`nTAYYOR!" -ForegroundColor Green
Write-Host "Oxirgi qo'lda qadam: https://console.firebase.google.com/project/$projectId/authentication/providers"
Write-Host "  -> 'Email/Password' ni yoqing (Enable)."
Write-Host "So'ng ilovani ishga tushiring:  flutter run"
