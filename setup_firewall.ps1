# Run this script as Administrator to allow connections on port 5000
# Right-click PowerShell -> Run as Administrator

Write-Host "Setting up Windows Firewall for TourGuard Backend..." -ForegroundColor Green
Write-Host ""

try {
    # Check if rule already exists
    $existingRule = Get-NetFirewallRule -DisplayName "TourGuard Backend" -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "✅ Firewall rule already exists" -ForegroundColor Yellow
    } else {
        # Create new firewall rule
        New-NetFirewallRule -DisplayName "TourGuard Backend" `
            -Direction Inbound `
            -LocalPort 5000 `
            -Protocol TCP `
            -Action Allow `
            -Profile Domain,Private,Public
        
        Write-Host "✅ Firewall rule created successfully!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Port 5000 is now accessible from your network" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your PC IP: 10.38.111.74" -ForegroundColor Cyan
    Write-Host "Admin Panel: http://localhost:5000" -ForegroundColor Cyan
    Write-Host "API URL: http://10.38.111.74:5000/api" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you're running as Administrator!" -ForegroundColor Yellow
    Write-Host "Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"



