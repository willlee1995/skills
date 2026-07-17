# Safe install of Cursor user hooks from this skills-repo folder.
# Does NOT use `skillshare sync extras` against ~/.cursor (copy+prune is unsafe there).
$ErrorActionPreference = 'Stop'

$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$cursorHome = Join-Path $env:USERPROFILE '.cursor'
$hooksDir = Join-Path $cursorHome 'hooks'

$required = @(
    (Join-Path $source 'hooks.json'),
    (Join-Path $source 'hooks\skillshare-session-start.ps1'),
    (Join-Path $source 'hooks\wiki-session-start.ps1')
)
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

# Merge hooks.json if the other machine already has unrelated hooks.
$srcHooks = Get-Content (Join-Path $source 'hooks.json') -Raw | ConvertFrom-Json
$destHooksPath = Join-Path $cursorHome 'hooks.json'
if (Test-Path -LiteralPath $destHooksPath) {
    $destHooks = Get-Content $destHooksPath -Raw | ConvertFrom-Json
} else {
    $destHooks = [pscustomobject]@{ version = 1; hooks = [pscustomobject]@{} }
}

if (-not $destHooks.hooks) {
    $destHooks | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) -Force
}

$session = @()
if ($destHooks.hooks.sessionStart) {
    $session = @($destHooks.hooks.sessionStart)
}

function Add-HookCommand([object[]]$list, [string]$command, [int]$timeout) {
    $exists = $false
    foreach ($item in $list) {
        if ($item.command -eq $command) { $exists = $true; break }
    }
    if (-not $exists) {
        $list += [pscustomobject]@{ command = $command; timeout = $timeout }
    }
    return $list
}

foreach ($item in @($srcHooks.hooks.sessionStart)) {
    $session = Add-HookCommand $session ([string]$item.command) ([int]$item.timeout)
}

$destHooks.version = 1
$destHooks.hooks | Add-Member -NotePropertyName sessionStart -NotePropertyValue $session -Force

$destHooks | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $destHooksPath -Encoding utf8

Copy-Item (Join-Path $source 'hooks\skillshare-session-start.ps1') $hooksDir -Force
Copy-Item (Join-Path $source 'hooks\wiki-session-start.ps1') $hooksDir -Force

Write-Host "OK: installed Cursor hooks into $cursorHome"
Write-Host "Reload Cursor (or start a new chat) so sessionStart hooks load."
