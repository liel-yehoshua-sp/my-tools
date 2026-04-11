---
name: my-tools
description: >
  Moves Cursor/Codex skills, rules, and agents between global directories (~/.cursor/skills,
  ~/.codex/skills, ~/.cursor/rules, ~/.cursor/agents) and the my-tools git repo with one-shot
  rsync, git commit, and git push. Use when the user mentions my-tools, /my-tools, moving or
  backing up a skill, rule, or agent into my-tools, syncing from my-tools to global, Legacy (or
  other) subfolders under skills, or fast non-interactive publish of personal tooling.
---

# my-tools

## When to use

- **Into repo**: copy or move a skill/rule/agent from a global path into `~/dev/slpt/my-tools`, optionally under a subfolder (e.g. `Legacy`), then **commit and push** in one command.
- **From repo**: copy (or move) from `my-tools` back to the right global directory.
- Prefer this skill for **single-asset moves** with git; for **bulk “all skills from repo → ~/.cursor/skills”**, use the **update-my-skills** scripts if installed (see [references/update-my-skills.md](references/update-my-skills.md)).

## Layout in `my-tools`

| Bucket | Repo path | Default global source/target |
|--------|-----------|-------------------------------|
| Cursor skills | `skills/…` | `$CURSOR_SKILLS_GLOBAL` (default `~/.cursor/skills`) |
| Codex skills (repo archive) | `archived/…` | `$CODEX_SKILLS_GLOBAL` (default `~/.codex/skills`) |
| Rules | `rules/…` | `$CURSOR_RULES_GLOBAL` (default `~/.cursor/rules`) |
| Agents | `agents/…` | `$CURSOR_AGENTS_GLOBAL` (default `~/.cursor/agents`) |

**Auto bucket** is inferred from the resolved path of `--src` (symlinks resolved). If a Codex skill should live under `skills/Legacy/…` instead of `archived/…`, pass `--bucket skills` explicitly (still requires `SKILL.md` in the folder).

## Script path (after this skill is installed under `~/.cursor/skills`):

`$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh`

From the **my-tools repo** working copy only:

`$MY_TOOLS_ROOT/skills/my-tools/scripts/cursor-asset-sync.sh`

### Move global → repo (default: **delete source** after success)

```bash
# Codex skill → repo (auto-detects archived bucket), Legacy subfolder, commit + push
bash "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh" to-repo \
  --src "$HOME/.codex/skills/csharp-developer" \
  --under Legacy \
  --commit "chore(archived): archive csharp-developer under Legacy" \
  --push

# Same skill but stored under repo skills/Legacy (override bucket)
bash "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh" to-repo \
  --src "$HOME/.codex/skills/csharp-developer" \
  --bucket skills \
  --under Legacy \
  --commit "chore(skills): move csharp-developer to Legacy" \
  --push

# Copy only (keep global copy)
bash "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh" to-repo \
  --src "$HOME/.cursor/skills/foo" \
  --commit "chore(skills): snapshot foo" \
  --push \
  --keep-source
```

### Repo → global (default: **keep** repo copy)

```bash
# Restore into ~/.cursor/skills/Legacy/foo (path after skills/)
bash "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh" from-repo \
  --src "skills/Legacy/foo"

# After restoring, remove from repo and push (optional)
bash "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh" from-repo \
  --src "skills/Legacy/foo" \
  --delete-repo-copy \
  --commit "chore(skills): remove Legacy/foo after restoring to global" \
  --push
```

### Environment overrides

| Variable | Default |
|----------|---------|
| `MY_TOOLS_ROOT` | `$HOME/dev/slpt/my-tools` |
| `CURSOR_SKILLS_GLOBAL` | `$HOME/.cursor/skills` |
| `CURSOR_RULES_GLOBAL` | `$HOME/.cursor/rules` |
| `CURSOR_AGENTS_GLOBAL` | `$HOME/.cursor/agents` |
| `CODEX_SKILLS_GLOBAL` | `$HOME/.codex/skills` |

## Agent workflow

1. Parse **direction** (to repo vs from repo), **paths**, optional **subfolder**, and **bucket** if the user named `skills` vs `archived`.
2. Build one `bash … cursor-asset-sync.sh` command; use a clear `chore(…): …` commit message.
3. **Run** the script (non-interactive); do not ask to confirm each git step unless the user asked for a dry run.
4. If the skill folder is missing from global (e.g. first install), run from `$MY_TOOLS_ROOT/skills/my-tools/scripts/cursor-asset-sync.sh`.
5. If `chmod +x` was lost: `chmod +x "$HOME/.cursor/skills/my-tools/scripts/cursor-asset-sync.sh"`.

## Requirements

`bash`, `rsync`, `python3` (for `realpath` fallback), `git`. Remote `git push` must succeed (credentials/SSH already work).

## See also

- [references/update-my-skills.md](references/update-my-skills.md) — bulk sync between repo and global skills.
