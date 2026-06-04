#!/bin/bash
# Validates that resolution patches contain all expected changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR/output}"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory not found: $OUTPUT_DIR"
    exit 1
fi

echo "🔍 Validating conflict resolution..."
echo ""

MISSING_COUNT=0
WARNINGS=()

# Read conflicts
if [ ! -f "$OUTPUT_DIR/conflicts.txt" ]; then
    echo "Error: conflicts.txt not found"
    exit 1
fi

CONFLICTS=$(cat "$OUTPUT_DIR/conflicts.txt")

# For each conflicted file, check if resolution exists
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue

    echo "Checking: $FILE"

    # Check if file is still conflicted
    if grep -q "<<<<<<< HEAD" "$FILE" 2>/dev/null; then
        echo "  ❌ Still has conflict markers"
        ((MISSING_COUNT++))
        continue
    fi

    # Check if file was staged
    if ! git diff --cached --name-only | grep -q "^$FILE$"; then
        echo "  ⚠️  Not staged (may need: git add $FILE)"
    else
        echo "  ✅ Resolved and staged"
    fi
done

# Validate using verification checklist if it exists
if [ -f "$OUTPUT_DIR/verification-checklist.md" ]; then
    echo ""
    echo "📋 Verification checklist available at:"
    echo "   $OUTPUT_DIR/verification-checklist.md"
    echo ""
    echo "Please review checklist to ensure no changes were lost."
fi

echo ""
if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "✅ All conflicts appear to be resolved"
    echo ""
    echo "Next steps:"
    echo "  1. Review verification checklist"
    echo "  2. Run: dotnet build (or appropriate build command)"
    echo "  3. Continue merge/rebase: git rebase --continue (or git commit)"
    exit 0
else
    echo "❌ $MISSING_COUNT files still have conflicts"
    echo ""
    echo "Please resolve remaining conflicts before continuing."
    exit 1
fi
