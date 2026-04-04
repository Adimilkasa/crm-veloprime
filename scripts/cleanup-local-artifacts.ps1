param(
  [switch]$IncludeScreenshots
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) {
  $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
  Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
  (Get-Location).Path
}

$repoRoot = Resolve-Path (Join-Path $scriptRoot '..')

$targets = @(
  @{
    Path = Join-Path $repoRoot '.next'
    Description = 'Next.js build cache'
  }
  @{
    Path = Join-Path $repoRoot 'vercel-deploy.log'
    Description = 'Vercel deploy log'
  }
  @{
    Path = Join-Path $repoRoot 'client\veloprime_hybrid_app\build'
    Description = 'Flutter build artifacts'
  }
  @{
    Path = Join-Path $repoRoot 'client\veloprime_hybrid_app\.dart_tool'
    Description = 'Flutter tool cache'
  }
  @{
    Path = Join-Path $repoRoot 'client\veloprime_hybrid_app\deploy\msix\artifacts'
    Description = 'MSIX local packaging artifacts'
  }
)

if ($IncludeScreenshots) {
  $targets += @{
    Path = Join-Path $repoRoot 'screeny'
    Description = 'Local screenshots workspace'
  }
}

foreach ($target in $targets) {
  $resolvedPath = [System.IO.Path]::GetFullPath($target.Path)

  if (-not (Test-Path $resolvedPath)) {
    Write-Host "SKIP path=$resolvedPath reason=missing"
    continue
  }

  Remove-Item -Path $resolvedPath -Recurse -Force
  Write-Host "REMOVED path=$resolvedPath description=$($target.Description)"
}

Write-Host 'LOCAL_ARTIFACT_CLEANUP_DONE'