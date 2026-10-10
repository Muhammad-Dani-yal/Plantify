param([string]$Apk = 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk')
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskApkPath = Join-Path $taskProject $Apk
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskApkPath)
try {
    if ($null -ne $taskArchive.GetEntry('assets/flutter_assets/kernel_blob.bin')) {
        throw 'Expected an optimized release APK, not a debug build.'
    }
    $taskArchitectures = @($taskArchive.Entries | Where-Object { $_.FullName -like 'lib/*/*.so' } |
        ForEach-Object { $_.FullName.Split('/')[1] } | Sort-Object -Unique)
    if ($taskArchitectures.Count -ne 1) { throw 'APK must contain only one device architecture.' }
    foreach ($taskLibrary in @('libapp.so', 'libflutter.so')) {
        if ($null -eq $taskArchive.GetEntry("lib/$($taskArchitectures[0])/$taskLibrary")) {
            throw "Missing compiled release library: $taskLibrary"
        }
    }
    $taskCodeReader = [IO.StreamReader]::new(
        $taskArchive.GetEntry("lib/$($taskArchitectures[0])/libapp.so").Open(), [Text.Encoding]::UTF8)
    try { $taskCompiledCode = $taskCodeReader.ReadToEnd() }
    finally { $taskCodeReader.Dispose() }
    foreach ($taskMarker in @('assets/botanical/greenhouse-hero.webp', 'Explore online plants', 'Plantify AI guide')) {
        if (-not $taskCompiledCode.Contains($taskMarker)) { throw "Stale compiled release code: missing $taskMarker" }
    }
    $taskPhotos = @($taskArchive.Entries | Where-Object {
        $_.FullName -match '^assets/flutter_assets/assets/(botanical|catalogue)/.*\.webp$'
    })
    if ($taskPhotos.Count -ne 101) { throw "Expected 100 plant images and a welcome image; found $($taskPhotos.Count)." }
    foreach ($taskPhoto in $taskPhotos) {
        $taskSource = Join-Path $taskProject $taskPhoto.FullName.Replace('assets/flutter_assets/', '')
        $taskDigest = [Security.Cryptography.SHA256]::Create()
        $taskStream = $taskPhoto.Open()
        try { $taskPackagedHash = [BitConverter]::ToString($taskDigest.ComputeHash($taskStream)).Replace('-', '') }
        finally { $taskStream.Dispose(); $taskDigest.Dispose() }
        if ($taskPackagedHash -ne (Get-FileHash -LiteralPath $taskSource -Algorithm SHA256).Hash) {
            throw "Stale packaged image: $taskSource"
        }
    }
    $taskSummary = [ordered]@{
        apk = $Apk
        bytes = (Get-Item -LiteralPath $taskApkPath).Length
        architecture = $taskArchitectures[0]
        verifiedImages = $taskPhotos.Count
        packagedImageBytes = ($taskPhotos | Measure-Object Length -Sum).Sum
    }
    $taskSummary | ConvertTo-Json
    Write-Output 'PASS: release code, single architecture and every compressed image verified.'
} finally { $taskArchive.Dispose() }
