param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')

function New-CleanupSession {
  return New-Object Microsoft.PowerShell.Commands.WebRequestSession
}

function Login-Admin {
  $session = New-CleanupSession
  $response = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/auth/login') `
    -Method Post `
    -WebSession $session `
    -Body @{ email = 'admin@veloprime.pl'; password = 'Admin123!' } `
    -ContentType 'application/x-www-form-urlencoded' `
    -MaximumRedirection 0 `
    -UseBasicParsing `
    -ErrorAction SilentlyContinue

  if (-not $response -or $response.StatusCode -ne 303 -or $response.Headers.Location -notlike '*/dashboard') {
    throw 'Admin login failed during smoke cleanup'
  }

  return $session
}

try {
  $adminSession = Login-Admin
  $usersResponse = Invoke-WebRequest -Uri ($baseUrl + '/api/client/users') -WebSession $adminSession -UseBasicParsing
  $usersPayload = $usersResponse.Content | ConvertFrom-Json

  if (-not $usersPayload.ok) {
    throw 'User list fetch failed during smoke cleanup'
  }

  $smokeUsers = @($usersPayload.users | Where-Object { $_.email -like 'smoke.sales.*' })
  $deactivated = 0

  foreach ($user in $smokeUsers) {
    if ($user.isActive) {
      $toggleResponse = Invoke-WebRequest `
        -Uri ($baseUrl + '/api/client/users/' + $user.id + '/status') `
        -Method Patch `
        -WebSession $adminSession `
        -UseBasicParsing
      $togglePayload = $toggleResponse.Content | ConvertFrom-Json

      if (-not $togglePayload.ok) {
        throw 'Failed to deactivate smoke user ' + $user.email
      }

      if ($togglePayload.user.isActive -ne $false) {
        throw 'Smoke user still active after toggle: ' + $user.email
      }

      $deactivated += 1
    }
  }

  Write-Host ('SMOKE_CLEANUP_OK total=' + $smokeUsers.Count + ' deactivated=' + $deactivated)
} catch {
  Write-Host ('SMOKE_CLEANUP_FAIL ' + $_.Exception.Message)
  exit 1
}