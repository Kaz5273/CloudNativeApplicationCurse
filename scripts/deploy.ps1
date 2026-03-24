#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Idempotent deployment script for Gym Management System
.DESCRIPTION
    This script safely deploys the application by:
    - Stopping running containers (preserving data)
    - Pulling latest images from GHCR
    - Starting the application with docker-compose
.PARAMETER ImageTag
    The image tag to deploy (default: latest commit SHA)
.PARAMETER Owner
    The GitHub repository owner (default: kaz5273)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",
    
    [Parameter(Mandatory=$false)]
    [string]$Owner = "kaz5273"
)

# Script configuration
$ErrorActionPreference = "Stop"
$Owner = $Owner.ToLower()

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Gym Management System - Deployment Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop running containers (preserve volumes)
Write-Host "[1/4] Stopping running containers..." -ForegroundColor Yellow
try {
    docker compose down 2>$null
    Write-Host "✓ Containers stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠ No containers to stop or already stopped" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Pull latest images
Write-Host "[2/4] Pulling latest images from GHCR..." -ForegroundColor Yellow
try {
    Write-Host "  → Pulling backend image: ghcr.io/$Owner/cloudnative-backend:$ImageTag"
    docker pull "ghcr.io/$Owner/cloudnative-backend:$ImageTag"
    
    Write-Host "  → Pulling frontend image: ghcr.io/$Owner/cloudnative-frontend:$ImageTag"
    docker pull "ghcr.io/$Owner/cloudnative-frontend:$ImageTag"
    
    Write-Host "✓ Images pulled successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to pull images" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Tag images for docker-compose
Write-Host "[3/4] Tagging images for docker-compose..." -ForegroundColor Yellow
try {
    docker tag "ghcr.io/$Owner/cloudnative-backend:$ImageTag" "cloudnativeapplicationcurse-backend:latest"
    docker tag "ghcr.io/$Owner/cloudnative-frontend:$ImageTag" "cloudnativeapplicationcurse-frontend:latest"
    Write-Host "✓ Images tagged successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to tag images" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Start application
Write-Host "[4/4] Starting application..." -ForegroundColor Yellow
try {
    docker compose up -d
    Write-Host "✓ Application started successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start application" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verify deployment
Write-Host "Verifying deployment..." -ForegroundColor Yellow
$servicesOutput = docker compose ps --format "{{.Service}}|{{.State}}"

$allHealthy = $true
foreach ($line in $servicesOutput) {
    if ($line) {
        $parts = $line -split '\|'
        $name = $parts[0]
        $status = $parts[1]
        
        if ($status -eq "running") {
            Write-Host "  ✓ $name : $status" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $name : $status" -ForegroundColor Red
            $allHealthy = $false
        }
    }
}

Write-Host ""
if ($allHealthy) {
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  ✓ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application URLs:" -ForegroundColor Cyan
    Write-Host "  → Frontend: http://localhost:8080" -ForegroundColor White
    Write-Host "  → Backend:  http://localhost:3000" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  ✗ Deployment completed with warnings" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs with: docker compose logs -f" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
