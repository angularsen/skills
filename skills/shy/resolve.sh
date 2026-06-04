#!/bin/bash
# shy resolve - Smart merge conflict assistant for shy people

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shy-lib.sh"

OUTPUT_DIR="$SCRIPT_DIR/output"

# Check state and act accordingly
if [ -f "$OUTPUT_DIR/conflict-plan.md" ]; then
    echo "✓ Conflict analysis found"
    echo ""
    echo "📋 Review: $OUTPUT_DIR/conflict-plan.md"
    echo ""
    echo "Ready to resolve conflicts!"
    echo ""
    echo "Tell the agent:"
    echo "  - 'Resolve Task N with strategy X' (auto-resolve)"
    echo "  - 'Task N manually resolved' (mark complete)"
    echo "  - 'Skip Task N' (defer)"
    echo ""
    echo "Or run:"
    echo "  bash $SCRIPT_DIR/analyze-conflict.sh  # Regenerate analysis"
    echo "  git checkout --conflict=merge <file>  # Reset a file to conflict state"
    exit 0
fi

# Check if in merge or rebase state
IN_MERGE=false
IN_REBASE=false
CONFLICT_TYPE=""
TARGET_BRANCH=""

if is_in_merge; then
    IN_MERGE=true
    CONFLICT_TYPE="merge"
    MERGE_COMMIT=$(get_merge_commit)
    TARGET_BRANCH=$(resolve_branch_name_for_commit "$MERGE_COMMIT" false)
    if [ -z "$TARGET_BRANCH" ]; then
        TARGET_BRANCH="MERGE_HEAD"
    fi
elif is_in_rebase; then
    IN_REBASE=true
    CONFLICT_TYPE="rebase"
    # For rebase, TARGET_BRANCH represents the onto commit (where we're rebasing to)
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
    echo "To initiate merge and analyze:"
    echo ""
    echo "  bash $SCRIPT_DIR/generate-conflict-analysis.sh <branch-name> --merge"
    echo ""
    echo "Or start manually:"
    echo ""
    echo "  git merge <branch-name> --no-commit --no-ff"
    echo "  git rebase <branch-name>"
    echo "  bash $SCRIPT_DIR/resolve.sh"
    exit 1
fi

# We're in conflict state, generate analysis
if [ "$IN_MERGE" = true ]; then
    echo "✓ Merge conflict detected"
else
    echo "✓ Rebase conflict detected"
fi
echo ""
echo "Generating conflict analysis..."
echo ""

# Run the analysis generator
bash "$SCRIPT_DIR/generate-conflict-analysis.sh" "$TARGET_BRANCH"

echo ""
echo "✓ Analysis complete!"
echo ""
echo "📋 Review: $OUTPUT_DIR/conflict-plan.md"
echo ""
echo "Tell the agent which tasks to resolve or handle manually in your IDE"
