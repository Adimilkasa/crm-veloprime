$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$certPath = Join-Path $scriptDir 'veloprime-crm-test-signing.cer'

if (-not (Test-Path $certPath)) {
  throw "Nie znaleziono pliku certyfikatu: $certPath"
}

function Import-VeloPrimeCertificate {
  param(
    [string]$PrimaryScope,
    [string]$FallbackScope
  )

  $primaryStores = @(
    "Cert:\$PrimaryScope\TrustedPeople",
    "Cert:\$PrimaryScope\Root"
  )
  $fallbackStores = @(
    "Cert:\$FallbackScope\TrustedPeople",
    "Cert:\$FallbackScope\Root"
  )

  try {
    foreach ($store in $primaryStores) {
      Import-Certificate -FilePath $certPath -CertStoreLocation $store | Out-Null
    }

    return $primaryStores
  } catch {
    foreach ($store in $fallbackStores) {
      Import-Certificate -FilePath $certPath -CertStoreLocation $store | Out-Null
    }

    return $fallbackStores
  }
}

$importedStores = Import-VeloPrimeCertificate -PrimaryScope 'LocalMachine' -FallbackScope 'CurrentUser'

Write-Host 'Certyfikat VeloPrime CRM Test zostal zaimportowany do:'
foreach ($store in $importedStores) {
  Write-Host "- $store"
}
Write-Host ''
Write-Host 'Mozesz teraz ponownie uruchomic plik VeloPrime-CRM-Test.appinstaller.'