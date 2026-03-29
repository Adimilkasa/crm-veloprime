param(
  [string]$BaseUrl = 'http://127.0.0.1:3005'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = $BaseUrl.TrimEnd('/')
$testEmail = 'smoke.sales.' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + '@veloprime.pl'
$initialPassword = 'Start123!'
$changedPassword = 'Zmiana123!'
$resetPassword = 'Reset123!'

function New-SmokeSession {
  return New-Object Microsoft.PowerShell.Commands.WebRequestSession
}

function Invoke-SmokeLogin {
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

function Assert-LoginSuccess {
  param(
    [string]$Email,
    [string]$Password
  )

  $session = New-SmokeSession
  $response = Invoke-SmokeLogin -Email $Email -Password $Password -Session $session

  if (-not $response) {
    throw 'No login response for ' + $Email
  }

  if ($response.StatusCode -ne 303) {
    throw 'Unexpected successful-login status for ' + $Email + ': ' + $response.StatusCode
  }

  if ($response.Headers.Location -notlike '*/dashboard') {
    throw 'Login did not redirect to dashboard for ' + $Email + ': ' + $response.Headers.Location
  }

  return $session
}

function Assert-LoginFailure {
  param(
    [string]$Email,
    [string]$Password
  )

  $session = New-SmokeSession
  $response = Invoke-SmokeLogin -Email $Email -Password $Password -Session $session

  if (-not $response) {
    throw 'No failed-login response for ' + $Email
  }

  if ($response.StatusCode -ne 303) {
    throw 'Unexpected failed-login status for ' + $Email + ': ' + $response.StatusCode
  }

  if ($response.Headers.Location -notlike '*/login?error=credentials') {
    throw 'Failed login did not end with credentials error for ' + $Email + ': ' + $response.Headers.Location
  }
}

try {
  Write-Host '1. Login admin'
  $adminSession = Assert-LoginSuccess -Email 'admin@veloprime.pl' -Password 'Admin123!'

  Write-Host '2. Fetch user list'
  $usersResponse = Invoke-WebRequest -Uri ($baseUrl + '/api/client/users') -WebSession $adminSession -UseBasicParsing
  $usersPayload = $usersResponse.Content | ConvertFrom-Json
  if (-not $usersPayload.ok) {
    throw 'GET /api/client/users returned ok=false'
  }

  Write-Host '3. Create test sales user'
  $createBody = @{
    fullName = 'Smoke Test Sales'
    email = $testEmail
    role = 'SALES'
    password = $initialPassword
    region = 'Warszawa'
    teamName = 'Smoke'
    reportsToUserId = 'demo-manager'
  } | ConvertTo-Json

  $createResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/users') `
    -Method Post `
    -WebSession $adminSession `
    -ContentType 'application/json' `
    -Body $createBody `
    -UseBasicParsing
  $createPayload = $createResponse.Content | ConvertFrom-Json

  if (-not $createPayload.ok) {
    throw 'User creation failed: ' + $createPayload.error
  }

  $userId = [string]$createPayload.user.id

  if (-not $userId) {
    throw 'Missing user.id after create user'
  }

  Write-Host '4. Login new user'
  $null = Assert-LoginSuccess -Email $testEmail -Password $initialPassword

  Write-Host '5. Change password as logged-in user'
  $userSession = Assert-LoginSuccess -Email $testEmail -Password $initialPassword
  $changeBody = @{ currentPassword = $initialPassword; newPassword = $changedPassword } | ConvertTo-Json
  $changeResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/account/password') `
    -Method Post `
    -WebSession $userSession `
    -ContentType 'application/json' `
    -Body $changeBody `
    -UseBasicParsing
  $changePayload = $changeResponse.Content | ConvertFrom-Json

  if (-not $changePayload.ok) {
    throw 'Password change failed: ' + $changePayload.error
  }

  Write-Host '6. Verify old and new password'
  Assert-LoginFailure -Email $testEmail -Password $initialPassword
  $null = Assert-LoginSuccess -Email $testEmail -Password $changedPassword

  Write-Host '7. Reset password as admin'
  $resetBody = @{ newPassword = $resetPassword } | ConvertTo-Json
  $resetResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/users/' + $userId + '/password-reset') `
    -Method Post `
    -WebSession $adminSession `
    -ContentType 'application/json' `
    -Body $resetBody `
    -UseBasicParsing
  $resetPayload = $resetResponse.Content | ConvertFrom-Json

  if (-not $resetPayload.ok) {
    throw 'Password reset failed: ' + $resetPayload.error
  }

  Write-Host '8. Verify password after reset'
  Assert-LoginFailure -Email $testEmail -Password $changedPassword
  $null = Assert-LoginSuccess -Email $testEmail -Password $resetPassword

  Write-Host '9. Lock account as admin'
  $statusResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/users/' + $userId + '/status') `
    -Method Patch `
    -WebSession $adminSession `
    -UseBasicParsing
  $statusPayload = $statusResponse.Content | ConvertFrom-Json

  if (-not $statusPayload.ok) {
    throw 'Account lock failed: ' + $statusPayload.error
  }

  if ($statusPayload.user.isActive -ne $false) {
    throw 'User was not locked'
  }

  Write-Host '10. Verify blocked-user login fails'
  Assert-LoginFailure -Email $testEmail -Password $resetPassword

  Write-Host '11. Unlock account and verify final login'
  $unblockResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/users/' + $userId + '/status') `
    -Method Patch `
    -WebSession $adminSession `
    -UseBasicParsing
  $unblockPayload = $unblockResponse.Content | ConvertFrom-Json

  if (-not $unblockPayload.ok) {
    throw 'Account unlock failed: ' + $unblockPayload.error
  }

  if ($unblockPayload.user.isActive -ne $true) {
    throw 'User was not unlocked'
  }

  $null = Assert-LoginSuccess -Email $testEmail -Password $resetPassword

  Write-Host '12. Cleanup by locking the smoke account again'
  $cleanupLockResponse = Invoke-WebRequest `
    -Uri ($baseUrl + '/api/client/users/' + $userId + '/status') `
    -Method Patch `
    -WebSession $adminSession `
    -UseBasicParsing
  $cleanupLockPayload = $cleanupLockResponse.Content | ConvertFrom-Json

  if (-not $cleanupLockPayload.ok) {
    throw 'Smoke cleanup lock failed: ' + $cleanupLockPayload.error
  }

  if ($cleanupLockPayload.user.isActive -ne $false) {
    throw 'Smoke cleanup did not lock the test user'
  }

  Write-Host ('SMOKE_OK userId=' + $userId + ' email=' + $testEmail)
} catch {
  Write-Host ('SMOKE_FAIL ' + $_.Exception.Message)
  exit 1
}