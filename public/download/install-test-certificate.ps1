$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$certPath = Join-Path $scriptDir 'veloprime-crm-test-signing.cer'

if (-not (Test-Path $certPath)) {
  throw "Nie znaleziono pliku certyfikatu: $certPath"
}

Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null
Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null

Write-Host 'Certyfikat VeloPrime CRM Test zostal zaimportowany do:'
Write-Host '- Cert:\LocalMachine\TrustedPeople'
Write-Host '- Cert:\LocalMachine\Root'
Write-Host ''
Write-Host 'Mozesz teraz ponownie uruchomic plik VeloPrime-CRM-Test.appinstaller.'