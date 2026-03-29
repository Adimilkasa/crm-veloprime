param(
  [string]$AppInstallerPath = '.\public\download\VeloPrime-CRM-Test.appinstaller',
  [string]$AppInstallerUrl = 'https://crm.veloprime.pl/download/VeloPrime-CRM-Test.appinstaller',
  [string]$PackageUrl,
  [string]$Version,
  [string]$Tag,
  [string]$Repo,
  [string]$AssetName
)

$ErrorActionPreference = 'Stop'

function Resolve-MsixVersion {
  param(
    [string]$ExplicitVersion,
    [string]$SourceUrl
  )

  if ($ExplicitVersion) {
    return $ExplicitVersion.Trim()
  }

  $match = [regex]::Match($SourceUrl, '(?<version>\d+\.\d+\.\d+\.\d+)(?=\.msix(?:$|[?#]))')

  if ($match.Success) {
    return $match.Groups['version'].Value
  }

  throw 'Nie udalo sie wykryc wersji z PackageUrl. Podaj jawnie parametr -Version, np. 0.1.2.0.'
}

function Resolve-GitHubRepo {
  param([string]$ExplicitRepo)

  if ($ExplicitRepo) {
    return $ExplicitRepo.Trim()
  }

  $remoteUrl = git remote get-url origin 2>$null

  if (-not $remoteUrl) {
    throw 'Nie udalo sie odczytac git remote origin. Podaj jawnie parametr -Repo, np. Adimilkasa/crm-veloprime.'
  }

  $remoteUrl = $remoteUrl.Trim()

  $httpsMatch = [regex]::Match($remoteUrl, 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/]+?)(?:\.git)?$')

  if ($httpsMatch.Success) {
    return "$($httpsMatch.Groups['owner'].Value)/$($httpsMatch.Groups['name'].Value)"
  }

  throw "Nie udalo sie wywnioskowac repo GitHub z origin: $remoteUrl"
}

function Resolve-Tag {
  param(
    [string]$ExplicitTag,
    [string]$ResolvedVersion
  )

  if ($ExplicitTag) {
    return $ExplicitTag.Trim()
  }

  return "v$ResolvedVersion"
}

function Resolve-AssetName {
  param(
    [string]$ExplicitAssetName,
    [string]$ResolvedVersion
  )

  if ($ExplicitAssetName) {
    return $ExplicitAssetName.Trim()
  }

  return "veloprime_hybrid_app_${ResolvedVersion}.msix"
}

function Resolve-PackageUrl {
  param(
    [string]$ExplicitPackageUrl,
    [string]$ResolvedRepo,
    [string]$ResolvedTag,
    [string]$ResolvedAssetName
  )

  if ($ExplicitPackageUrl) {
    return $ExplicitPackageUrl.Trim()
  }

  return "https://github.com/$ResolvedRepo/releases/download/$ResolvedTag/$ResolvedAssetName"
}

$resolvedAppInstallerPath = [System.IO.Path]::GetFullPath($AppInstallerPath)

if (-not (Test-Path $resolvedAppInstallerPath)) {
  throw "Nie znaleziono pliku appinstaller: $resolvedAppInstallerPath"
}

$resolvedVersion = if ($Version) {
  $Version.Trim()
} elseif ($PackageUrl) {
  Resolve-MsixVersion -ExplicitVersion $Version -SourceUrl $PackageUrl
} else {
  [xml]$existingAppInstallerXml = Get-Content -Path $resolvedAppInstallerPath
  $existingVersion = $existingAppInstallerXml.AppInstaller.MainPackage.Version

  if (-not $existingVersion) {
    throw 'Nie udalo sie wykryc wersji z istniejacego .appinstaller. Podaj parametr -Version.'
  }

  $existingVersion.Trim()
}

$resolvedRepo = Resolve-GitHubRepo -ExplicitRepo $Repo
$resolvedTag = Resolve-Tag -ExplicitTag $Tag -ResolvedVersion $resolvedVersion
$resolvedAssetName = Resolve-AssetName -ExplicitAssetName $AssetName -ResolvedVersion $resolvedVersion
$resolvedPackageUrl = Resolve-PackageUrl -ExplicitPackageUrl $PackageUrl -ResolvedRepo $resolvedRepo -ResolvedTag $resolvedTag -ResolvedAssetName $resolvedAssetName

[xml]$appInstallerXml = Get-Content -Path $resolvedAppInstallerPath
$appInstallerNode = $appInstallerXml.AppInstaller
$mainPackageNode = $appInstallerNode.MainPackage

if (-not $appInstallerNode -or -not $mainPackageNode) {
  throw 'Niepoprawny plik .appinstaller: brak wezla AppInstaller lub MainPackage.'
}

$appInstallerNode.SetAttribute('Uri', $AppInstallerUrl)
$appInstallerNode.SetAttribute('Version', $resolvedVersion)
$mainPackageNode.SetAttribute('Version', $resolvedVersion)
$mainPackageNode.SetAttribute('Uri', $resolvedPackageUrl)

$appInstallerXml.Save($resolvedAppInstallerPath)

Write-Host "APPINSTALLER_UPDATED path=$resolvedAppInstallerPath version=$resolvedVersion"
Write-Host "APPINSTALLER_URI=$AppInstallerUrl"
Write-Host "PACKAGE_URI=$resolvedPackageUrl"
Write-Host "PACKAGE_REPO=$resolvedRepo"
Write-Host "PACKAGE_TAG=$resolvedTag"
Write-Host "PACKAGE_ASSET=$resolvedAssetName"