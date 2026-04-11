# update-my-skills (bulk skill sync)

For syncing **many** skills at once between `my-tools/skills` and `~/.cursor/skills`, use the **update-my-skills** skill if present globally.

Typical script paths:

- `$HOME/.cursor/skills/update-my-skills/scripts/sync-repo-to-global.sh` — copy every skill from repo to global.
- `$HOME/.cursor/skills/update-my-skills/scripts/sync-paths-to-repo.sh` — copy given skill dirs into `my-tools/skills` with optional `--commit` / `--push`.

The **my-tools** skill’s `cursor-asset-sync.sh` adds: **rules**, **agents**, **archived** (Codex paths in repo), **subfolders** (e.g. `Legacy`), and **inferred bucket** from the source path.
