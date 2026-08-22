$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$body = @{
    family_id = "b4e16e52-a95f-4e6e-a6cf-dc8f85892010"
    member_id = "26852703-ab3d-4dc0-b713-7f316f39557b"
    description = "Test Expense Full"
    amount = 500
    payment_mode = "Cash"
    expense_date = "2026-08-22"
    expense_time = "10:00 PM"
} | ConvertTo-Json

Write-Host "=== TEST INSERT full ==="
try {
    $resp = Invoke-RestMethod -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/expenses" -Headers $headers -Method POST -Body $body
    Write-Host "SUCCESS!"
    $resp | ConvertTo-Json
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $responseBody = $reader.ReadToEnd()
    Write-Host "Body: $responseBody"
}
