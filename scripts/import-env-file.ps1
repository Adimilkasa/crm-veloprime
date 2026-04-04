function Import-EnvFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Target = 'Process'
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Env file not found: $Path"
  }

  $loadedKeys = New-Object System.Collections.Generic.List[string]

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') {
      continue
    }

    if ($line -notmatch '^(?<key>[^#=]+)=(?<value>.*)$') {
      continue
    }

    $key = $matches['key'].Trim()
    $value = $matches['value']

    if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
      $value = $value.Substring(1, $value.Length - 2)
    }

    [System.Environment]::SetEnvironmentVariable($key, $value, $Target)
    $loadedKeys.Add($key)
  }

  return $loadedKeys
}