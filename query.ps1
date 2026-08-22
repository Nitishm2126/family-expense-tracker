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
    query = "SELECT tablename, policyname, roles, cmd, qual, with_check FROM pg_policies WHERE schemaname = 'public' AND tablename = 'expenses' ORDER BY policyname;"
} | ConvertTo-Json

try {
    $resp = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/rpc/query" -Headers $headers -Method POST -Body $body -UseBasicParsing
    Write-Host "Policies Response:"
    Write-Host $($resp.Content)
} catch {
    Write-Host "RPC query not available: $($_.Exception.Response.StatusCode)"
    Write-Host "Error details: $($_.ErrorDetails.Message)"
}

$body2 = @{
    query = "SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'expenses' ORDER BY ordinal_position;"
} | ConvertTo-Json

try {
    $resp2 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/rpc/query" -Headers $headers -Method POST -Body $body2 -UseBasicParsing
    Write-Host "Columns Response:"
    Write-Host $($resp2.Content)
} catch {
    Write-Host "RPC query not available: $($_.Exception.Response.StatusCode)"
    Write-Host "Error details: $($_.ErrorDetails.Message)"
}
