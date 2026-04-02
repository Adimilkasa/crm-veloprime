function New-SmokeSession {
  return New-Object Microsoft.PowerShell.Commands.WebRequestSession
}

function Invoke-FormLogin {
  param(
    [string]$BaseUrl,
    [string]$Email,
    [string]$Password,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session
  )

  return Invoke-WebRequest `
    -Uri ($BaseUrl.TrimEnd('/') + '/api/auth/login') `
    -Method Post `
    -WebSession $Session `
    -Body @{ email = $Email; password = $Password } `
    -ContentType 'application/x-www-form-urlencoded' `
    -MaximumRedirection 0 `
    -UseBasicParsing `
    -ErrorAction SilentlyContinue
}

function Login-Admin {
  param([string]$BaseUrl)

  $session = New-SmokeSession
  $response = Invoke-FormLogin -BaseUrl $BaseUrl -Email 'admin@veloprime.pl' -Password 'Admin123!' -Session $session

  if (-not $response -or $response.StatusCode -ne 303 -or $response.Headers.Location -notlike '*/dashboard') {
    throw 'Admin login failed for smoke test'
  }

  return $session
}

function Get-Bootstrap {
  param(
    [string]$BaseUrl,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session
  )

  $response = Invoke-WebRequest -Uri ($BaseUrl.TrimEnd('/') + '/api/client/bootstrap') -WebSession $Session -UseBasicParsing
  $payload = $response.Content | ConvertFrom-Json

  if (-not $payload.ok) {
    throw 'Bootstrap returned ok=false'
  }

  return $payload
}

function Get-LeadsPayload {
  param(
    [string]$BaseUrl,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session
  )

  $response = Invoke-WebRequest -Uri ($BaseUrl.TrimEnd('/') + '/api/client/leads') -WebSession $Session -UseBasicParsing
  $payload = $response.Content | ConvertFrom-Json

  if (-not $payload.ok) {
    throw 'Lead list returned ok=false'
  }

  return $payload
}

function Ensure-SmokeOfferVersion {
  param(
    [string]$BaseUrl,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [string]$SmokeOfferTitle,
    [string]$SmokeLeadName,
    [string]$SmokeLeadEmail,
    [string]$SmokePhone,
    [string]$SmokeMessage,
    [string]$ValidatedNotes,
    [string]$StepLabelPrefix,
    [string]$CustomerEmail = ''
  )

  Write-Host ($StepLabelPrefix + '. Load bootstrap data')
  $bootstrap = Get-Bootstrap -BaseUrl $BaseUrl -Session $Session

  $existingSmokeOffer = @($bootstrap.offers | Where-Object { $_.title -eq $SmokeOfferTitle }) | Select-Object -First 1
  $offerId = $null
  $offerNumber = $null

  if ($existingSmokeOffer) {
    Write-Host (([int]$StepLabelPrefix + 1).ToString() + '. Reuse existing smoke offer')
    $offerId = [string]$existingSmokeOffer.id
    $offerNumber = [string]$existingSmokeOffer.number
  } else {
    $leadId = $null
    $leadName = $null

    if (@($bootstrap.leadOptions).Count -gt 0) {
      $selectedLead = $bootstrap.leadOptions[0]
      $leadId = [string]$selectedLead.id
      $leadName = [string]$selectedLead.label
      Write-Host (([int]$StepLabelPrefix + 1).ToString() + '. Use existing lead option')
    } else {
      Write-Host (([int]$StepLabelPrefix + 1).ToString() + '. Create fallback smoke lead')
      $leadsPayload = Get-LeadsPayload -BaseUrl $BaseUrl -Session $Session
      $firstOpenStage = @($leadsPayload.stages | Where-Object { $_.kind -eq 'OPEN' } | Select-Object -First 1)

      if (-not $firstOpenStage) {
        throw 'No open lead stage available for fallback smoke lead'
      }

      $leadCreateBody = @{
        source = 'Smoke Test'
        fullName = $SmokeLeadName
        email = $SmokeLeadEmail
        phone = $SmokePhone
        interestedModel = 'BYD Seal'
        region = 'Warszawa'
        message = $SmokeMessage
        stageId = [string]$firstOpenStage.id
        salespersonId = ''
      } | ConvertTo-Json

      $leadCreateResponse = Invoke-WebRequest `
        -Uri ($BaseUrl.TrimEnd('/') + '/api/client/leads') `
        -Method Post `
        -WebSession $Session `
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

    Write-Host (([int]$StepLabelPrefix + 2).ToString() + '. Create offer from lead')
    $offerCreateBody = @{
      leadId = $leadId
      title = $SmokeOfferTitle
      customerType = 'PRIVATE'
      financingVariant = 'kredyt'
      financingTermMonths = '36'
      financingInputValue = '20000'
      financingBuyoutPercent = '20'
      validUntil = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
      notes = $SmokeMessage + ' for ' + $leadName
    } | ConvertTo-Json

    $offerCreateResponse = Invoke-WebRequest `
      -Uri ($BaseUrl.TrimEnd('/') + '/api/client/offers') `
      -Method Post `
      -WebSession $Session `
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

  Write-Host (([int]$StepLabelPrefix + 3).ToString() + '. Refresh offer detail')
  $offerResponse = Invoke-WebRequest -Uri ($BaseUrl.TrimEnd('/') + '/api/client/offers/' + $offerId) -WebSession $Session -UseBasicParsing
  $offerPayload = $offerResponse.Content | ConvertFrom-Json
  if (-not $offerPayload.ok) {
    throw 'Offer detail failed: ' + $offerPayload.error
  }

  Write-Host (([int]$StepLabelPrefix + 4).ToString() + '. Save offer update before version creation')
  $patchBody = @{
    title = $SmokeOfferTitle
    customerName = [string]$offerPayload.offer.customerName
    customerEmail = $(if ($CustomerEmail) { $CustomerEmail } else { [string]$offerPayload.offer.customerEmail })
    customerPhone = [string]$offerPayload.offer.customerPhone
    financingVariant = 'kredyt'
    financingTermMonths = '36'
    financingInputValue = '20000'
    financingBuyoutPercent = '20'
    validUntil = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
    notes = $ValidatedNotes
  } | ConvertTo-Json

  $patchResponse = Invoke-WebRequest `
    -Uri ($BaseUrl.TrimEnd('/') + '/api/client/offers/' + $offerId) `
    -Method Patch `
    -WebSession $Session `
    -ContentType 'application/json' `
    -Body $patchBody `
    -UseBasicParsing
  $patchPayload = $patchResponse.Content | ConvertFrom-Json
  if (-not $patchPayload.ok) {
    throw 'Offer update failed: ' + $patchPayload.error
  }

  Write-Host (([int]$StepLabelPrefix + 5).ToString() + '. Create PDF version')
  $versionResponse = Invoke-WebRequest `
    -Uri ($BaseUrl.TrimEnd('/') + '/api/client/offers/' + $offerId + '/pdf-version') `
    -Method Post `
    -WebSession $Session `
    -UseBasicParsing
  $versionPayload = $versionResponse.Content | ConvertFrom-Json

  if (-not $versionPayload.ok) {
    throw 'PDF version creation failed: ' + $versionPayload.error
  }

  $versionId = [string]$versionPayload.version.id
  if (-not $versionId) {
    throw 'Missing version id after PDF version creation'
  }

  return [pscustomobject]@{
    Bootstrap = $bootstrap
    OfferId = $offerId
    OfferNumber = $offerNumber
    VersionId = $versionId
  }
}