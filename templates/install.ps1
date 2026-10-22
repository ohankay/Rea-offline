# Offline installer for Windows: copies this bundle to %LOCALAPPDATA%\rea-offline
# and adds its bin folder to the current user's PATH. No admin rights needed.
param([string]$Prefix = (Join-Path $env:LOCALAPPDATA 'rea-offline'))
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
Write-Host "REA kuruluyor / installing: $Prefix"
if ((Resolve-Path $src).Path -ne $Prefix) {
  if (Test-Path $Prefix) { Remove-Item -Recurse -Force $Prefix }
  New-Item -ItemType Directory -Force -Path $Prefix | Out-Null
  Copy-Item -Recurse -Force (Join-Path $src '*') $Prefix
}
Get-ChildItem -Recurse $Prefix | Unblock-File -ErrorAction SilentlyContinue
$bin = Join-Path $Prefix 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
if (($userPath -split ';') -notcontains $bin) {
  [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ';' + $bin).TrimStart(';')), 'User')
}
$env:Path = "$bin;$env:Path"
& (Join-Path $bin 'rea.cmd') --version
Write-Host ''
Write-Host 'Tamam / done. Yeni bir terminal acip deneyin / open a new terminal and try:'
Write-Host '  rea --help    |    rea doctor    |    rea mcp'
