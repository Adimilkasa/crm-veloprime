param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$smokeOfferTitle = 'SMOKE_FLOW_OFFER'
$smokeLeadName = 'Smoke Flow Lead'
$smokeLeadEmail = 'smoke.flow.lead@veloprime.pl'

function New-SmokeSession {
  return New-Object Microsoft.PowerShell.Commands.WebRequestSession
}

function Invoke-FormLogin {
  param(
    [string]$Email,
    [string]$Password,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session
  )

  return Invoke-WebRequest `
    -Uri ($baseUrl + '/api/auth/login') `
    -Method Post `
    -WebSession $Session `
    -Body @{ email = $Email; password = $Password } `
    -ContentType 'application/x-www-form-urlencoded' `
    -MaximumRedirection 0 `
    -UseBasicParsing `
    -ErrorAction SilentlyContinue
}

function Login-Admin {
  $session = New-SmokeSession
  $response = Invoke-FormLogin -Email 'admin@veloprime.pl' -Password 'Admin123!' -Session $session

  if (-not $response -or $response.StatusCode -ne 303 -or $response.Headers.Location -notlike '*/dashboard') {
    throw 'Admin login failed for lead-offer-pdf smoke test'
  }

  return $session
}

function Get-Bootstrap {
  param([Microsoft.PowerShell.Commands.WebRequestSession]$Session)

  $response = Invoke-WebRequest -Uri ($baseUrl + '/api/client/bootstrap') -WebSession $Session -UseBasicParsing
  $payload = $response.Content | ConvertFrom-Json

  if (-not $payload.ok) {
    throw 'Bootstrap returned ok=false'
  }

  return $payload
}

function Get-LeadsPayload {
  param([Microsoft.PowerShell.Commands.WebRequestSession]$Session)

  $response = Invoke-WebRequest -Uri ($baseUrl + '/api/client/leads') -WebSession $Session -UseBasicParsing
  $payload = $response.Content | ConvertFrom-Json

  if (-not $payload.ok) {
    throw 'Lead list returned ok=false'
  }

  return $payload
}

try {
  Write-Host '1. Login admin'
  $adminSession = Login-Admin

  Write-Host '2. Load bootstrap data'
  $bootstrap = Get-Bootstrap -Session $adminSession

  $existingSmokeOffer = @($bootstrap.offers | Where-Object { $_.title -eq $smokeOfferTitle }) | Select-Object -First 1
  $offerId = $null
  $offerNumber = $null

  if ($existingSmokeOffer) {
    Write-Host '3. Reuse existing smoke offer'
    $offerId = [string]$existingSmokeOffer.id
    $offerNumber = [string]$existingSmokeOffer.number
  } else {
    $leadId = $null
    $leadName = $null

    if (@($bootstrap.leadOptions).Count -gt 0) {
      $selectedLead = $bootstrap.leadOptions[0]
      $leadId = [string]$selectedLead.id
      $leadName = [string]$selectedLead.label
      Write-Host '3. Use existing lead option'
    } else {
      Write-Host '3. Create fallback smoke lead'
      $leadsPayload = Get-LeadsPayload -Session $adminSession
      $firstOpenStage = @($leadsPayload.stages | Where-Object { $_.kind -eq 'OPEN' } | Select-Object -First 1)

      if (-not $firstOpenStage) {
        throw 'No open lead stage available for fallback smoke lead'
      }

      $leadCreateBody = @{
        source = 'Smoke Test'
        fullName = $smokeLeadName
        email = $smokeLeadEmail
        phone = '+48500000000'
        interestedModel = 'BYD Seal'
        region = 'Warszawa'
        message = 'Smoke flow lead-offer-pdf'
        stageId = [string]$firstOpenStage.id
        salespersonId = ''
      } | ConvertTo-Json

      $leadCreateResponse = Invoke-WebRequest `
        -Uri ($baseUrl + '/api/client/leads') `
        -Method Post `
        -WebSession $adminSession `
        -ContentType 'application/json' `
        -Body $leadCreateBody `
        -UseBasicParsing
      $leadCreatePayload = $leadCreateResponse.Content | ConvertFrom-Json

      if (-not $leadCreatePayload.ok) {
        throw 'Fallback lead creation failed: ' + $leadCreatePayload.error
      }

      $leadId = [string]$leadCreatePayload.lead.id
      $leadName = [string]$leadCreatePayload.lead.fullName
    }

    Write-Host '4. Create offer from lead'
    $offerCreateBody = @{
      leadId = $leadId
      title = $smokeOfferTitle
      customerType = 'PRIVATE'
      financingVariant = 'kredyt'
      financingTermMonths = '36'
      financingInputValue = '20000'
      financingBuyoutPercent = '20'
      validUntil = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
      notes = 'Smoke flow lead-offer-pdf for ' + $leadName
    } | ConvertTo-Json

    $offerCreateResponse = Invoke-WebRequest `
      -Uri ($baseUrl + '/api/client/offers') `
      -Method Post `
      -WebSession $adminSession `
      -ContentType 'application/json' `
      -Body $offerCreateBody `
      -UseBasicParsing
    $offerCreatePayload = $offerCreateResponse.Content | ConvertFrom-Json

    if (-not $offerCreatePayload.ok) {
      throw 'Offer creation failed: ' + $offerCreatePayload.error
    }

    $offerId = [string]$offerCreatePayload.offer.id
    $offerNumber = [string]$offerCreatePayload.offer.number
  }

  Write-Host '5. Refresh offer detail'
  $offerResponse = Invoke-WebRequest -Uri ($baseUrl + '/api/client/offers/' + $offerId) -WebSession $adminSession -UseBasicParsing
  $offerPayload = $offerResponse.Content | ConvertFrom-Json
  if (-not $offerPayload.ok) {
    throw 'Offer detail failed: ' + $offerPayload.error
  }

  Write-Host '6. Save offer update before version creation'
  $patchBody = @{
    title = $smokeOfferTitle
    customerName = [string]$offerPayload.offer.customerName
    customerEmail = [string]$offerPayload.offer.customerEmail
    customerPhone = [string]$offerPayload.offer.customerPhone
    financingVariant = 'kredyt'
    financingTermMonths = '36'
    financingInputValue = '20000'
    financingBuyoutPercent = '20'
    validUntil = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
    notes = 'Smoke flow validated'
  } | ConvertTo-Json

  $patchResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/offers/' + $offerId) `
    -Method Patch `
    -WebSession $adminSession `
    -ContentType 'application/json' `
    -Body $patchBody `
    -UseBasicParsing
  $patchPayload = $patchResponse.Content | ConvertFrom-Json
  if (-not $patchPayload.ok) {
    throw 'Offer update failed: ' + $patchPayload.error
  }

  Write-Host '7. Create PDF version'
  $versionResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/offers/' + $offerId + '/pdf-version') `
    -Method Post `
    -WebSession $adminSession `
    -UseBasicParsing
  $versionPayload = $versionResponse.Content | ConvertFrom-Json

  if (-not $versionPayload.ok) {
    throw 'PDF version creation failed: ' + $versionPayload.error
  }

  $versionId = [string]$versionPayload.version.id
  if (-not $versionId) {
    throw 'Missing version id after PDF version creation'
  }

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

  Write-Host '9. Open PDF page'
  $pdfResponse = Invoke-WebRequest -Uri ($baseUrl + '/offers/' + $offerId + '/pdf?versionId=' + $versionId) -WebSession $adminSession -UseBasicParsing

  if ($pdfResponse.StatusCode -ne 200) {
    throw 'PDF page did not return 200'
  }

  if ($pdfResponse.Content -notmatch 'offer-pdf-document') {
    throw 'PDF page content does not include document marker'
  }

  Write-Host ('SMOKE_OK offerId=' + $offerId + ' offerNumber=' + $offerNumber + ' versionId=' + $versionId)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}