param(
  [Parameter(Mandatory = $true)]
  [string]$Password,

  [string]$Publisher = 'CN=VeloPrime CRM Test',

  [string]$OutputDir
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
  $OutputDir = Join-Path $scriptRoot 'artifacts\cert'
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$cert = New-SelfSignedCertificate `
  -Type Custom `
  -Subject $Publisher `
  -KeyUsage DigitalSignature `
  -FriendlyName 'VeloPrime CRM Test MSIX' `
  -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3') `
  -CertStoreLocation 'Cert:\CurrentUser\My' `
  -HashAlgorithm 'SHA256' `
  -NotAfter (Get-Date).AddYears(3)

$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$pfxPath = Join-Path $OutputDir 'veloprime-crm-test-signing.pfx'
$cerPath = Join-Path $OutputDir 'veloprime-crm-test-signing.cer'

Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null

Write-Host "PFX: $pfxPath"
Write-Host "CER: $cerPath"
Write-Host 'Zaimportuj plik CER na komputerze testowym do Trusted People lub Trusted Root Certification Authorities przed instalacją MSIX.'
