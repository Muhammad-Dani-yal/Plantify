# Smaller ARM64 download; Android extracts the native libraries on installation.
$ErrorActionPreference = 'Stop'
flutter build apk --release --split-per-abi --target-platform android-arm64 --android-project-arg=plantifyCompactApk=true
if ($LASTEXITCODE -ne 0) { throw 'Compact APK build failed.' }
$builtApk = 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
& "$PSScriptRoot/verify_release_apk.ps1" -Apk $builtApk
if ($LASTEXITCODE -ne 0) { throw 'APK verification failed.' }
Copy-Item -LiteralPath $builtApk -Destination 'Plantify.apk'
if ((Get-FileHash -LiteralPath $builtApk).Hash -ne (Get-FileHash -LiteralPath 'Plantify.apk').Hash) {
    throw 'APK copy verification failed.'
}
Write-Output 'Complete compact Android app: Plantify.apk'
