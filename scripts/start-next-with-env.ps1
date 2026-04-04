param(
  [string]$EnvFile = '.env',
  [int]$Port = 3000,
  [string]$Hostname = '127.0.0.1'
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'import-env-file.ps1')

$resolvedEnvFile = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
  $EnvFile
} else {
  Join-Path (Get-Location) $EnvFile
}

$loadedKeys = Import-EnvFile -Path $resolvedEnvFile -Target Process
Write-Host ('Loaded env from ' + $resolvedEnvFile + ' (' + $loadedKeys.Count + ' keys)')

npx next dev --turbopack --hostname $Hostname --port $Port