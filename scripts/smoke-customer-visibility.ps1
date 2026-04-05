param(
  [string]$BaseUrl = 'http://127.0.0.1:3006'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$smokeLeadName = 'Smoke Customer Visibility ' + $timestamp
$smokeLeadEmail = 'smoke.customer.visibility.' + $timestamp + '@veloprime.pl'
$smokeOfferTitle = 'SMOKE_CUSTOMER_VISIBILITY_' + $timestamp

function New-SmokeSession {
  return New-Object Microsoft.PowerShell.Commands.WebRequestSession
}

function Wait-ForServer {
  param([string]$Url)

  for ($attempt = 0; $attempt -lt 60; $attempt++) {
    try {
      $response = Invoke-WebRequest -Uri ($Url + '/login') -UseBasicParsing
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return
      }
    } catch {
    }

    Start-Sleep -Seconds 1
  }

  throw 'Server did not become ready for smoke test.'
}

function Login-User {
  param(
    [string]$Email,
    [string]$Password
  )

  $session = New-SmokeSession
  $response = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/auth/login') `
    -Method Post `
    -WebSession $session `
    -Body @{ email = $Email; password = $Password } `
    -ContentType 'application/x-www-form-urlencoded' `
    -MaximumRedirection 0 `
    -UseBasicParsing `
    -ErrorAction SilentlyContinue

  if (-not $response -or $response.StatusCode -ne 303 -or $response.Headers.Location -notlike '*/dashboard') {
    throw 'Login failed for ' + $Email
  }

  return $session
}

function Invoke-JsonRequest {
  param(
    [string]$Method,
    [string]$Uri,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [object]$Body = $null,
    [switch]$AllowErrorStatus
  )

  $requestSplat = @{
    Uri = $Uri
    Method = $Method
    WebSession = $Session
    UseBasicParsing = $true
    ErrorAction = 'Stop'
  }

  if ($null -ne $Body) {
    $requestSplat.ContentType = 'application/json'
    $requestSplat.Body = ($Body | ConvertTo-Json -Depth 10)
  }

  try {
    $response = Invoke-WebRequest @requestSplat
    $payload = if ($response.Content) { $response.Content | ConvertFrom-Json } else { $null }

    return [pscustomobject]@{
      StatusCode = [int]$response.StatusCode
      Payload = $payload
    }
  } catch {
    $response = $_.Exception.Response

    if (-not $response) {
      throw
    }

    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $content = $reader.ReadToEnd()
    $payload = $null

    if ($content) {
      try {
        $payload = $content | ConvertFrom-Json
      } catch {
      }
    }

    if (-not $AllowErrorStatus) {
      $message = if ($payload -and $payload.error) { [string]$payload.error } elseif ($content) { $content } else { $_.Exception.Message }
      throw ('Request failed [' + [int]$response.StatusCode + ']: ' + $message)
    }

    return [pscustomobject]@{
      StatusCode = [int]$response.StatusCode
      Payload = $payload
    }
  }
}

try {
  Write-Host '1. Wait for server on smoke-db'
  Wait-ForServer -Url $baseUrl

  Write-Host '2. Login seeded roles'
  $salesSession = Login-User -Email 'handlowiec@veloprime.pl' -Password 'Sales123!'
  $managerSession = Login-User -Email 'manager@veloprime.pl' -Password 'Manager123!'
  $directorSession = Login-User -Email 'dyrektor@veloprime.pl' -Password 'Director123!'
  $adminSession = Login-User -Email 'admin@veloprime.pl' -Password 'Admin123!'

  Write-Host '3. Load sales lead stages'
  $leadsResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/leads') -Session $salesSession
  if (-not $leadsResponse.Payload.ok) {
    throw 'Sales lead list returned ok=false'
  }

  $openStage = @($leadsResponse.Payload.stages | Where-Object { $_.kind -eq 'OPEN' } | Select-Object -First 1)
  if (-not $openStage) {
    throw 'No OPEN stage available for customer visibility smoke.'
  }

  Write-Host '4. Sales creates lead'
  $leadCreateResponse = Invoke-JsonRequest `
    -Method Post `
    -Uri ($baseUrl + '/api/client/leads') `
    -Session $salesSession `
    -Body @{
      source = 'Smoke Customer Visibility'
      fullName = $smokeLeadName
      email = $smokeLeadEmail
      phone = '+48500000031'
      interestedModel = 'BYD Seal'
      region = 'Warszawa'
      message = 'Smoke customer visibility flow'
      stageId = [string]$openStage.id
    }

  if (-not $leadCreateResponse.Payload.ok) {
    throw 'Lead creation returned ok=false'
  }

  $leadId = [string]$leadCreateResponse.Payload.lead.id
  if (-not $leadId) {
    throw 'Missing lead id after sales lead creation.'
  }

  Write-Host '5. Sales creates offer from lead'
  $offerCreateResponse = Invoke-JsonRequest `
    -Method Post `
    -Uri ($baseUrl + '/api/client/offers') `
    -Session $salesSession `
    -Body @{
      leadId = $leadId
      title = $smokeOfferTitle
      customerType = 'PRIVATE'
      financingVariant = 'kredyt'
      financingTermMonths = '36'
      financingInputValue = '15000'
      financingBuyoutPercent = '20'
      validUntil = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
      notes = 'Smoke customer visibility offer'
    }

  if (-not $offerCreateResponse.Payload.ok) {
    throw 'Offer creation returned ok=false'
  }

  $offerId = [string]$offerCreateResponse.Payload.offer.id
  if (-not $offerId) {
    throw 'Missing offer id after sales offer creation.'
  }

  Write-Host '6. Verify persisted offer leadId and customerId'
  $offerDetailResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/offers/' + $offerId) -Session $salesSession
  if (-not $offerDetailResponse.Payload.ok) {
    throw 'Offer detail returned ok=false'
  }

  if ([string]$offerDetailResponse.Payload.offer.leadId -ne $leadId) {
    throw 'Offer detail does not expose persisted leadId for the created offer.'
  }

  $leadDetailResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/leads/' + $leadId) -Session $salesSession
  if (-not $leadDetailResponse.Payload.ok) {
    throw 'Lead detail returned ok=false'
  }

  $customerId = [string]$leadDetailResponse.Payload.lead.customerId
  if (-not $customerId) {
    throw 'Lead detail does not contain customerId after offer creation.'
  }

  Write-Host '7. Verify customer workspace access by hierarchy'
  $managerCustomerResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/customers/' + $customerId) -Session $managerSession
  $directorCustomerResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/customers/' + $customerId) -Session $directorSession
  $adminCustomerResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/customers/' + $customerId) -Session $adminSession
  $salesCustomerResponse = Invoke-JsonRequest -Method Get -Uri ($baseUrl + '/api/client/customers/' + $customerId) -Session $salesSession -AllowErrorStatus

  foreach ($entry in @($managerCustomerResponse, $directorCustomerResponse, $adminCustomerResponse)) {
    if ($entry.StatusCode -ne 200 -or -not $entry.Payload.ok) {
      throw 'A management role could not open the customer workspace.'
    }
  }

  if ($salesCustomerResponse.StatusCode -ne 403) {
    throw 'Sales should not access customer workspace API directly; expected 403.'
  }

  Write-Host '8. Verify customer workspace contains the new lead and offer'
  if (-not @($managerCustomerResponse.Payload.relatedLeads | Where-Object { $_.id -eq $leadId })) {
    throw 'Manager customer workspace does not include the created lead.'
  }

  if (-not @($managerCustomerResponse.Payload.relatedOffers | Where-Object { $_.id -eq $offerId })) {
    throw 'Manager customer workspace does not include the created offer.'
  }

  Write-Host ('SMOKE_OK customerId=' + $customerId + ' leadId=' + $leadId + ' offerId=' + $offerId)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}