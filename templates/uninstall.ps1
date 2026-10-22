param([string]$Prefix = (Join-Path $env:LOCALAPPDATA 'rea-offline'))
$bin = Join-Path $Prefix 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $kept = ($userPath -split ';') | Where-Object { $_ -and $_ -ne $bin }
  [Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')
}
if (Test-Path $Prefix) { Remove-Item -Recurse -Force $Prefix }
Write-Host 'REA kaldirildi / removed.'
