# PowerShell script for Windows development environment
Write-Host "Starting Batch Application Development Environment for Windows..." -ForegroundColor Green
Write-Host ""

# Set environment variables
$env:NODE_ENV = "development"
$env:PORT = "8088"
$env:FRONTEND_URL = "http://localhost:3001"

Write-Host "Environment Variables:" -ForegroundColor Yellow
Write-Host "NODE_ENV: $env:NODE_ENV"
Write-Host "PORT: $env:PORT"
Write-Host "FRONTEND_URL: $env:FRONTEND_URL"
Write-Host ""

# Check if pnpm is installed
if (!(Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: pnpm is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install pnpm: npm install -g pnpm" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if air is installed
if (!(Get-Command air -ErrorAction SilentlyContinue)) {
    Write-Host "Error: air is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install air: go install github.com/cosmtrek/air@latest" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Starting Next.js frontend on port 3001..." -ForegroundColor Cyan
$frontendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location static
    pnpm run dev
}

Write-Host "Waiting 3 seconds for frontend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Starting Golang backend with Air on port 8088..." -ForegroundColor Cyan
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    air -c .air.win.toml
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Development servers are running..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Frontend (Next.js): http://localhost:3001" -ForegroundColor White
Write-Host "Backend (Golang):   http://localhost:8088" -ForegroundColor White
Write-Host "Application:        http://localhost:8088" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop all servers..." -ForegroundColor Yellow

try {
    # Wait for jobs and show output
    while ($frontendJob.State -eq "Running" -or $backendJob.State -eq "Running") {
        Receive-Job $frontendJob
        Receive-Job $backendJob
        Start-Sleep -Seconds 1
    }
}
finally {
    Write-Host ""
    Write-Host "Stopping development servers..." -ForegroundColor Yellow
    
    # Stop jobs
    Stop-Job $frontendJob -ErrorAction SilentlyContinue
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $frontendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -ErrorAction SilentlyContinue
    
    # Kill processes
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name "main" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name "air" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host "Development servers stopped." -ForegroundColor Green
}
