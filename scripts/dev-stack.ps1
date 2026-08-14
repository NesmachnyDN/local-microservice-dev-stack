param(
    [ValidateSet('reset', 'up', 'down', 'clean', 'status', 'logs', 'config')]
    [string]$Action = 'reset',

    [ValidateSet('core', 'database', 'messaging', 'broker', 'all')]
    [string]$Profile = 'core'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Assert-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found."
    }
}

function New-LocalSecret {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) }
    finally { $rng.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
}

function Ensure-EnvironmentFile {
    if (Test-Path '.env') { return }

    Copy-Item '.env.example' '.env'
    $content = Get-Content '.env' -Raw
    $content = $content.Replace('POSTGRES_ADMIN_PASSWORD=__GENERATE__', "POSTGRES_ADMIN_PASSWORD=$(New-LocalSecret)")
    $content = $content.Replace('DEV_DATABASE_PASSWORD=__GENERATE__', "DEV_DATABASE_PASSWORD=$(New-LocalSecret)")
    $content = $content.Replace('ARTEMIS_PASSWORD=__GENERATE__', "ARTEMIS_PASSWORD=$(New-LocalSecret)")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $Root '.env'), $content, $utf8NoBom)
    Write-Host 'Created .env with generated local-only credentials.'
}

function Read-EnvFile {
    $values = @{}
    foreach ($line in Get-Content '.env') {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        $parts = $trimmed.Split('=', 2)
        if ($parts.Count -eq 2) { $values[$parts[0]] = $parts[1] }
    }
    return $values
}

function Show-Endpoints {
    $envValues = Read-EnvFile
    Write-Host ''
    Write-Host "Local infrastructure profile '$Profile' is ready."

    if ($Profile -in @('core', 'database', 'all')) {
        Write-Host "PostgreSQL: localhost:$($envValues['POSTGRES_PORT'])"
        Write-Host "Databases:  $($envValues['DEV_DATABASES'])"
    }
    if ($Profile -in @('core', 'messaging', 'all')) {
        Write-Host "Kafka:      localhost:$($envValues['KAFKA_PORT'])"
    }
    if ($Profile -in @('broker', 'all')) {
        Write-Host "Artemis:    localhost:$($envValues['ARTEMIS_CORE_PORT'])"
        Write-Host "Console:    http://localhost:$($envValues['ARTEMIS_WEB_PORT'])"
    }

    Write-Host ''
    Write-Host 'Run application microservices from the IDE and point them at these endpoints.'
}

Assert-Command 'docker'
Ensure-EnvironmentFile
& docker compose version | Out-Null

$composeArgs = @('compose', '--profile', $Profile)

switch ($Action) {
    'reset' {
        & docker compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { throw 'docker compose down failed' }
        & docker @composeArgs up -d --wait
        if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }
        Show-Endpoints
    }
    'up' {
        & docker @composeArgs up -d --wait
        if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }
        Show-Endpoints
    }
    'down' { & docker compose down --remove-orphans }
    'clean' { & docker compose down --volumes --remove-orphans }
    'status' { & docker @composeArgs ps }
    'logs' { & docker @composeArgs logs --follow }
    'config' { & docker @composeArgs config }
}

if ($LASTEXITCODE -ne 0) {
    throw "Docker Compose command failed with exit code $LASTEXITCODE"
}
