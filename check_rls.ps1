$envContent = Get-Content "e:\Projects\expense tracker app\family_expense_tracker\.env"
$anonLine = $envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }
$anonKey = $anonLine -replace "^SUPABASE_ANON_KEY=", ""

$headers = @{
    "apikey" = $anonKey
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Check if there is a SQL execution RPC we can call
# Try calling pg_policies via rpc if available
Write-Host "=== Checking existing RLS policies via rpc ==="
try {
    $body = '{"query": "SELECT tablename, policyname, roles, cmd, qual FROM pg_policies WHERE schemaname = '"'"'public'"'"' AND tablename IN ('"'"'families'"'"', '"'"'members'"'"') ORDER BY tablename, policyname"}'
    $resp = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/rpc/query" -Headers $headers -Method POST -Body $body -UseBasicParsing
    Write-Host "Status: $($resp.StatusCode)"
    Write-Host "Body: $($resp.Content)"
} catch {
    Write-Host "RPC query not available: $($_.Exception.Response.StatusCode)"
    Write-Host "Body: $($_.ErrorDetails.Message)"
}

# Also check if there's an execute_sql function
Write-Host ""
Write-Host "=== Checking rowsecurity status ==="
try {
    $body2 = '{}'
    $resp2 = Invoke-WebRequest -Uri "https://eowvprknwokacnmickgt.supabase.co/rest/v1/rpc/get_rls_status" -Headers $headers -Method POST -Body $body2 -UseBasicParsing
    Write-Host "Status: $($resp2.StatusCode)"
    Write-Host "Body: $($resp2.Content)"
} catch {
    Write-Host "get_rls_status not available: $($_.Exception.Response.StatusCode)"
}
