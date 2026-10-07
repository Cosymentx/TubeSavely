# Helper script to build TubeSavely Windows and generate Inno Setup installer
param(
  [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"

if (-not $SkipFlutterBuild) {
  Write-Host "==> Building Flutter Windows Release..." -ForegroundColor Cyan
  flutter build windows --release
}

$versionLine = Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(.+)"
$version = "1.0.0"
if ($versionLine) {
  $version = $versionLine.Matches[0].Groups[1].Value.Trim().Split('+')[0]
}

Write-Host "==> Packaging Inno Setup installer for version $version..." -ForegroundColor Cyan

$cmd = Get-Command iscc -ErrorAction SilentlyContinue
$cmdSource = if ($cmd) { $cmd.Source } else { $null }

$candidatePaths = @(
  $cmdSource,
  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
  "C:\Program Files\Inno Setup 6\ISCC.exe",
  "D:\Program Files (x86)\Inno Setup 6\ISCC.exe",
  "D:\Program Files\Inno Setup 6\ISCC.exe",
  "D:\Program Files\Antigravity\resources\app\node_modules\innosetup\bin\ISCC.exe",
  "C:\Program Files\Antigravity\resources\app\node_modules\innosetup\bin\ISCC.exe"
)

$isccPath = $null
foreach ($p in $candidatePaths) {
  if ($p -and (Test-Path $p)) {
    $isccPath = $p
    break
  }
}

if (-not $isccPath) {
  Write-Error "ISCC.exe (Inno Setup Compiler) not found. Please install Inno Setup 6 or run: choco install innosetup"
  exit 1
}

Write-Host "==> Using Inno Setup compiler: $isccPath" -ForegroundColor DarkGray
& $isccPath "/DMyAppVersion=$version" "$PSScriptRoot\TubeSavely.iss"

if ($LASTEXITCODE -eq 0) {
  Write-Host "`n==> Installer generated successfully: TubeSavely-windows-x64-setup.exe" -ForegroundColor Green
} else {
  Write-Error "Inno Setup compilation failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}
