#!/bin/bash
# shy analyze-conflict - Regenerate conflict analysis

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shy-lib.sh"

# Check if in merge or rebase state
IN_MERGE=false
IN_REBASE=false
TARGET_BRANCH=""

if is_in_merge; then
    IN_MERGE=true
    MERGE_COMMIT=$(get_merge_commit)
    TARGET_BRANCH=$(resolve_branch_name_for_commit "$MERGE_COMMIT" false)
    if [ -z "$TARGET_BRANCH" ]; then
        TARGET_BRANCH="MERGE_HEAD"
    fi
elif is_in_rebase; then
    IN_REBASE=true
    ONTO_COMMIT=$(get_rebase_onto_commit)
    ONTO_SHORT=$(git rev-parse --short "$ONTO_COMMIT")
    # Prefer master/main when resolving branch name
    TARGET_BRANCH=$(resolve_branch_name_for_commit "$ONTO_COMMIT" true)
    if [ -z "$TARGET_BRANCH" ]; then
        TARGET_BRANCH="$ONTO_SHORT"
    fi
fi

if [ "$IN_MERGE" = false ] && [ "$IN_REBASE" = false ]; then
    echo "❌ Not in a merge or rebase conflict state"
    echo ""
    echo "To initiate first:"
    echo "  git merge <branch-name> --no-commit --no-ff"
    echo "  git rebase <branch-name>"
    exit 1
fi

if [ "$IN_MERGE" = true ]; then
    echo "Regenerating conflict analysis for merge..."
else
    echo "Regenerating conflict analysis for rebase..."
fi
echo ""

# Remove old analysis
OUTPUT_DIR="$SCRIPT_DIR/output"

if [ -d "$OUTPUT_DIR" ]; then
    echo "Removing old analysis..."
    rm -rf "$OUTPUT_DIR"
fi

# Generate fresh analysis
bash "$SCRIPT_DIR/generate-conflict-analysis.sh" "$TARGET_BRANCH"

echo ""
echo "✓ Fresh analysis complete!"
echo ""
echo "📋 Review: $OUTPUT_DIR/conflict-plan.md"
