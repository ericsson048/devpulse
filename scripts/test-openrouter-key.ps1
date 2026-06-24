param(
  [Parameter(Mandatory)]
  [string]$Key
)

$headers = @{ Authorization = "Bearer $Key" }

try {
  $r = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/auth/key" -Headers $headers -ErrorAction Stop
  $d = $r.data
  Write-Host "[OK] Key valid" -ForegroundColor Green
  Write-Host "  Label    : $($d.label)" -ForegroundColor Cyan
  Write-Host "  Usage    : $($d.usage) / $($d.limit.limit)" -ForegroundColor Cyan
  Write-Host "  Remaining: $($d.limit.remaining)" -ForegroundColor Cyan
  Write-Host "  Is free  : $($d.is_free)" -ForegroundColor Cyan
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  Write-Host "[FAIL] Key invalid (HTTP $code)" -ForegroundColor Red
  exit 1
}
