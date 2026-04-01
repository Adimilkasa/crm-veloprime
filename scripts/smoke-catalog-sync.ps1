param(
  [string]$BaseUrl = 'http://127.0.0.1:3000'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')

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
    throw 'Admin login failed for catalog sync smoke test'
  }

  return $session
}

function Assert-PositiveCount {
  param(
    [string]$Label,
    [object]$Value
  )

  $parsed = [int]$Value
  if ($parsed -le 0) {
    throw ($Label + ' must be greater than zero')
  }
}

try {
  Write-Host '1. Login admin'
  $adminSession = Login-Admin

  Write-Host '2. Run legacy catalog sync'
  $syncResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/catalog/sync-legacy') `
    -Method Post `
    -WebSession $adminSession `
    -UseBasicParsing
  $syncPayload = $syncResponse.Content | ConvertFrom-Json

  if (-not $syncPayload.ok) {
    throw ('Legacy catalog sync failed: ' + $syncPayload.error)
  }

  Assert-PositiveCount -Label 'Synced brands' -Value $syncPayload.summary.brands
  Assert-PositiveCount -Label 'Synced models' -Value $syncPayload.summary.models
  Assert-PositiveCount -Label 'Synced versions' -Value $syncPayload.summary.versions
  Assert-PositiveCount -Label 'Synced pricingRecords' -Value $syncPayload.summary.pricingRecords

  Write-Host '3. Load catalog workspace'
  $workspaceResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/catalog/workspace') `
    -WebSession $adminSession `
    -UseBasicParsing
  $workspacePayload = $workspaceResponse.Content | ConvertFrom-Json

  if (-not $workspacePayload.ok) {
    throw ('Catalog workspace failed: ' + $workspacePayload.error)
  }

  Assert-PositiveCount -Label 'Workspace brands' -Value $workspacePayload.workspace.stats.brands
  Assert-PositiveCount -Label 'Workspace models' -Value $workspacePayload.workspace.stats.models
  Assert-PositiveCount -Label 'Workspace versions' -Value $workspacePayload.workspace.stats.versions
  Assert-PositiveCount -Label 'Workspace pricingRecords' -Value $workspacePayload.workspace.stats.pricingRecords

  Write-Host '4. Load bootstrap'
  $bootstrapResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/bootstrap') `
    -WebSession $adminSession `
    -UseBasicParsing
  $bootstrapPayload = $bootstrapResponse.Content | ConvertFrom-Json

  if (-not $bootstrapPayload.ok) {
    throw 'Bootstrap returned ok=false'
  }

  if (-not $bootstrapPayload.catalog) {
    throw 'Bootstrap payload is missing catalog section'
  }

  Assert-PositiveCount -Label 'Bootstrap brands' -Value (@($bootstrapPayload.catalog.brands).Count)
  Assert-PositiveCount -Label 'Bootstrap models' -Value (@($bootstrapPayload.catalog.models).Count)
  Assert-PositiveCount -Label 'Bootstrap versions' -Value (@($bootstrapPayload.catalog.versions).Count)
  Assert-PositiveCount -Label 'Bootstrap pricingOptions' -Value (@($bootstrapPayload.pricingOptions).Count)

  if (-not @($bootstrapPayload.manifest.versions | Where-Object { $_.artifactType -eq 'DATA' }).Count) {
    throw 'Bootstrap manifest is missing DATA version'
  }

  if (-not @($bootstrapPayload.manifest.versions | Where-Object { $_.artifactType -eq 'ASSETS' }).Count) {
    throw 'Bootstrap manifest is missing ASSETS version'
  }

  Write-Host ('SYNC_OK brands=' + [string]$workspacePayload.workspace.stats.brands + ' models=' + [string]$workspacePayload.workspace.stats.models + ' versions=' + [string]$workspacePayload.workspace.stats.versions + ' pricing=' + [string]$workspacePayload.workspace.stats.pricingRecords)
} catch {
  Write-Host ('SYNC_FAIL ' + $_.Exception.Message)
  exit 1
}