# Cursor sessionStart hook - pull/sync Skillshare global skills (fail-open).
# Source of truth: %APPDATA%\skillshare\skills (not ~/.cursor/skills).
# Requires: skillshare CLI on PATH (or default install path below).

$ErrorActionPreference = 'Continue'

# At most once per this many minutes (override with SKILLSHARE_HOOK_COOLDOWN_MINUTES).
$cooldownMinutes = 60
if ($env:SKILLSHARE_HOOK_COOLDOWN_MINUTES -match '^\d+$') {
    $cooldownMinutes = [int]$env:SKILLSHARE_HOOK_COOLDOWN_MINUTES
}

$stampDir = Join-Path $env:APPDATA 'skillshare'
$stampFile = Join-Path $stampDir 'cursor-hook-last-sync.txt'
$logFile = Join-Path $stampDir 'cursor-hook-sync.log'

function Write-HookLog([string]$msg) {
    try {
        if (-not (Test-Path -LiteralPath $stampDir)) {
            New-Item -ItemType Directory -Path $stampDir -Force | Out-Null
        }
        $line = '{0:o} {1}' -f (Get-Date).ToUniversalTime(), $msg
        Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
    }
    catch { }
}

function Find-Skillshare {
    $cmd = Get-Command skillshare -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }

    $fallback = Join-Path $env:LOCALAPPDATA 'Programs\skillshare\skillshare.exe'
    if (Test-Path -LiteralPath $fallback) { return $fallback }

    return $null
}

function Test-CooldownElapsed {
    if ($env:SKILLSHARE_HOOK_FORCE -eq '1') { return $true }
    if ($cooldownMinutes -le 0) { return $true }
    if (-not (Test-Path -LiteralPath $stampFile)) { return $true }

    try {
        $raw = (Get-Content -LiteralPath $stampFile -TotalCount 1 -ErrorAction Stop).Trim()
        $last = [datetime]::Parse($raw, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
        return ((Get-Date) - $last).TotalMinutes -ge $cooldownMinutes
    }
    catch {
        return $true
    }
}

function Touch-Stamp {
    try {
        if (-not (Test-Path -LiteralPath $stampDir)) {
            New-Item -ItemType Directory -Path $stampDir -Force | Out-Null
        }
        Set-Content -LiteralPath $stampFile -Value ((Get-Date).ToUniversalTime().ToString('o')) -Encoding utf8
    }
    catch { }
}

try {
    # Consume stdin so Cursor's JSON payload does not block the pipe.
    $null = [Console]::In.ReadToEnd()

    if (-not (Test-CooldownElapsed)) {
        Write-Output '{"additional_context":"","env":{}}'
        exit 0
    }

    $exe = Find-Skillshare
    if (-not $exe) {
        Write-HookLog 'skip: skillshare CLI not found'
        Write-Output '{"additional_context":"","env":{}}'
        exit 0
    }

    function Summarize-Output($obj) {
        $text = (($obj | Out-String) -replace '\s+', ' ').Trim()
        if ($text.Length -gt 500) { return $text.Substring(0, 500) }
        return $text
    }

    function Test-PullSucceeded($exitCode, [string]$text) {
        # skillshare pull currently exits 0 even when blocked by local changes.
        if ($exitCode -ne 0) { return $false }
        if ($text -match 'Local changes detected') { return $false }
        if ($text -match '✗') { return $false }
        return $true
    }

    $pull = & $exe pull 2>&1
    $pullCode = $LASTEXITCODE
    $pullText = Summarize-Output $pull
    Write-HookLog ("pull exit={0} :: {1}" -f $pullCode, $pullText)

    if (-not (Test-PullSucceeded $pullCode $pullText)) {
        # Dirty tree / network / conflicts: still redistribute local source to Cursor copy target.
        $sync = & $exe sync -g 2>&1
        $syncCode = $LASTEXITCODE
        Write-HookLog ("sync -g exit={0} :: {1}" -f $syncCode, (Summarize-Output $sync))
    }

    Touch-Stamp
}
catch {
    Write-HookLog ("error: {0}" -f $_.Exception.Message)
}

# Fail open: never block session creation.
Write-Output '{"additional_context":"","env":{}}'
exit 0
