#!/usr/bin/env bash
# Sync skills, rules, and agents between global dirs and the my-tools git repo.
# Usage:
#   asset-sync.sh to-repo --src PATH [--under REL] [--bucket auto|skills|dotagents-skills|archived|rules|agents] [--commit MSG] [--push] [--keep-source]
#   asset-sync.sh from-repo --src REPO_SUBPATH [--dest DIR] [--commit MSG] [--push] [--delete-repo-copy]
set -euo pipefail

MY_TOOLS_ROOT="${MY_TOOLS_ROOT:-$HOME/dev/slpt/my-tools}"
SKILLS_GLOBAL="${SKILLS_GLOBAL:-$HOME/.cursor/skills}"
RULES_GLOBAL="${RULES_GLOBAL:-$HOME/.cursor/rules}"
AGENTS_GLOBAL="${AGENTS_GLOBAL:-$HOME/.cursor/agents}"
ARCHIVED_SKILLS_GLOBAL="${ARCHIVED_SKILLS_GLOBAL:-$HOME/.codex/skills}"

realpath_portable() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p"
  else
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p"
  fi
}

detect_bucket_from_src() {
  local src_resolved="$1"
  local skills_r rules_r agents_r archived_r
  skills_r="$(realpath_portable "$SKILLS_GLOBAL")"
  rules_r="$(realpath_portable "$RULES_GLOBAL")"
  agents_r="$(realpath_portable "$AGENTS_GLOBAL")"
  archived_r="$(realpath_portable "$ARCHIVED_SKILLS_GLOBAL")"
  case "$src_resolved" in
    "$archived_r"/*) echo "archived" ;;
    "$skills_r"/*) echo "skills" ;;
    "$rules_r"/*) echo "rules" ;;
    "$agents_r"/*) echo "agents" ;;
    *)
      echo "error: could not infer --bucket from source path: $src_resolved" >&2
      echo "  expected under one of: $archived_r, $skills_r, $rules_r, $agents_r" >&2
      echo "  pass --bucket explicitly." >&2
      exit 1
      ;;
  esac
}

usage() {
  cat >&2 <<'EOF'
asset-sync.sh to-repo --src PATH [options]
  --under REL          Subfolder inside the bucket (e.g. Legacy)
  --bucket KIND        skills | dotagents-skills | archived | rules | agents | auto (default auto)
  --commit MSG         git commit -m MSG (repo root); skipped if nothing staged
  --push               git push from repo root
  --keep-source        Do not delete source after successful copy (default: delete = move)

asset-sync.sh from-repo --src REPO_SUBPATH [options]
  REPO_SUBPATH         e.g. skills/Legacy/foo, .agents/skills/foo, archived/Legacy/foo, rules/bar.mdc
  --dest DIR           Override destination parent (file targets need full file path for rules/agents)
  --commit MSG         git commit after deletion from repo (only with --delete-repo-copy)
  --push               git push  --delete-repo-copy   Remove from repo after copying to global (dangerous; off by default)

Global env overrides: MY_TOOLS_ROOT, SKILLS_GLOBAL, RULES_GLOBAL, AGENTS_GLOBAL,
 ARCHIVED_SKILLS_GLOBAL
EOF
  exit 1
}

require_rsync() {
  if ! command -v rsync >/dev/null 2>&1; then
    echo "error: rsync is required" >&2
    exit 1
  fi
}

require_git_repo() {
  if [[ ! -d "${MY_TOOLS_ROOT}/.git" ]]; then
    echo "error: not a git repository: $MY_TOOLS_ROOT" >&2
    exit 1
  fi
}

MODE=""
SRC=""
UNDER=""
BUCKET="auto"
COMMIT_MSG=""
DO_PUSH=0
KEEP_SOURCE=0
DEST_OVERRIDE=""
DELETE_REPO_COPY=0

if [[ $# -lt 1 ]]; then
  usage
fi
MODE="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --src)
      [[ $# -ge 2 ]] || { echo "error: --src needs a value" >&2; exit 1; }
      SRC="$2"
      shift 2
      ;;
    --under)
      [[ $# -ge 2 ]] || { echo "error: --under needs a value" >&2; exit 1; }
      UNDER="$2"
      shift 2
      ;;
    --bucket)
      [[ $# -ge 2 ]] || { echo "error: --bucket needs a value" >&2; exit 1; }
      BUCKET="$2"
      shift 2
      ;;
    --commit)
      [[ $# -ge 2 ]] || { echo "error: --commit needs a message" >&2; exit 1; }
      COMMIT_MSG="$2"
      shift 2
      ;;
    --push)
      DO_PUSH=1
      shift
      ;;
    --keep-source)
      KEEP_SOURCE=1
      shift
      ;;
    --dest)
      [[ $# -ge 2 ]] || { echo "error: --dest needs a value" >&2; exit 1; }
      DEST_OVERRIDE="$2"
      shift 2
      ;;
    --delete-repo-copy)
      DELETE_REPO_COPY=1
      shift
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage
      ;;
    *)
      echo "error: unexpected argument: $1" >&2
      usage
      ;;
  esac
done

to_repo() {
  [[ -n "$SRC" ]] || { echo "error: to-repo requires --src" >&2; exit 1; }
  require_rsync
  require_git_repo

  local src_resolved base_name dest_dir rel_git_path
  if [[ ! -e "$SRC" ]]; then
    echo "error: source does not exist: $SRC" >&2
    exit 1
  fi
  src_resolved="$(realpath_portable "$SRC")"
  if [[ "$BUCKET" == "auto" ]]; then
    BUCKET="$(detect_bucket_from_src "$src_resolved")"
  fi

  base_name="$(basename "$src_resolved")"
  if [[ "$BUCKET" == "dotagents-skills" ]]; then
    if [[ -n "$UNDER" ]]; then
      UNDER="${UNDER#/}"
      UNDER="${UNDER%/}"
      dest_dir="${MY_TOOLS_ROOT}/.agents/skills/${UNDER}/${base_name}"
      rel_git_path=".agents/skills/${UNDER}/${base_name}"
    else
      dest_dir="${MY_TOOLS_ROOT}/.agents/skills/${base_name}"
      rel_git_path=".agents/skills/${base_name}"
    fi
  elif [[ -n "$UNDER" ]]; then
    UNDER="${UNDER#/}"
    UNDER="${UNDER%/}"
    dest_dir="${MY_TOOLS_ROOT}/${BUCKET}/${UNDER}/${base_name}"
    rel_git_path="${BUCKET}/${UNDER}/${base_name}"
  else
    dest_dir="${MY_TOOLS_ROOT}/${BUCKET}/${base_name}"
    rel_git_path="${BUCKET}/${base_name}"
  fi

  if [[ "$BUCKET" == "skills" || "$BUCKET" == "dotagents-skills" || "$BUCKET" == "archived" ]]; then
    if [[ ! -d "$src_resolved" ]]; then
      echo "error: skill source must be a directory: $src_resolved" >&2
      exit 1
    fi
    if [[ ! -f "${src_resolved}/SKILL.md" ]]; then
      echo "error: skill directory must contain SKILL.md: $src_resolved" >&2
      exit 1
    fi
    mkdir -p "$dest_dir"
    rsync -a --delete "${src_resolved}/" "${dest_dir}/"
    echo "synced (dir): $src_resolved -> $dest_dir"
  elif [[ "$BUCKET" == "rules" || "$BUCKET" == "agents" ]]; then
    if [[ -d "$src_resolved" ]]; then
      mkdir -p "$dest_dir"
      rsync -a --delete "${src_resolved}/" "${dest_dir}/"
      echo "synced (dir): $src_resolved -> $dest_dir"
    else
      mkdir -p "$(dirname "$dest_dir")"
      rsync -a "$src_resolved" "$dest_dir"
      echo "synced (file): $src_resolved -> $dest_dir"
    fi
  else
    echo "error: invalid bucket: $BUCKET" >&2
    exit 1
  fi

  git -C "$MY_TOOLS_ROOT" add -- "$rel_git_path"
  if [[ -n "$COMMIT_MSG" ]]; then
    if git -C "$MY_TOOLS_ROOT" diff --cached --quiet; then
      echo "nothing to commit for $rel_git_path"
    else
      git -C "$MY_TOOLS_ROOT" commit -m "$COMMIT_MSG"
    fi
  fi
  if [[ "$DO_PUSH" -eq 1 ]]; then
    git -C "$MY_TOOLS_ROOT" push
  fi

  if [[ "$KEEP_SOURCE" -eq 0 ]]; then
    rm -rf "$src_resolved"
    echo "removed source (move): $src_resolved"
  fi
}

from_repo() {
  [[ -n "$SRC" ]] || { echo "error: from-repo requires --src (repo-relative path)" >&2; exit 1; }
  require_rsync
  local repo_path="${MY_TOOLS_ROOT}/${SRC#/}"
  if [[ ! -e "$repo_path" ]]; then
    echo "error: repo path does not exist: $repo_path" >&2
    exit 1
  fi

  local dest=""
  if [[ -n "$DEST_OVERRIDE" ]]; then
    dest="$DEST_OVERRIDE"
  else
    case "$SRC" in
      .agents/skills/*)
        dest="${SKILLS_GLOBAL}/${SRC#.agents/skills/}"
        ;;
      skills/*|archived/*)
        local sub="${SRC#*/}"
        sub="${sub#*/}"
        if [[ "$SRC" == skills/* ]]; then
          dest="${SKILLS_GLOBAL}/${sub}"
        else
          dest="${ARCHIVED_SKILLS_GLOBAL}/${sub}"
        fi
        ;;
      rules/*)
        dest="${RULES_GLOBAL}/${SRC#rules/}"
        ;;
      agents/*)
        dest="${AGENTS_GLOBAL}/${SRC#agents/}"
        ;;
      *)
        echo "error: cannot infer --dest from REPO_SUBPATH; use --dest" >&2
        exit 1
        ;;
    esac
  fi

  if [[ -d "$repo_path" ]]; then
    mkdir -p "$dest"
    rsync -a --delete "${repo_path}/" "${dest}/"
    echo "synced to global (dir): $repo_path -> $dest"
  else
    mkdir -p "$(dirname "$dest")"
    rsync -a "$repo_path" "$dest"
    echo "synced to global (file): $repo_path -> $dest"
  fi

  if [[ "$DELETE_REPO_COPY" -eq 1 ]]; then
    require_git_repo
    local bucket_prefix="${SRC%%/*}"
    rm -rf "$repo_path"
    git -C "$MY_TOOLS_ROOT" add -A -- "$bucket_prefix"
    if [[ -n "$COMMIT_MSG" ]]; then
      if git -C "$MY_TOOLS_ROOT" diff --cached --quiet; then
        echo "nothing to commit after delete"
      else
        git -C "$MY_TOOLS_ROOT" commit -m "$COMMIT_MSG"
      fi
    fi
    if [[ "$DO_PUSH" -eq 1 ]]; then
      git -C "$MY_TOOLS_ROOT" push
    fi
  fi
}

case "$MODE" in
  to-repo) to_repo ;;
  from-repo) from_repo ;;
  *) usage ;;
esac
