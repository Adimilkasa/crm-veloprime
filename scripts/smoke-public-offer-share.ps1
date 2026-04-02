param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$smokeOfferTitle = 'SMOKE_PUBLIC_SHARE_OFFER'
$smokeLeadName = 'Smoke Public Share Lead'
$smokeLeadEmail = 'smoke.public.share@veloprime.pl'
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
    -SmokePhone '+48500000001' `
    -SmokeMessage 'Smoke flow public-offer-share' `
    -ValidatedNotes 'Smoke public share validated' `
    -StepLabelPrefix '2'
  $offerId = [string]$prepared.OfferId
  $offerNumber = [string]$prepared.OfferNumber
  $versionId = [string]$prepared.VersionId

  Write-Host '8. Create public share link'
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
  $shareToken = [string]$sharePayload.share.token

  if (-not $shareUrl -or -not $shareToken) {
    throw 'Missing share url or token after share creation'
  }

  if ($shareUrl -notmatch '/oferta/') {
    throw 'Share URL does not point to public offer page'
  }

  Write-Host '9. Open public offer page without CRM session'
  $publicResponse = Invoke-WebRequest -Uri $shareUrl -UseBasicParsing

  if ($publicResponse.StatusCode -ne 200) {
    throw 'Public offer page did not return 200'
  }

  if ($publicResponse.Content -notmatch 'Oferta online') {
    throw 'Public offer page does not include offer header marker'
  }

  if ($publicResponse.Content -notmatch [Regex]::Escape($offerNumber)) {
    throw 'Public offer page does not include offer number'
  }

  Write-Host ('SMOKE_OK offerId=' + $offerId + ' offerNumber=' + $offerNumber + ' versionId=' + $versionId + ' shareToken=' + $shareToken)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}