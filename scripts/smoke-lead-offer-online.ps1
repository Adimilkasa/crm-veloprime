param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$smokeOfferTitle = 'SMOKE_FLOW_OFFER'
$smokeLeadName = 'Smoke Flow Lead'
$smokeLeadEmail = 'smoke.flow.lead@veloprime.pl'
. (Join-Path $PSScriptRoot 'smoke-offer-common.ps1')

try {
  Write-Host '1. Login admin'
  $adminSession = Login-Admin -BaseUrl $baseUrl
  $prepared = Ensure-SmokeOfferVersion `
    -BaseUrl $baseUrl `
    -Session $adminSession `
    -SmokeOfferTitle $smokeOfferTitle `
    -SmokeLeadName $smokeLeadName `
    -SmokeLeadEmail $smokeLeadEmail `
    -SmokePhone '+48500000000' `
    -SmokeMessage 'Smoke flow lead-offer-online' `
    -ValidatedNotes 'Smoke flow validated' `
    -StepLabelPrefix '2'
  $offerId = [string]$prepared.OfferId
  $offerNumber = [string]$prepared.OfferNumber
  $versionId = [string]$prepared.VersionId

  Write-Host '8. Fetch document snapshot'
  $documentResponse = Invoke-WebRequest -Uri ($baseUrl + '/api/client/offers/' + $offerId + '/document?versionId=' + $versionId) -WebSession $adminSession -UseBasicParsing
  $documentPayload = $documentResponse.Content | ConvertFrom-Json

  if (-not $documentPayload.ok) {
    throw 'Document snapshot failed: ' + $documentPayload.error
  }

  if ([string]$documentPayload.document.offerId -ne $offerId) {
    throw 'Document snapshot returned a different offerId'
  }

  if ([string]$documentPayload.document.version.id -ne $versionId) {
    throw 'Document snapshot returned a different versionId'
  }

  Write-Host '9. Open online offer page'
  $shareBody = @{ versionId = $versionId } | ConvertTo-Json
  $shareResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/offers/' + $offerId + '/share') `
    -Method Post `
    -WebSession $adminSession `
    -ContentType 'application/json' `
    -Body $shareBody `
    -UseBasicParsing
  $sharePayload = $shareResponse.Content | ConvertFrom-Json

  if (-not $sharePayload.ok) {
    throw 'Offer share failed: ' + $sharePayload.error
  }

  $shareUrl = [string]$sharePayload.share.url
  if (-not $shareUrl -or $shareUrl -notmatch '/oferta/') {
    throw 'Offer share did not return a public offer URL'
  }

  $publicResponse = Invoke-WebRequest -Uri $shareUrl -UseBasicParsing

  if ($publicResponse.StatusCode -ne 200) {
    throw 'Online offer page did not return 200'
  }

  if ($publicResponse.Content -notmatch 'Oferta online') {
    throw 'Online offer page content does not include offer header marker'
  }

  Write-Host ('SMOKE_OK offerId=' + $offerId + ' offerNumber=' + $offerNumber + ' versionId=' + $versionId)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}