$ErrorActionPreference = "Stop"

$ControlUrl = if ($env:CONTROL_URL) { $env:CONTROL_URL } else { "https://marumesh.lab.highmaru.com" }
$ReleaseBase = if ($env:GITHUB_RELEASE_BASE) { $env:GITHUB_RELEASE_BASE } else { "https://github.com/dirmich/maru-mesh/releases/latest/download" }
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { Join-Path $env:ProgramFiles "MaruMesh" }
$Asset = "marumesh-windows-amd64.exe"
$Url = "$ReleaseBase/$Asset"
$Tmp = Join-Path $env:TEMP $Asset

Write-Host "Downloading $Url"
Invoke-WebRequest -Uri $Url -OutFile $Tmp
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Force $Tmp (Join-Path $InstallDir "marumesh.exe")

$Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($Path -notlike "*$InstallDir*") {
  [Environment]::SetEnvironmentVariable("Path", "$Path;$InstallDir", "Machine")
}

Write-Host "Installed: $InstallDir\marumesh.exe"
Write-Host "Control plane: $ControlUrl"
Write-Host "Next: marumesh up"
