$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

Write-Host "=== TEST 1: Can anon SELECT from members? ==="
try {
    $resp1 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/members?select=id,name,family_id&family_id=eq.b4e16e52-a95f-4e6e-a6cf-dc8f85892010&order=name" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP Status: $($resp1.StatusCode)"
    Write-Host "Body: $($resp1.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "Body: $($reader.ReadToEnd())"
}

Write-Host ""
Write-Host "=== TEST 2: Can anon SELECT from expenses? ==="
try {
    $resp2 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/expenses?select=*&limit=1" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP Status: $($resp2.StatusCode)"
    Write-Host "Body: $($resp2.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "Body: $($reader.ReadToEnd())"
}

Write-Host ""
Write-Host "=== TEST 3: Can anon INSERT into expenses (minimal valid row)? ==="
$body = @{
    family_id = "b4e16e52-a95f-4e6e-a6cf-dc8f85892010"
    member_id = "26852703-ab3d-4dc0-b713-7f316f39557b"
    description = "RLS diagnostic test"
    amount = 1
    payment_mode = "Cash"
    expense_date = "2026-08-22"
    expense_time = "10:00 AM"
} | ConvertTo-Json

try {
    $resp3 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/expenses" -Headers $headers -Method POST -Body $body -UseBasicParsing
    Write-Host "HTTP Status: $($resp3.StatusCode)"
    Write-Host "SUCCESS! Body: $($resp3.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errorBody = $reader.ReadToEnd()
    Write-Host "Body: $errorBody"
}

Write-Host ""
Write-Host "=== TEST 4: Check if RLS is even enabled on expenses ==="
Write-Host "(If SELECT works but INSERT fails with 42501, RLS is enabled but INSERT policy is missing/wrong for anon)"
