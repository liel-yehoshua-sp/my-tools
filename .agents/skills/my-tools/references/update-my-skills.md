# update-my-skills (bulk skill sync)

For syncing **many** skills at once between `my-tools/skills` and your global skills directory (`SKILLS_GLOBAL`), use the **update-my-skills** skill if present globally.

Typical script paths (under `$SKILLS_GLOBAL/update-my-skills/scripts/`):

- `sync-repo-to-global.sh` — copy every skill from repo to global.
- `sync-paths-to-repo.sh` — copy given skill dirs into `my-tools/skills` with optional `--commit` / `--push`.

The **my-tools** skill’s `asset-sync.sh` adds: **rules**, **agents**, **archived** paths in repo, **`.agents/skills/…`** (same global target as `skills/…`), **subfolders** (e.g. `Legacy`), and **inferred bucket** from the source path.
