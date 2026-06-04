#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/install-claude-shy-commands.sh --project <project-dir>
  bash scripts/install-claude-shy-commands.sh --user

Options:
  --project DIR  Install Claude Code /shy:* commands into a project
  --user         Install Claude Code /shy:* commands globally for the current user
  -h, --help     Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMAND_SRC="$REPO_DIR/extras/claude-commands/shy"
MODE=""
PROJECT_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      if [ $# -lt 2 ]; then
        echo "Error: --project requires a directory." >&2
        usage >&2
        exit 2
      fi
      MODE="project"
      PROJECT_DIR="$2"
      shift 2
      ;;
    --user|--global)
      MODE="user"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "Error: choose either --project <project-dir> or --user." >&2
  usage >&2
  exit 2
fi

if [ "$MODE" = "project" ] && [ -z "$PROJECT_DIR" ]; then
  echo "Error: --project requires a directory." >&2
  usage >&2
  exit 2
fi

if [ ! -d "$COMMAND_SRC" ]; then
  echo "Error: cannot find Claude command templates at $COMMAND_SRC" >&2
  exit 1
fi

if [ "$MODE" = "project" ]; then
  DEST="$(cd "$PROJECT_DIR" && pwd)/.claude/commands/shy"
else
  DEST="${HOME:?HOME is not set}/.claude/commands/shy"
fi

mkdir -p "$DEST"
cp "$COMMAND_SRC/"*.md "$DEST/"

echo "Installed Claude Code Shy commands: $DEST"
echo "Try in Claude Code: /shy:resolve"
