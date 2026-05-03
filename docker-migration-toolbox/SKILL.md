---
name: docker-migration-toolbox
description: Designs and operates a self-contained Docker migration image plus host launcher scripts for database/CMS migrations in air-gapped or split Linux vs Docker Desktop environments. Covers build-from-root COPY layout, docker.sock and host-pwd mounts, prod gates, mandatory dry-runs, JIT env prompts, and offline docker save/load. Use when building or porting a migration toolbox image, wiring docker run wrappers, or migrating a similar stack (Postgres + API/CMS + bash phase scripts) to another host.
---

# Docker migration toolbox

Reference implementation: `irpanel-revamp` under `scripts/migrations/docker/` (Dockerfile, `run-*.sh`, `menu.js`, `RUNBOOK.txt`) plus copied migration packs under `scripts/migrations/`.

## Design goals

1. **One artifact** — Operators carry a single image (`docker save` / `docker load`) instead of installing Node, Python, and ad-hoc deps on prod.
2. **Reproducible context** — Image bakes pinned script versions and `npm ci --omit=dev` (minimal `package.json` next to the Dockerfile).
3. **Same entrypoint, two modes** — Default: interactive orchestration (`CMD` → menu). Override: `docker run image path/to/script.js` so CI and docs stay aligned.
4. **Host integration without `docker cp`** — Bind-mount the operator’s `$PWD` to a well-known path (e.g. `/host-pwd`); default backup/export paths there so artifacts land on the host filesystem.
5. **Host Docker from inside the container** — Mount `/var/run/docker.sock` and install `docker-cli` when menu actions need `docker exec` against Postgres/CMS containers on the host.

## Dockerfile principles

- **Build context = repository root** — `docker build -f scripts/migrations/docker/Dockerfile -t <name>:latest .` so `COPY` paths stay stable and documented in Dockerfile comments.
- **Layer order** — Copy lockfiles first, `RUN npm ci`, then copy migration scripts and packs (better cache on dep-only changes).
- **Ship whole packs** — `COPY` directories (e.g. entire `phase*` trees) so auxiliary assets and shell scripts stay in sync; `chmod +x` on `*.sh` in a `RUN` so bind-mounted volumes are not required for execute bit.
- **Base image** — Small distro (e.g. `node:*-alpine`) plus only OS packages you need (`bash`, `curl`, `docker-cli`).
- **Runtime** — Set `NODE_ENV=production`, `NODE_PATH` if scripts resolve shared modules from `/app/node_modules`.
- **Entrypoint** — Fixed executable (`ENTRYPOINT ["node"]`) with default `CMD` for the menu keeps `docker run image <script>` valid (args after image go to Node).

## Launcher script (`run-*.sh`) principles

- `set -euo pipefail`; first arg selects **environment profile** (e.g. `linux` vs `desktop`).
- **Common `docker run` block** as an array: `-it --rm`, socket mount, host-pwd mount, `-e IRPANEL_HOST_PWD=$PWD` (or generic `*_HOST_PWD`) for display and path translation.
- **Forward secrets and knobs explicitly** — Use `-e VAR` (no value) only when the host has exported `VAR`; for automation defaults, pass `-e VAR=value` so unset host vars still get sane defaults (document the pitfall: bare `-e NAME` does nothing if not exported).
- **Networking split** — Linux same-host services: `--network host` + `http://localhost:...`. Docker Desktop: omit host networking; use `http://host.docker.internal:...`.
- **Critical ordering** — Document that all `-e` / `-v` flags must appear **before** the image name; anything after the image is consumed by the entrypoint (e.g. Node script args).

## Interactive menu (Node or other) principles

- **Just-in-time prompts** — For each action, collect only required env vars; if already set (forwarded from host), skip prompts. Prefer pre-export + forward for automation.
- **Short context before each prompt** — What the variable is, where to get it, default, sensitivity (password/token).
- **Mandatory dry-run** — Mutating actions: always run preview/dry path first, then separate confirm for apply.
- **Production gate** — Heuristic from URL host, container names, and/or `*_TARGET_ENV`; for prod, require typing a literal phrase (not a single `y`) before destructive/apply steps.
- **Path resolution** — Relative paths resolve against `/host-pwd` when mounted; show both in-container and on-host paths after writes.
- **Bash vs sh** — Alpine `sh` may break scripts using `pipefail` / `[[`; document `bash` entrypoint or self-reexec pattern.

## Safety and audit

- Pre-action summary that lists effective config (warn that tokens may appear in scrollback; rotate if recorded).
- Verbose dry output: default summary to terminal; full per-record logs to a file under `/host-pwd` for audit.
- Allow-list filters for bulk exports (e.g. status filters) so accidental scope expansion is harder.

## Offline / air-gapped flow

Document in image comments and runbook:

- `docker build ... -t <name>:latest .`
- `docker save -o <name>.tar <name>:latest`
- On target: `docker load -i <name>.tar`

## Porting checklist (new similar project)

1. **Inventory** — List all migration entrypoints (Node, SQL, bash phases) and their runtime deps; collapse to one `package.json` beside the Dockerfile if shared Node deps exist.
2. **COPY graph** — Replace paths with new repo layout; keep “build from root” rule or document a different context.
3. **Launcher** — Adjust default container names, DB names, URLs, prod-host allowlists, and `host.docker.internal` vs `host` profile.
4. **Menu mapping** — Wire script paths to menu choices; keep dry/apply split and prod gate for each mutator.
5. **RUNBOOK** — One operator-facing file: build/save/load, env vars, prod gate, permissions note (root in container may own files on host — `chown` hint).
6. **Non-interactive** — Document `docker run --rm image path/to/script.js` (and env vars) for CI; if no TTY, define behavior (exit with help vs run default).

## Optional deep reference

When mirroring IR Panel exactly, read the vendored operator doc at `scripts/migrations/docker/RUNBOOK.txt` in the repo (it duplicates and extends launcher behavior).
