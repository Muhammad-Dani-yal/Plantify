# Smaller ARM64 download; Android extracts the native libraries on installation.
$ErrorActionPreference = 'Stop'
flutter build apk --release --split-per-abi --target-platform android-arm64 --android-project-arg=plantifyCompactApk=true
if ($LASTEXITCODE -ne 0) { throw 'Compact APK build failed.' }
Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk' -Destination 'build/app/outputs/flutter-apk/app-compact-arm64-release.apk'
