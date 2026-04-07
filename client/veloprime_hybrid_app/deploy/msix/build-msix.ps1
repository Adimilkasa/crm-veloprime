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
  $LogoPath = Join-Path $scriptRoot '..\..\assets\branding\app_icon.png'
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

function Add-DesktopShortcutManifestExtension {
  param(
    [string]$ManifestPath,
    [string]$ShortcutName,
    [string]$ShortcutDescription
  )

  if (-not (Test-Path $ManifestPath)) {
    throw "AppxManifest.xml not found at $ManifestPath"
  }

  $content = Get-Content -Path $ManifestPath -Raw

  if ($content -notmatch 'xmlns:desktop7=') {
    $namespaceReplacement = @'
          xmlns:desktop6="http://schemas.microsoft.com/appx/manifest/desktop/windows10/6" 
          xmlns:desktop7="http://schemas.microsoft.com/appx/manifest/desktop/windows10/7" 
          xmlns:desktop10="http://schemas.microsoft.com/appx/manifest/desktop/windows10/10" 
'@
    $content = $content.Replace(
      '          xmlns:desktop6="http://schemas.microsoft.com/appx/manifest/desktop/windows10/6" ',
      $namespaceReplacement
    )
  }

  if ($content -match 'IgnorableNamespaces="([^"]*)"') {
    $namespaces = $Matches[1].Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    $orderedNamespaces = @($namespaces + 'desktop7' + 'desktop10' | Select-Object -Unique)
    $content = [System.Text.RegularExpressions.Regex]::Replace(
      $content,
      'IgnorableNamespaces="([^"]*)"',
      ('IgnorableNamespaces="' + ($orderedNamespaces -join ' ') + '"'),
      1
    )
  }

  if ($content -notmatch 'Category="windows.shortcut"') {
    $escapedShortcutName = [System.Security.SecurityElement]::Escape($ShortcutName)
    $escapedDescription = [System.Security.SecurityElement]::Escape($ShortcutDescription)
    $shortcutExtension = @'
          <desktop7:Extension Category="windows.shortcut">
            <desktop7:Shortcut
              File="$(Desktop)\{0}.lnk"
              Icon="Images\Square44x44Logo.png"
              Description="{1}"
              desktop10:DisplayName="{2}"
              desktop10:Description="{1}" />
          </desktop7:Extension>
'@ -f $ShortcutName, $escapedDescription, $escapedShortcutName

    if ($content -match '<Extensions>') {
      $content = $content.Replace('</Extensions>', "$shortcutExtension`r`n        </Extensions>")
    } else {
      $content = $content.Replace('        </Application>', "        <Extensions>`r`n$shortcutExtension`r`n        </Extensions>`r`n      </Application>")
    }
  }

  [System.IO.File]::WriteAllText($ManifestPath, $content, [System.Text.UTF8Encoding]::new($false))
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

  $buildArgs = @(
    'pub',
    'run',
    'msix:build',
    '--build-windows', 'false',
    '--display-name', $DisplayName,
    '--publisher-display-name', $PublisherDisplayName,
    '--identity-name', $IdentityName,
    '--version', $MsixVersion,
    '--logo-path', $resolvedLogoPath,
    '--capabilities', 'internetClient',
    '--publisher', $Publisher,
    '--architecture', 'x64'
  )

  if ($resolvedCertificatePath) {
    $buildArgs += @('--certificate-path', $resolvedCertificatePath)
  }

  if ($resolvedCertificatePassword) {
    $buildArgs += @('--certificate-password', $resolvedCertificatePassword)
  }

  flutter @buildArgs

  $manifestPath = Get-ChildItem -Path (Join-Path $projectRoot 'build\windows') -Filter 'AppxManifest.xml' -Recurse |
    Sort-Object LastWriteTime -Descending |
    Select-Object -ExpandProperty FullName -First 1
  Add-DesktopShortcutManifestExtension `
    -ManifestPath $manifestPath `
    -ShortcutName $DisplayName `
    -ShortcutDescription 'Skrot do klienta desktopowego VeloPrime CRM.'

  $packArgs = @(
    'pub',
    'run',
    'msix:pack',
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
    $packArgs += @('--certificate-path', $resolvedCertificatePath)
  }

  if ($resolvedCertificatePassword) {
    $packArgs += @('--certificate-password', $resolvedCertificatePassword)
  }

  flutter @packArgs

  if (-not $PreservePublishArtifacts) {
    Get-ChildItem -Path $resolvedPublishDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $resolvedPublishDir | Out-Null
  }

  $publishedVersionsDir = Join-Path $resolvedPublishDir 'versions'
  New-Item -ItemType Directory -Force -Path $publishedVersionsDir | Out-Null

  $packagePath = Join-Path $resolvedOutputDir "$OutputName.msix"
  $publishedMsixName = "veloprime_hybrid_app_${MsixVersion}.msix"
  $publishedMsixPath = Join-Path $publishedVersionsDir $publishedMsixName
  Copy-Item -Path $packagePath -Destination $publishedMsixPath -Force

  if ($PublishBaseUrl) {
    $normalizedPublishBaseUrl = $PublishBaseUrl.TrimEnd('/')
    $normalizedPackageBaseUrl = if ($PackageBaseUrl) {
      $PackageBaseUrl.TrimEnd('/')
    } else {
      "$normalizedPublishBaseUrl/versions"
    }
    $appInstallerPath = Join-Path $resolvedPublishDir "$OutputName.appinstaller"

    $appInstallerXml = @"
<?xml version="1.0" encoding="utf-8"?>
<AppInstaller xmlns="http://schemas.microsoft.com/appx/appinstaller/2018" Uri="$normalizedPublishBaseUrl/$OutputName.appinstaller" Version="$MsixVersion">
  <MainPackage Name="$IdentityName" Version="$MsixVersion" Publisher="$Publisher" Uri="$normalizedPackageBaseUrl/$publishedMsixName" ProcessorArchitecture="x64" />
  <UpdateSettings>
    <OnLaunch HoursBetweenUpdateChecks="0" UpdateBlocksActivation="true" ShowPrompt="true" />
    <AutomaticBackgroundTask />
  </UpdateSettings>
</AppInstaller>
"@
    [System.IO.File]::WriteAllText($appInstallerPath, $appInstallerXml.Trim(), [System.Text.UTF8Encoding]::new($false))

    $indexHtmlPath = Join-Path $resolvedPublishDir 'index.html'
    $indexHtml = @"
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$DisplayName</title>
</head>
<body>
  <p><a href="./$OutputName.appinstaller">Zainstaluj $DisplayName</a></p>
</body>
</html>
"@
    [System.IO.File]::WriteAllText($indexHtmlPath, $indexHtml.Trim(), [System.Text.UTF8Encoding]::new($false))
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
