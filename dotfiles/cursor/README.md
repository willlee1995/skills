# Cursor user hooks (carried in skills git repo)

Synced across machines via the Skillshare **skills** git remote (`skillshare pull` / `push`), **not** via Skillshare extras targeting `~/.cursor`.

## Why not extras?

`skillshare sync extras` in **copy** mode against `~/.cursor` can prune unrelated Cursor files. Use `install.ps1` instead (explicit copy + hooks.json merge).

## Install / refresh on a machine

After Skillshare source is available (`skillshare pull` or clone):

```powershell
cd "$env:APPDATA\skillshare\skills\dotfiles\cursor"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Files

| Path | Purpose |
|------|---------|
| `hooks.json` | Registers wiki + skillshare `sessionStart` hooks |
| `hooks/wiki-session-start.ps1` | Injects LLM wiki context |
| `hooks/skillshare-session-start.ps1` | `skillshare pull`, fallback `sync -g`, 60m cooldown |
| `install.ps1` | Safe installer for other machines |

## Edit workflow

1. Edit live files under `~/.cursor/hooks*` **or** edit this folder, then run `install.ps1`.
2. Copy changes back into this `dotfiles/cursor` folder if you edited live.
3. Commit + `skillshare push` (or `git push` from the skills repo).
