param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$smokeOfferTitle = 'SMOKE_OFFER_EMAIL'
$smokeLeadName = 'Smoke Offer Email Lead'
$smokeLeadEmail = 'smoke.offer.email@veloprime.pl'
$recipientEmail = 'smoke.offer.email.recipient@veloprime.pl'
$outboxDir = Join-Path (Get-Location) '.mail-outbox'
. (Join-Path $PSScriptRoot 'smoke-offer-common.ps1')

try {
  Write-Host '1. Prepare empty outbox state'
  if (Test-Path $outboxDir) {
    Get-ChildItem -Path $outboxDir -File | Remove-Item -Force
  } else {
    New-Item -ItemType Directory -Path $outboxDir | Out-Null
  }

  Write-Host '2. Login admin'
  $adminSession = Login-Admin -BaseUrl $baseUrl
  $prepared = Ensure-SmokeOfferVersion `
    -BaseUrl $baseUrl `
    -Session $adminSession `
    -SmokeOfferTitle $smokeOfferTitle `
    -SmokeLeadName $smokeLeadName `
    -SmokeLeadEmail $smokeLeadEmail `
    -SmokePhone '+48500000002' `
    -SmokeMessage 'Smoke flow offer-email' `
    -ValidatedNotes 'Smoke offer email validated' `
    -StepLabelPrefix '3' `
    -CustomerEmail $recipientEmail
  $offerId = [string]$prepared.OfferId
  $offerNumber = [string]$prepared.OfferNumber
  $versionId = [string]$prepared.VersionId

  Write-Host '9. Send offer email'
  $emailBody = @{ versionId = $versionId; toEmail = $recipientEmail } | ConvertTo-Json
  $emailResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/offers/' + $offerId + '/send-email') `
    -Method Post `
    -WebSession $adminSession `
    -ContentType 'application/json' `
    -Body $emailBody `
    -UseBasicParsing
  $emailPayload = $emailResponse.Content | ConvertFrom-Json

  if (-not $emailPayload.ok) {
    throw 'Offer email failed: ' + $emailPayload.error
  }

  if ([string]$emailPayload.email.to -ne $recipientEmail) {
    throw 'Offer email response returned unexpected recipient'
  }

  $publicUrl = [string]$emailPayload.email.publicUrl
  if (-not $publicUrl -or $publicUrl -notmatch '/oferta/') {
    throw 'Offer email response did not include public offer URL'
  }

  Write-Host '10. Validate dev outbox entry'
  $outboxFiles = @(Get-ChildItem -Path $outboxDir -File | Sort-Object LastWriteTimeUtc)
  if ($outboxFiles.Count -ne 1) {
    throw 'Expected exactly one dev outbox file after sending email'
  }

  $outboxPayload = Get-Content -Path $outboxFiles[0].FullName -Raw | ConvertFrom-Json

  if ([string]$outboxPayload.to -ne $recipientEmail) {
    throw 'Dev outbox file has unexpected recipient'
  }

  if ([string]$outboxPayload.subject -notmatch 'VeloPrime \| Oferta') {
    throw 'Dev outbox file has unexpected subject'
  }

  if ([string]$outboxPayload.html -notmatch [Regex]::Escape($publicUrl)) {
    throw 'Dev outbox html does not include public offer URL'
  }

  if ([string]$outboxPayload.text -notmatch [Regex]::Escape($publicUrl)) {
    throw 'Dev outbox text does not include public offer URL'
  }

  Write-Host ('SMOKE_OK offerId=' + $offerId + ' offerNumber=' + $offerNumber + ' versionId=' + $versionId + ' to=' + $recipientEmail)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}