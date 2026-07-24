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
Write-Host "Starting Acquisition App in Development Mode" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Check .env.development exists
# ---------------------------------------------------------------------------
if (-not (Test-Path ".env.development")) {
    Write-Fail ".env.development file not found!`n   Please copy .env.development from the template and update with your Neon credentials."
}
Write-Ok ".env.development found"

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
# 3. Create .neon_local directory
# ---------------------------------------------------------------------------
if (-not (Test-Path ".neon_local")) {
    New-Item -ItemType Directory -Path ".neon_local" | Out-Null
}
Write-Ok ".neon_local directory ready"

# ---------------------------------------------------------------------------
# 4. Ensure .neon_local/ is in .gitignore
# ---------------------------------------------------------------------------
$gitignore = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
if ($gitignore -and -not $gitignore.Contains(".neon_local/")) {
    Add-Content -Path ".gitignore" -Value ".neon_local/"
    Write-Ok "Added .neon_local/ to .gitignore"
}

# ---------------------------------------------------------------------------
# 5. Build and start containers
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Building and starting development containers..."
Write-Info "  - Neon Local proxy will create an ephemeral database branch"
Write-Info "  - Application will run on http://localhost:3000"
Write-Host ""

docker compose -f docker-compose.dev.yml up --build

Write-Ok "Neon Local is healthy"

# ---------------------------------------------------------------------------
# 7. Run database migrations inside the container
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Applying database migrations..."
docker compose -f docker-compose.dev.yml exec app npx drizzle-kit migrate
Write-Ok "Migrations applied"

# ---------------------------------------------------------------------------
# 8. Verify app is reachable
# ---------------------------------------------------------------------------
Start-Sleep -Seconds 2
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Ok "App is healthy at http://localhost:3000"
} catch {
    Write-Warn "App may still be starting - check http://localhost:3000 in a few seconds"
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Development environment started!" -ForegroundColor Green
Write-Host "   Application:    http://localhost:3000"
Write-Host "   Health check:   http://localhost:3000/health"
Write-Host "   Neon Local DB:  localhost:5432"
Write-Host ""
Write-Host "To stop: docker compose -f docker-compose.dev.yml down"
Write-Host "To stop & delete branch: docker compose -f docker-compose.dev.yml down -v"
Write-Host ""
