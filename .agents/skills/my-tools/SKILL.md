---
name: my-tools
description: >
  Moves skills, rules, and agents between global install directories and the my-tools git repo with
  one-shot rsync, git commit, and git push. Use when the user mentions my-tools, /my-tools, moving or
  backing up a skill, rule, or agent into my-tools, syncing from my-tools to global, Legacy (or
  other) subfolders under skills, or fast non-interactive publish of personal tooling.
---

# my-tools

## When to use

- **Into repo**: copy or move a skill/rule/agent from a global path into `~/dev/slpt/my-tools`, optionally under a subfolder (e.g. `Legacy`), then **commit and push** in one command.
- **From repo**: copy (or move) from `my-tools` back to the right global directory.
- Prefer this skill for **single-asset moves** with git; for **bulk “all repo skills → global”**, use the **update-my-skills** scripts if installed (see [references/update-my-skills.md](references/update-my-skills.md)).

## Layout in `my-tools`

| Bucket | Repo path | Global source/target (env) |
|--------|-----------|----------------------------|
| Skills | `skills/…` | `SKILLS_GLOBAL` |
| Skills (`.agents` layout) | `.agents/skills/…` | `SKILLS_GLOBAL` (same as `skills/…`) |
| Archived skills | `archived/…` | `ARCHIVED_SKILLS_GLOBAL` |
| Rules | `rules/…` | `RULES_GLOBAL` |
| Agents | `agents/…` | `AGENTS_GLOBAL` |

Defaults for those env vars match common editor layouts under `$HOME`; override them if your paths differ. See `scripts/asset-sync.sh` for exact fallbacks.

**Auto bucket** is inferred from the resolved path of `--src` (symlinks resolved). If a skill under the **archived** tree should live under `skills/Legacy/…` instead, pass `--bucket skills` explicitly (still requires `SKILL.md` in the folder). To write under `.agents/skills/…` in the repo (e.g. this skill’s checkout), use **`--bucket dotagents-skills`** on `to-repo`.

## Script path (after this skill is installed globally under your skills root):

`$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh`

From the **my-tools repo** working copy only:

`$MY_TOOLS_ROOT/.agents/skills/my-tools/scripts/asset-sync.sh`

### Move global → repo (default: **delete source** after success)

```bash
# Archived-tree skill → repo (auto-detects archived bucket), Legacy subfolder, commit + push
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" to-repo \
  --src "${ARCHIVED_SKILLS_GLOBAL}/csharp-developer" \
  --under Legacy \
  --commit "chore(archived): archive csharp-developer under Legacy" \
  --push

# Same skill but stored under repo skills/Legacy (override bucket)
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" to-repo \
  --src "${ARCHIVED_SKILLS_GLOBAL}/csharp-developer" \
  --bucket skills \
  --under Legacy \
  --commit "chore(skills): move csharp-developer to Legacy" \
  --push

# Copy only (keep global copy)
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" to-repo \
  --src "${SKILLS_GLOBAL}/foo" \
  --commit "chore(skills): snapshot foo" \
  --push \
  --keep-source
```

### Repo → global (default: **keep** repo copy)

```bash
# Restore under global skills (path mirrors repo after skills/)
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" from-repo \
  --src "skills/Legacy/foo"

# Restore this skill from the .agents layout
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" from-repo \
  --src ".agents/skills/my-tools"

# After restoring, remove from repo and push (optional)
bash "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh" from-repo \
  --src "skills/Legacy/foo" \
  --delete-repo-copy \
  --commit "chore(skills): remove Legacy/foo after restoring to global" \
  --push
```

### Environment overrides

| Variable | Role |
|----------|------|
| `MY_TOOLS_ROOT` | Path to the `my-tools` git clone |
| `SKILLS_GLOBAL` | Global skills directory |
| `RULES_GLOBAL` | Global rules directory |
| `AGENTS_GLOBAL` | Global agents directory |
| `ARCHIVED_SKILLS_GLOBAL` | Global directory for the archived / secondary skills tree |

## Agent workflow

1. Parse **direction** (to repo vs from repo), **paths**, optional **subfolder**, and **bucket** if the user named `skills` vs `archived`.
2. Build one `bash … asset-sync.sh` command; use a clear `chore(…): …` commit message.
3. **Run** the script (non-interactive); do not ask to confirm each git step unless the user asked for a dry run.
4. If the skill folder is missing from global (e.g. first install), run from `$MY_TOOLS_ROOT/.agents/skills/my-tools/scripts/asset-sync.sh`.
5. If `chmod +x` was lost: `chmod +x "$SKILLS_GLOBAL/my-tools/scripts/asset-sync.sh"`.

## Requirements

`bash`, `rsync`, `python3` (for `realpath` fallback), `git`. Remote `git push` must succeed (credentials/SSH already work).

## See also

- [references/update-my-skills.md](references/update-my-skills.md) — bulk sync between repo and global skills.
