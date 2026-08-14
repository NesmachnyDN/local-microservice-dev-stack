param(
    [ValidateSet('reset', 'up', 'down', 'clean', 'status', 'logs', 'config')]
    [string]$Action = 'reset'
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
    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }
    return ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
}

function Ensure-EnvironmentFile {
    if (Test-Path '.env') {
        return
    }

    Copy-Item '.env.example' '.env'
    $content = Get-Content '.env' -Raw
    $content = $content.Replace('POSTGRES_ADMIN_PASSWORD=__GENERATE__', "POSTGRES_ADMIN_PASSWORD=$(New-LocalSecret)")
    $content = $content.Replace('DEV_DATABASE_PASSWORD=__GENERATE__', "DEV_DATABASE_PASSWORD=$(New-LocalSecret)")
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
    $postgresPort = if ($envValues['POSTGRES_PORT']) { $envValues['POSTGRES_PORT'] } else { '5432' }
    $kafkaPort = if ($envValues['KAFKA_PORT']) { $envValues['KAFKA_PORT'] } else { '9092' }

    Write-Host ''
    Write-Host 'Local infrastructure is ready.'
    Write-Host "PostgreSQL: localhost:$postgresPort"
    Write-Host "Kafka:      localhost:$kafkaPort"
    Write-Host "Databases:  $($envValues['DEV_DATABASES'])"
    Write-Host ''
    Write-Host 'Run application microservices from the IDE and point them at these endpoints.'
}

Assert-Command 'docker'
Ensure-EnvironmentFile
& docker compose version | Out-Null

switch ($Action) {
    'reset' {
        & docker compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { throw 'docker compose down failed' }
        & docker compose up -d --wait
        if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }
        Show-Endpoints
    }
    'up' {
        & docker compose up -d --wait
        if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed' }
        Show-Endpoints
    }
    'down' { & docker compose down --remove-orphans }
    'clean' { & docker compose down --volumes --remove-orphans }
    'status' { & docker compose ps }
    'logs' { & docker compose logs --follow }
    'config' { & docker compose config }
}

if ($LASTEXITCODE -ne 0) {
    throw "Docker Compose command failed with exit code $LASTEXITCODE"
}
