# Cursor sessionStart hook - inject LLM Wiki maintainer context.
# Reads JSON from stdin; prints a single JSON object on stdout for Cursor to parse.
# Requires: PowerShell 5+ (Windows). No jq/node dependency.

$ErrorActionPreference = 'Stop'

function Emit-Json([hashtable]$obj) {
    $obj | ConvertTo-Json -Compress -Depth 6
}

function Safe-Slug([string]$name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return 'project' }
    $s = $name.Trim() -replace '[^a-zA-Z0-9._-]+', '-'
    if ([string]::IsNullOrWhiteSpace($s)) { return 'project' }
    return $s.ToLowerInvariant()
}

try {
    $stdin = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($stdin)) {
        Write-Output '{"additional_context":"","env":{}}'
        exit 0
    }

    $payload = $stdin | ConvertFrom-Json

    $roots = @()
    if ($null -ne $payload.workspace_roots) {
        $roots = @($payload.workspace_roots)
    }

    $projectRoot = ''
    if ($roots.Count -gt 0) {
        $projectRoot = [string]$roots[0]
    }

    $wikiRoot = $env:LLM_WIKI_ROOT
    if ([string]::IsNullOrWhiteSpace($wikiRoot)) {
        # Default: this repo path on this machine (override with LLM_WIKI_ROOT).
        $wikiRoot = 'C:\Users\willl\llm-wiki'
    }

    $wikiRootNorm = $wikiRoot.TrimEnd('\', '/')

    $isWikiRepo = $false
    if (-not [string]::IsNullOrWhiteSpace($projectRoot)) {
        $agents = Join-Path $projectRoot 'AGENTS.md'
        $idx = Join-Path $projectRoot 'wiki\index.md'
        $isWikiRepo = (Test-Path -LiteralPath $agents) -and (Test-Path -LiteralPath $idx)
    }

    $slug = Safe-Slug([IO.Path]::GetFileName($projectRoot.TrimEnd('\', '/')))

    $ctx = ''
    if ($isWikiRepo) {
        $ctx = @"
## LLM Wiki (canonical repo)

This workspace **is** the wiki repository. Before substantive work:

1. Read ``AGENTS.md``, ``wiki/index.md``, and the latest entries in ``wiki/log.md``.
2. **Never** edit anything under ``raw/`` (immutable sources).
3. Maintain ``wiki/`` per ``AGENTS.md`` (ingest / query / lint). Prefer ``wiki/spaces/<slug>/`` when isolating a different product or engagement inside the same vault.

When you finish a meaningful chunk of work, update ``wiki/index.md`` and append to ``wiki/log.md`` if the wiki changed.
"@
    }
    else {
        $agentsPath = Join-Path $wikiRootNorm 'AGENTS.md'
        $spaceRoot = Join-Path $wikiRootNorm (Join-Path 'wiki' (Join-Path 'spaces' $slug))
        $wikiIndex = Join-Path $wikiRootNorm (Join-Path 'wiki' 'index.md')
        $wikiLog = Join-Path $wikiRootNorm (Join-Path 'wiki' 'log.md')

        $ctx = @"
## LLM Wiki - cross-project capture

**Composer workspace root:** ``$projectRoot``
**Canonical wiki directory:** ``$wikiRootNorm`` (set environment variable ``LLM_WIKI_ROOT`` to override this default.)

When this session produces **durable** project insight (architecture decisions, incident root causes, API contracts, runbooks, naming conventions, non-obvious bugs), **compile it into the wiki** so it compounds across machines and future agents:

1. Open ``$agentsPath`` and follow its workflows.
2. File project-specific pages under ``$spaceRoot`` (create the folder if missing). Link to related global concept/entity pages when useful.
3. After substantive edits, refresh ``$wikiIndex`` and append an entry to ``$wikiLog`` (see heading format in ``AGENTS.md``).
4. Do **not** paste entire private codebases into the wiki; summarize and point back to paths or commits in this workspace when appropriate.

If the user only wanted ephemeral help and no wiki updates, skip wiki edits unless they ask.
"@
    }

    $out = @{
        additional_context = $ctx.Trim()
        env                = @{
            LLM_WIKI_ROOT          = $wikiRootNorm
            LLM_WIKI_PROJECT_ROOT  = $projectRoot
            LLM_WIKI_SPACE_SLUG    = $slug
        }
    }

    Write-Output (Emit-Json $out)
    exit 0
}
catch {
    # Fail open: never block session creation.
    Write-Output '{"additional_context":"","env":{}}'
    exit 0
}
