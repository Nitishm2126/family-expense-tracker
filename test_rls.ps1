$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

Write-Host "=== TEST A: GET /members (no filter) ==="
try {
    $resp = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/members?select=id,family_id,name" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP Status: $($resp.StatusCode)"
    Write-Host "Body: $($resp.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    Write-Host "Body: $($_.ErrorDetails.Message)"
}

Write-Host ""
Write-Host "=== TEST B: GET /families ==="
try {
    $resp2 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/families?select=*" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP Status: $($resp2.StatusCode)"
    Write-Host "Body: $($resp2.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    Write-Host "Body: $($_.ErrorDetails.Message)"
}
