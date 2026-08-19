$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
}

Write-Host "=== GET OpenAPI Spec ==="
try {
    $resp = Invoke-RestMethod -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/" -Headers $headers -Method GET
    $resp | ConvertTo-Json -Depth 5 > "e:\Projects\expense tracker app\family_expense_tracker\openapi.json"
    Write-Host "OpenAPI spec saved to openapi.json"
} catch {
    Write-Host "HTTP Error: $($_.Exception.Response.StatusCode)"
}
