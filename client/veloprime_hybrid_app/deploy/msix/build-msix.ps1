param(
  [string]$BaseUrl = 'https://crm.veloprime.pl',
  [string]$PublishBaseUrl = 'https://crm.veloprime.pl',
  [string]$PackageBaseUrl,
  [string]$Publisher = 'CN=VeloPrime CRM Test',
  [string]$PublisherDisplayName = 'VeloPrime',
  [string]$IdentityName = 'pl.veloprime.crm',
  [string]$DisplayName = 'VeloPrime CRM',
  [string]$MsixVersion = '0.1.0.0',
  [string]$OutputName = 'VeloPrime-CRM-Test',
  [string]$OutputDir,
  [string]$PublishDir,
  [string]$LogoPath,
  [string]$CertificatePath,
  [string]$CertificatePassword,
  [switch]$SkipWindowsBuild
)

$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) {
  $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
  Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
  (Get-Location).Path
}

if (-not $OutputDir) {
  $OutputDir = Join-Path $scriptRoot 'artifacts\package'
}

if (-not $PublishDir) {
  $PublishDir = Join-Path $scriptRoot 'artifacts\publish'
}

if (-not $LogoPath) {
  $LogoPath = Join-Path $scriptRoot '..\..\assets\branding\logo.png'
}

$projectRoot = Resolve-Path (Join-Path $scriptRoot '..\..')
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$resolvedPublishDir = [System.IO.Path]::GetFullPath($PublishDir)
$resolvedLogoPath = [System.IO.Path]::GetFullPath($LogoPath)

New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $resolvedPublishDir | Out-Null

Push-Location $projectRoot
try {
  if (-not $SkipWindowsBuild) {
    flutter build windows --release --dart-define="VELOPRIME_API_BASE_URL=$BaseUrl"
  }

  $createArgs = @(
    'pub',
    'run',
    'msix:create',
    '--build-windows', 'false',
    '--display-name', $DisplayName,
    '--publisher-display-name', $PublisherDisplayName,
    '--identity-name', $IdentityName,
    '--version', $MsixVersion,
    '--logo-path', $resolvedLogoPath,
    '--capabilities', 'internetClient',
    '--output-path', $resolvedOutputDir,
    '--output-name', $OutputName,
    '--publisher', $Publisher,
    '--architecture', 'x64'
  )

  if ($CertificatePath) {
    $createArgs += @('--certificate-path', ([System.IO.Path]::GetFullPath($CertificatePath)))
  }

  if ($CertificatePassword) {
    $createArgs += @('--certificate-password', $CertificatePassword)
  }

  flutter @createArgs

  $publishArgs = @(
    'pub',
    'run',
    'msix:publish',
    '--build-windows', 'false',
    '--display-name', $DisplayName,
    '--publisher-display-name', $PublisherDisplayName,
    '--identity-name', $IdentityName,
    '--version', $MsixVersion,
    '--logo-path', $resolvedLogoPath,
    '--capabilities', 'internetClient',
    '--output-path', $resolvedOutputDir,
    '--output-name', $OutputName,
    '--publisher', $Publisher,
    '--publish-folder-path', $resolvedPublishDir,
    '--architecture', 'x64'
  )

  if ($CertificatePath) {
    $publishArgs += @('--certificate-path', ([System.IO.Path]::GetFullPath($CertificatePath)))
  }

  if ($CertificatePassword) {
    $publishArgs += @('--certificate-password', $CertificatePassword)
  }

  flutter @publishArgs

  if ($PublishBaseUrl) {
    $normalizedPublishBaseUrl = $PublishBaseUrl.TrimEnd('/')
    $normalizedPackageBaseUrl = if ($PackageBaseUrl) {
      $PackageBaseUrl.TrimEnd('/')
    } else {
      "$normalizedPublishBaseUrl/versions"
    }
    $appInstallerPath = Join-Path $resolvedPublishDir "$OutputName.appinstaller"
    $versionsDir = Join-Path $resolvedPublishDir 'versions'
    $publishedMsix = Get-ChildItem -Path $versionsDir -Filter '*.msix' |
      Where-Object { $_.Name -like "*${MsixVersion}*.msix" } |
      Select-Object -First 1

    if (-not $publishedMsix) {
      $publishedMsix = Get-ChildItem -Path $versionsDir -Filter '*.msix' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    }

    if ($publishedMsix -and (Test-Path $appInstallerPath)) {
      [xml]$appInstallerXml = Get-Content -Path $appInstallerPath
      $appInstallerNode = $appInstallerXml.AppInstaller
      $mainPackageNode = $appInstallerNode.MainPackage

      $appInstallerNode.SetAttribute('Uri', "$normalizedPublishBaseUrl/$OutputName.appinstaller")
      $mainPackageNode.SetAttribute('Uri', "$normalizedPackageBaseUrl/$($publishedMsix.Name)")
      $appInstallerXml.Save($appInstallerPath)
    }
  }

  Write-Host "MSIX artifacts: $resolvedOutputDir"
  Write-Host "Publish artifacts: $resolvedPublishDir"
  Write-Host 'To jest plik do publikacji na stronie: artifacts\package\VeloPrime-CRM-Test.msix'
} finally {
  Pop-Location
}
