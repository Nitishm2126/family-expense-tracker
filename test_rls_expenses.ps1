$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

Write-Host "=== TEST C: GET /expenses ==="
try {
    $resp3 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/expenses?limit=1" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "HTTP Status: $($resp3.StatusCode)"
    Write-Host "Body: $($resp3.Content)"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
    Write-Host "Body: $($_.ErrorDetails.Message)"
}
