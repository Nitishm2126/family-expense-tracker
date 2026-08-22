$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""
$baseUrl = "https://eowvprknwokacnmickgt.supabase.co"

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

Write-Host "=== DIAG 1: anon SELECT member ==="
try {
    $r1 = Invoke-WebRequest -Uri "$baseUrl/rest/v1/members?select=id,name,family_id&id=eq.26852703-ab3d-4dc0-b713-7f316f39557b" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP $($r1.StatusCode)"
    Write-Host $r1.Content
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=== DIAG 2: anon INSERT expense (with category_id null) ==="
$body1 = '{"family_id":"b4e16e52-a95f-4e6e-a6cf-dc8f85892010","member_id":"26852703-ab3d-4dc0-b713-7f316f39557b","category_id":null,"description":"diag test","amount":1,"payment_mode":"Cash","expense_date":"2026-08-22","expense_time":"10:00 AM"}'
try {
    $r2 = Invoke-WebRequest -Uri "$baseUrl/rest/v1/expenses" -Headers $headers -Method POST -Body $body1 -UseBasicParsing
    Write-Host "HTTP $($r2.StatusCode) SUCCESS"
    Write-Host $r2.Content
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errBody = $reader.ReadToEnd()
    Write-Host "FAILED: $($_.Exception.Response.StatusCode)"
    Write-Host $errBody
}

Write-Host ""
Write-Host "=== DIAG 3: anon INSERT expense (NO category_id key) ==="
$body2 = '{"family_id":"b4e16e52-a95f-4e6e-a6cf-dc8f85892010","member_id":"26852703-ab3d-4dc0-b713-7f316f39557b","description":"diag test 2","amount":1,"payment_mode":"Cash","expense_date":"2026-08-22","expense_time":"10:00 AM"}'
try {
    $r3 = Invoke-WebRequest -Uri "$baseUrl/rest/v1/expenses" -Headers $headers -Method POST -Body $body2 -UseBasicParsing
    Write-Host "HTTP $($r3.StatusCode) SUCCESS"
    Write-Host $r3.Content
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errBody = $reader.ReadToEnd()
    Write-Host "FAILED: $($_.Exception.Response.StatusCode)"
    Write-Host $errBody
}

Write-Host ""
Write-Host "=== DIAG 4: anon INSERT expense (minimal: only required cols) ==="
$body3 = '{"family_id":"b4e16e52-a95f-4e6e-a6cf-dc8f85892010","member_id":"26852703-ab3d-4dc0-b713-7f316f39557b","amount":1}'
try {
    $r4 = Invoke-WebRequest -Uri "$baseUrl/rest/v1/expenses" -Headers $headers -Method POST -Body $body3 -UseBasicParsing
    Write-Host "HTTP $($r4.StatusCode) SUCCESS"
    Write-Host $r4.Content
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $errBody = $reader.ReadToEnd()
    Write-Host "FAILED: $($_.Exception.Response.StatusCode)"
    Write-Host $errBody
}
