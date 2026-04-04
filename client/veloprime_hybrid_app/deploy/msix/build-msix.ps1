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
  [string]$CertificateThumbprint,
  [string]$CertificateStorePath = 'Cert:\CurrentUser\My',
  [string]$PublicCertificatePath,
  [switch]$PreservePublishArtifacts,
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
$repoRoot = Resolve-Path (Join-Path $projectRoot '..\..')
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$resolvedPublishDir = [System.IO.Path]::GetFullPath($PublishDir)
$resolvedLogoPath = [System.IO.Path]::GetFullPath($LogoPath)
$resolvedCertificatePath = $null
$resolvedCertificatePassword = $CertificatePassword
$temporaryCertificatePath = $null

New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $resolvedPublishDir | Out-Null

if (-not $PublicCertificatePath) {
  $PublicCertificatePath = Join-Path $repoRoot 'public\download\veloprime-crm-test-signing.cer'
}

function Resolve-InstalledSigningCertificate {
  param(
    [string]$ExplicitThumbprint,
    [string]$StorePath,
    [string]$FallbackCertificatePath
  )

  $thumbprint = $ExplicitThumbprint

  if (-not $thumbprint -and (Test-Path $FallbackCertificatePath)) {
    $thumbprint = (Get-PfxCertificate $FallbackCertificatePath).Thumbprint
  }

  if (-not $thumbprint) {
    return $null
  }

  return Get-ChildItem $StorePath |
    Where-Object { $_.Thumbprint -eq $thumbprint -and $_.HasPrivateKey } |
    Select-Object -First 1
}

function New-RandomPassword {
  param([int]$Length = 24)

  $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
  $chars = for ($index = 0; $index -lt $Length; $index++) {
    $alphabet[(Get-Random -Minimum 0 -Maximum $alphabet.Length)]
  }

  -join $chars
}

Push-Location $projectRoot
try {
  if (-not $CertificatePath) {
    $installedCertificate = Resolve-InstalledSigningCertificate `
      -ExplicitThumbprint $CertificateThumbprint `
      -StorePath $CertificateStorePath `
      -FallbackCertificatePath $PublicCertificatePath

    if ($installedCertificate) {
      $temporaryCertificatePath = Join-Path $resolvedOutputDir 'veloprime-crm-test-signing-session.pfx'
      $resolvedCertificatePassword = New-RandomPassword
      $secureCertificatePassword = ConvertTo-SecureString -String $resolvedCertificatePassword -AsPlainText -Force

      Export-PfxCertificate -Cert $installedCertificate.PSPath -FilePath $temporaryCertificatePath -Password $secureCertificatePassword | Out-Null

      $resolvedCertificatePath = $temporaryCertificatePath
      Write-Host "Using installed signing certificate thumbprint $($installedCertificate.Thumbprint)"
    }
  }

  if (-not $resolvedCertificatePath -and $CertificatePath) {
    $resolvedCertificatePath = [System.IO.Path]::GetFullPath($CertificatePath)
  }

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

  if ($resolvedCertificatePath) {
    $createArgs += @('--certificate-path', $resolvedCertificatePath)
  }

  if ($resolvedCertificatePassword) {
    $createArgs += @('--certificate-password', $resolvedCertificatePassword)
  }

  flutter @createArgs

  if (-not $PreservePublishArtifacts) {
    Get-ChildItem -Path $resolvedPublishDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $resolvedPublishDir | Out-Null
  }

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

  if ($resolvedCertificatePath) {
    $publishArgs += @('--certificate-path', $resolvedCertificatePath)
  }

  if ($resolvedCertificatePassword) {
    $publishArgs += @('--certificate-password', $resolvedCertificatePassword)
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
  if ($temporaryCertificatePath -and (Test-Path $temporaryCertificatePath)) {
    Remove-Item -Force $temporaryCertificatePath -ErrorAction SilentlyContinue
  }
  Pop-Location
}
