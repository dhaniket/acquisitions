# Development startup script for Acquisition App with Neon Local
# This script starts the application in development mode with Neon Local

$ErrorActionPreference = "Stop"

function Write-Info    { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red; exit 1 }

# Change to repo root (parent of scripts/ directory)
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ""
Write-Host "Starting Acquisition App in Production Mode" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Check .env.development exists
# ---------------------------------------------------------------------------
if (-not (Test-Path ".env.production")) {
    Write-Fail ".env.production file not found!`n   Please copy .env.production from the template and update with your Neon credentials."
}
Write-Ok ".env.production found"

# ---------------------------------------------------------------------------
# 2. Check Docker is running
# ---------------------------------------------------------------------------
try {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Fail "Docker is not running!`n   Please start Docker Desktop and try again."
}
Write-Ok "Docker is running"

# ---------------------------------------------------------------------------
# 5. Build and start containers
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Building and starting development containers..."
Write-Info "  - Using Neon Cloud Database (no local proxy)"
Write-Info "  - Running in optimized production mode"
Write-Host ""

docker compose -f docker-compose.prod.yml up --build -d

Write-Ok "Waiting for Neon Local to be ready..."
Start-Sleep -Seconds 5
# ---------------------------------------------------------------------------
# 7. Run database migrations inside the container
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Applying latest schema with Drizzle.."
npm run db:migrate

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "🎉 Production environment started!"
Write-Host "   Application:    http://localhost:3000"
Write-Host "   Health check:   http://localhost:3000/health"
Write-Host "   Logs: docker logs acquisition-app-prod"