#!/bin/bash
# generate-conflict-analysis.sh
# Generates comprehensive merge conflict analysis for any git merge

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shy-lib.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
INCOMING_BRANCH=""
OUTPUT_DIR="$SCRIPT_DIR/output"
AUTO_MERGE=false

usage() {
    echo "Usage: $0 <incoming-branch> [options]"
    echo ""
    echo "Options:"
    echo "  -o, --output DIR     Output directory (default: <skill-dir>/output)"
    echo "  -m, --merge          Automatically initiate merge (default: false)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 feature/my-branch"
    echo "  $0 feature/my-branch --output custom-dir --merge"
    exit 1
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    usage
fi

INCOMING_BRANCH="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -m|--merge)
            AUTO_MERGE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Verify we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if we're in a merge or rebase state BEFORE gathering all the details
IN_MERGE=false
IN_REBASE=false
SOURCE_BRANCH=""

if is_in_merge; then
    IN_MERGE=true
elif is_in_rebase; then
    IN_REBASE=true
    # For rebase, extract the source branch name
    SOURCE_BRANCH=$(get_rebase_source_branch)
fi

# Verify incoming branch exists (or resolve it from onto commit for rebase)
if [ "$IN_REBASE" = true ]; then
    # For rebase, INCOMING_BRANCH might be the onto commit
    # Try to resolve it to a better branch name
    if ! git rev-parse --verify "$INCOMING_BRANCH" > /dev/null 2>&1; then
        echo -e "${RED}Error: Branch/commit '$INCOMING_BRANCH' does not exist${NC}"
        exit 1
    fi
    # Check if it's a commit SHA and try to find master/main branch name
    if git rev-parse --short "$INCOMING_BRANCH" >/dev/null 2>&1; then
        MASTER_BRANCH=$(resolve_branch_name_for_commit "$INCOMING_BRANCH" true)
        if [ -n "$MASTER_BRANCH" ]; then
            INCOMING_BRANCH="$MASTER_BRANCH"
        fi
    fi
else
    # For merge, verify the branch exists
    if ! git rev-parse --verify "$INCOMING_BRANCH" > /dev/null 2>&1; then
        echo -e "${RED}Error: Branch '$INCOMING_BRANCH' does not exist${NC}"
        exit 1
    fi
fi

# Get commit SHAs and rebase-specific information
if [ "$IN_REBASE" = true ]; then
    # For rebase, capture the original HEAD and the conflicting commit
    ORIGINAL_HEAD=$(get_rebase_original_head)
    ORIGINAL_HEAD_SHORT=$(git rev-parse --short "$ORIGINAL_HEAD")
    ORIGINAL_HEAD_MSG=$(git log --oneline -1 "$ORIGINAL_HEAD" | cut -d' ' -f2-)
    ORIGINAL_HEAD_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$ORIGINAL_HEAD")

    CONFLICT_COMMIT=$(get_rebase_stopped_commit)
    CONFLICT_COMMIT_SHORT=$(git rev-parse --short "$CONFLICT_COMMIT")
    CONFLICT_COMMIT_MSG=$(git log --oneline -1 "$CONFLICT_COMMIT" | cut -d' ' -f2-)
    CONFLICT_COMMIT_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$CONFLICT_COMMIT")

    # Read the actual onto commit (the target we're rebasing onto)
    ONTO_COMMIT=$(get_rebase_onto_commit)
    ONTO_COMMIT_SHORT=$(git rev-parse --short "$ONTO_COMMIT")
    ONTO_COMMIT_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$ONTO_COMMIT")

    # Current detached HEAD (last successful commit, less important)
    CURRENT_DETACHED_HEAD=$(git rev-parse --short HEAD)
    # For rebase, use original head as HEAD_REV and onto commit as INCOMING_REV
    MERGE_BASE=$(git merge-base "$ORIGINAL_HEAD" "$ONTO_COMMIT")
    MERGE_BASE_SHORT=$(git rev-parse --short "$MERGE_BASE")
    MERGE_BASE_MSG=$(git log --oneline -1 "$MERGE_BASE" | cut -d' ' -f2-)
    MERGE_BASE_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$MERGE_BASE")
    HEAD_REV="$ORIGINAL_HEAD_SHORT"
    HEAD_DATE="$ORIGINAL_HEAD_DATE"
    INCOMING_REV="$ONTO_COMMIT_SHORT"
    INCOMING_DATE="$ONTO_COMMIT_DATE"
    # For diffs: HEAD side = onto target (origin/master), incoming side = your original branch
    DIFF_HEAD_COMMIT="HEAD"
    DIFF_INCOMING_COMMIT="$ORIGINAL_HEAD"
else
    # For merge, use current HEAD
    MERGE_BASE=$(git merge-base HEAD "$INCOMING_BRANCH")
    MERGE_BASE_SHORT=$(git rev-parse --short "$MERGE_BASE")
    MERGE_BASE_MSG=$(git log --oneline -1 "$MERGE_BASE" | cut -d' ' -f2-)
    MERGE_BASE_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$MERGE_BASE")
    HEAD_REV=$(git rev-parse --short HEAD)
    HEAD_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' HEAD)
    INCOMING_REV=$(git rev-parse --short "$INCOMING_BRANCH")
    INCOMING_DATE=$(git log -1 --format='%ad' --date=format:'%Y-%m-%d' "$INCOMING_BRANCH")
    # For diffs: use the branch names directly
    DIFF_HEAD_COMMIT="HEAD"
    DIFF_INCOMING_COMMIT="$INCOMING_BRANCH"
fi

if [ "$IN_REBASE" = true ]; then
    echo -e "${BLUE}=== Rebase Conflict Analysis Generator ===${NC}"
    if [ -n "$SOURCE_BRANCH" ]; then
        echo -e "Rebasing:        ${GREEN}$SOURCE_BRANCH${NC}"
    fi
    if [ -n "$ORIGINAL_HEAD_MSG" ]; then
        echo -e "Original HEAD:   ${GREEN}$ORIGINAL_HEAD_SHORT${NC} \"$ORIGINAL_HEAD_MSG\""
    fi
    if [ -n "$CONFLICT_COMMIT_MSG" ]; then
        echo -e "Applying commit: ${GREEN}$CONFLICT_COMMIT_SHORT${NC} \"$CONFLICT_COMMIT_MSG\""
    fi
    echo -e "Onto target:     ${GREEN}$INCOMING_BRANCH${NC} ($INCOMING_REV)"
    echo -e "Merge base:      ${GREEN}$MERGE_BASE_SHORT${NC}"
    if [ -n "$CURRENT_DETACHED_HEAD" ]; then
        echo -e "Detached HEAD:   ${GREEN}$CURRENT_DETACHED_HEAD${NC} (last successful)"
    fi
    echo -e "Output dir:      ${GREEN}$OUTPUT_DIR${NC}"
else
    echo -e "${BLUE}=== Merge Conflict Analysis Generator ===${NC}"
    echo -e "Current branch:  ${GREEN}$CURRENT_BRANCH${NC} ($HEAD_REV)"
    echo -e "Incoming branch: ${GREEN}$INCOMING_BRANCH${NC} ($INCOMING_REV)"
    echo -e "Merge base:      ${GREEN}$MERGE_BASE_SHORT${NC}"
    echo -e "Output dir:      ${GREEN}$OUTPUT_DIR${NC}"
fi
echo ""

# Initiate merge if requested
if [ "$AUTO_MERGE" = true ]; then
    echo -e "${YELLOW}Initiating merge...${NC}"
    if ! git merge "$INCOMING_BRANCH" --no-commit --no-ff 2>&1; then
        echo -e "${YELLOW}Merge has conflicts (expected)${NC}"
    fi
    echo ""
fi

# Verify we're in a conflict state (check again after AUTO_MERGE attempt)
if [ "$IN_MERGE" = false ] && [ "$IN_REBASE" = false ]; then
    # Re-check in case AUTO_MERGE was true and just ran
    if [ -f .git/MERGE_HEAD ]; then
        IN_MERGE=true
    elif [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
        IN_REBASE=true
    fi
fi

if [ "$IN_MERGE" = false ] && [ "$IN_REBASE" = false ]; then
    echo -e "${RED}Error: Not currently in a merge or rebase state${NC}"
    echo "Run: git merge $INCOMING_BRANCH --no-commit --no-ff"
    echo "Or:  git rebase $INCOMING_BRANCH"
    exit 1
fi

# Get list of conflicted files
CONFLICTS=$(git diff --name-only --diff-filter=U)
CONFLICT_COUNT=$(echo "$CONFLICTS" | grep -c . || echo 0)

if [ "$CONFLICT_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No conflicts found!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found $CONFLICT_COUNT conflicted files${NC}"
echo ""

# Create output directory structure
mkdir -p "$OUTPUT_DIR/diffs/head"
mkdir -p "$OUTPUT_DIR/diffs/incoming"
if [ "$IN_REBASE" = true ]; then
    mkdir -p "$OUTPUT_DIR/diffs/commit"
fi

# Save conflicts list
echo "$CONFLICTS" > "$OUTPUT_DIR/conflicts.txt"

echo -e "${BLUE}Generating diff files...${NC}"

# Generate diff files for each conflict
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue
    DIR=$(dirname "$FILE")
    mkdir -p "$OUTPUT_DIR/diffs/head/$DIR"
    mkdir -p "$OUTPUT_DIR/diffs/incoming/$DIR"

    git diff "$MERGE_BASE..$DIFF_HEAD_COMMIT" -- "$FILE" > "$OUTPUT_DIR/diffs/head/$FILE.diff" 2>&1 || true
    git diff "$MERGE_BASE..$DIFF_INCOMING_COMMIT" -- "$FILE" > "$OUTPUT_DIR/diffs/incoming/$FILE.diff" 2>&1 || true

    # For rebase: generate commit-specific diff showing ONLY what the conflicting commit changes
    if [ "$IN_REBASE" = true ] && [ -n "$CONFLICT_COMMIT" ]; then
        DIR=$(dirname "$FILE")
        mkdir -p "$OUTPUT_DIR/diffs/commit/$DIR"
        git show "$CONFLICT_COMMIT" -- "$FILE" > "$OUTPUT_DIR/diffs/commit/$FILE.diff" 2>&1 || true
    fi

    echo "  ✓ $FILE"
done

echo ""
echo -e "${BLUE}Generating analysis files...${NC}"

# Write metadata to file for generate-analysis.sh to read
OPERATION_TYPE="merge"
if [ "$IN_REBASE" = true ]; then
    OPERATION_TYPE="rebase"
fi

# Escape single quotes in strings by replacing ' with '\''
escape_single_quotes() {
    echo "$1" | sed "s/'/'\\\''/g"
}

cat > "$OUTPUT_DIR/.generate-analysis.vars" << EOF
OUTPUT_DIR='$(escape_single_quotes "$OUTPUT_DIR")'
CURRENT_BRANCH='$(escape_single_quotes "$CURRENT_BRANCH")'
INCOMING_BRANCH='$(escape_single_quotes "$INCOMING_BRANCH")'
HEAD_REV='$(escape_single_quotes "$HEAD_REV")'
INCOMING_REV='$(escape_single_quotes "$INCOMING_REV")'
MERGE_BASE_SHORT='$(escape_single_quotes "$MERGE_BASE_SHORT")'
CONFLICT_COUNT='$(escape_single_quotes "$CONFLICT_COUNT")'
OPERATION_TYPE='$(escape_single_quotes "$OPERATION_TYPE")'
SOURCE_BRANCH='$(escape_single_quotes "$SOURCE_BRANCH")'
ORIGINAL_HEAD_SHORT='$(escape_single_quotes "$ORIGINAL_HEAD_SHORT")'
ORIGINAL_HEAD_MSG='$(escape_single_quotes "$ORIGINAL_HEAD_MSG")'
CONFLICT_COMMIT_SHORT='$(escape_single_quotes "$CONFLICT_COMMIT_SHORT")'
CONFLICT_COMMIT_MSG='$(escape_single_quotes "$CONFLICT_COMMIT_MSG")'
DIFF_HEAD_COMMIT='$(escape_single_quotes "$DIFF_HEAD_COMMIT")'
DIFF_INCOMING_COMMIT='$(escape_single_quotes "$DIFF_INCOMING_COMMIT")'
HEAD_DATE='$(escape_single_quotes "$HEAD_DATE")'
INCOMING_DATE='$(escape_single_quotes "$INCOMING_DATE")'
MERGE_BASE_MSG='$(escape_single_quotes "$MERGE_BASE_MSG")'
MERGE_BASE_DATE='$(escape_single_quotes "$MERGE_BASE_DATE")'
ORIGINAL_HEAD_DATE='$(escape_single_quotes "$ORIGINAL_HEAD_DATE")'
CONFLICT_COMMIT_DATE='$(escape_single_quotes "$CONFLICT_COMMIT_DATE")'
ONTO_COMMIT_DATE='$(escape_single_quotes "$ONTO_COMMIT_DATE")'
EOF

# Use a separate script to generate the analysis files with proper escaping
bash -c "cat > '$OUTPUT_DIR/generate-analysis.sh'" << 'ANALYSIS_SCRIPT'
#!/bin/bash
# Source variables file (in same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.generate-analysis.vars"

# Read conflicts
CONFLICTS=$(cat "$OUTPUT_DIR/conflicts.txt")

# Function to analyze diff patterns and generate specific recommendations
analyze_conflict_pattern() {
    local FILE="$1"
    local HEAD_DIFF="$OUTPUT_DIR/diffs/head/$FILE.diff"
    local INCOMING_DIFF="$OUTPUT_DIR/diffs/incoming/$FILE.diff"
    local ANALYSIS_OUTPUT=""

    # Check if file was deleted in HEAD
    local HEAD_DELETED=false
    if grep -q "^deleted file mode" "$HEAD_DIFF" 2>/dev/null; then
        HEAD_DELETED=true
    fi

    # Check if file was deleted in incoming
    local INCOMING_DELETED=false
    if grep -q "^deleted file mode" "$INCOMING_DIFF" 2>/dev/null; then
        INCOMING_DELETED=true
    fi

    # Extract class/interface names from the file
    local CLASSNAME=$(basename "$FILE" .cs | sed 's/\.razor//')

    # Check for specific patterns in the diffs
    # Check for method additions (broader pattern to catch all method signatures)
    local HEAD_METHODS=$(grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF" 2>/dev/null | wc -l || echo 0)
    local INCOMING_METHODS=$(grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$INCOMING_DIFF" 2>/dev/null | wc -l || echo 0)

    # Check for using statement changes
    local HEAD_REMOVES_USING=$(grep "^-using " "$HEAD_DIFF" 2>/dev/null | wc -l || echo 0)
    local INCOMING_ADDS_USING=$(grep "^+using " "$INCOMING_DIFF" 2>/dev/null | wc -l || echo 0)

    # Generate specific analysis based on patterns
    ANALYSIS_OUTPUT+="\n### Recommended Resolution\n\n"

    # Pattern: File deleted on HEAD but modified on incoming (modify/delete conflict)
    if [ "$HEAD_DELETED" = true ] && [ "$INCOMING_DELETED" = false ]; then
        ANALYSIS_OUTPUT+="**Conflict Type:** Modify/Delete - File was deleted on HEAD but modified on incoming branch.\n\n"
        ANALYSIS_OUTPUT+="**Recommended Action:**\n"
        ANALYSIS_OUTPUT+="1. **Check if file was moved/refactored:** Search for \`$CLASSNAME\` in the codebase to see if this class/functionality was moved to a different location\n"
        ANALYSIS_OUTPUT+="2. **Compare functionality:** If the file was moved, check if the incoming changes are already present in the new location\n"
        ANALYSIS_OUTPUT+="3. **Resolution:**\n"
        ANALYSIS_OUTPUT+="   - If moved and changes already present: Accept deletion (\`git rm $FILE\`)\n"
        ANALYSIS_OUTPUT+="   - If moved but changes missing: Apply incoming changes to the new location\n"
        ANALYSIS_OUTPUT+="   - If not moved and needed: Keep the file with incoming modifications\n\n"
    elif [ "$INCOMING_DELETED" = true ] && [ "$HEAD_DELETED" = false ]; then
        ANALYSIS_OUTPUT+="**Conflict Type:** Modify/Delete - File was deleted on incoming branch but modified on HEAD.\n\n"
        ANALYSIS_OUTPUT+="**Recommended Action:** Check if incoming branch moved this file elsewhere. If so, apply HEAD changes to the new location.\n\n"
    fi

    # Pattern: Both branches add methods - DO ACTUAL ANALYSIS
    if [ "$HEAD_METHODS" -gt 0 ] && [ "$INCOMING_METHODS" -gt 0 ]; then
        ANALYSIS_OUTPUT+="**Analysis: Method Additions Detected**\n\n"

        # Extract actual method names from HEAD
        ANALYSIS_OUTPUT+="HEAD adds:\n"
        HEAD_METHOD_LIST=$(grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF" 2>/dev/null | head -5 | while read -r LINE; do
            METHOD=$(echo "$LINE" | sed -n 's/^+.*\s\+\(\w\+\)\s*(.*$/\1/p')
            [ -n "$METHOD" ] && echo "- \`$METHOD()\`"
        done)
        [ -n "$HEAD_METHOD_LIST" ] && ANALYSIS_OUTPUT+="$HEAD_METHOD_LIST\n"
        ANALYSIS_OUTPUT+="\n"

        # Extract actual method names from incoming
        ANALYSIS_OUTPUT+="Incoming adds:\n"
        INCOMING_METHOD_LIST=$(grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$INCOMING_DIFF" 2>/dev/null | head -5 | while read -r LINE; do
            METHOD=$(echo "$LINE" | sed -n 's/^+.*\s\+\(\w\+\)\s*(.*$/\1/p')
            [ -n "$METHOD" ] && echo "- \`$METHOD()\`"
        done)
        [ -n "$INCOMING_METHOD_LIST" ] && ANALYSIS_OUTPUT+="$INCOMING_METHOD_LIST\n"
        ANALYSIS_OUTPUT+="\n"

        ANALYSIS_OUTPUT+="**Resolution:** Merge both - these appear to be independent features.\n\n"
    fi

    # Pattern: Code moved to another file (method refactoring)
    # Check if HEAD removes methods that incoming modifies (broader pattern)
    local HEAD_REMOVES_METHODS=$(grep "^-\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF" 2>/dev/null | grep -v "^---" | wc -l || echo 0)
    if [ "$HEAD_REMOVES_METHODS" -gt 0 ] && [ "$INCOMING_METHODS" -gt 0 ]; then
        ANALYSIS_OUTPUT+="**Analysis: Code Movement (Refactoring)**\n\n"

        ANALYSIS_OUTPUT+="HEAD removed methods (likely refactored):\n"
        REMOVED_METHOD_LIST=$(grep "^-\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF" 2>/dev/null | grep -v "^---" | head -3 | while read -r LINE; do
            METHOD=$(echo "$LINE" | sed -n 's/^-.*\s\+\(\w\+\)\s*(.*$/\1/p')
            [ -n "$METHOD" ] && echo "- \`$METHOD()\`"
        done)
        [ -n "$REMOVED_METHOD_LIST" ] && ANALYSIS_OUTPUT+="$REMOVED_METHOD_LIST\n"
        ANALYSIS_OUTPUT+="\n"

        # Actually search for moved methods
        ANALYSIS_OUTPUT+="**🔍 Searched for moved methods:**\n\n"
        local REMOVED_METHODS=$(grep "^-\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF" 2>/dev/null | grep -v "^---" | sed -n 's/^-.*\s\+\(\w\+\)\s*(.*$/\1/p' | head -5)

        if [ -n "$REMOVED_METHODS" ]; then
            local FOUND_ANY=false
            while IFS= read -r METHOD_NAME; do
                [ -z "$METHOD_NAME" ] && continue

                # Search in all .cs and .razor files
                local NEW_LOCATION=$(grep -r "^\s*\(public\|private\|protected\|internal\).*\s$METHOD_NAME\s*(" \
                    --include="*.cs" --include="*.razor" \
                    . 2>/dev/null | head -1 | cut -d: -f1 2>/dev/null)

                if [ -n "$NEW_LOCATION" ]; then
                    ANALYSIS_OUTPUT+="- ✅ **\`$METHOD_NAME()\`** → Found in **\`$NEW_LOCATION\`**\n"
                    ANALYSIS_OUTPUT+="  ⚠️ **Action Required**: Apply incoming's changes to this file\n\n"
                    FOUND_ANY=true
                fi
            done <<< "$REMOVED_METHODS"

            if [ "$FOUND_ANY" = false ]; then
                ANALYSIS_OUTPUT+="- ⚠️ No moved methods found (search may need manual verification)\n\n"
            fi
        fi

        ANALYSIS_OUTPUT+="**Example:** If incoming modified a method that HEAD moved to another file, apply those modifications to the new location instead.\n\n"
    fi

    # Pattern: Using statement changes
    if [ "$HEAD_REMOVES_USING" -gt 0 ] || [ "$INCOMING_ADDS_USING" -gt 0 ]; then
        ANALYSIS_OUTPUT+="**Using Statements Changed:** One or both branches modified using statements.\n\n"
        ANALYSIS_OUTPUT+="**Recommended Action:**\n"
        ANALYSIS_OUTPUT+="1. **Favor additive combination:** Keep using statements from both branches\n"
        ANALYSIS_OUTPUT+="2. **Remove duplicates:** If same namespace appears twice, keep only one\n"
        ANALYSIS_OUTPUT+="3. Extra using statements don't cause problems and are easy to clean up manually later if needed\n\n"
    fi

    # If no specific patterns detected, refer to general workflow
    if [ "$HEAD_DELETED" = false ] && [ "$INCOMING_DELETED" = false ] && \
       [ "$HEAD_METHODS" -eq 0 ] && [ "$INCOMING_METHODS" -eq 0 ] && \
       [ "$HEAD_REMOVES_USING" -eq 0 ] && [ "$INCOMING_ADDS_USING" -eq 0 ]; then
        ANALYSIS_OUTPUT+="**General Conflict:** Changes on both branches affect overlapping areas.\n\n"
        ANALYSIS_OUTPUT+="**Recommended Action:** Follow the general resolution workflow in the **Resolution Workflow** section of [conflict-plan.md](conflict-plan.md#resolution-workflow).\n\n"
    fi

    echo -e "$ANALYSIS_OUTPUT"
}


# Generate conflict-analysis.md header
if [ "$OPERATION_TYPE" = "rebase" ]; then
cat > "$OUTPUT_DIR/conflict-analysis.md" << EOF
# Rebase Conflict Analysis Report

## Summary

- **Rebasing:** \`${SOURCE_BRANCH:-$CURRENT_BRANCH}\` onto \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE)
- **Original HEAD:** \`$ORIGINAL_HEAD_SHORT\` "$ORIGINAL_HEAD_MSG" ($ORIGINAL_HEAD_DATE)
- **Applying commit:** \`$CONFLICT_COMMIT_SHORT\` "$CONFLICT_COMMIT_MSG" ($CONFLICT_COMMIT_DATE)
- **Merge Base:** \`$MERGE_BASE_SHORT\` "$MERGE_BASE_MSG" ($MERGE_BASE_DATE)
- **Date:** $(date '+%Y-%m-%d %H:%M:%S')
- **Total Conflicts:** $CONFLICT_COUNT

---

## Table of Contents

EOF
else
cat > "$OUTPUT_DIR/conflict-analysis.md" << EOF
# Merge Conflict Analysis Report

## Summary

- **Merge:** \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE) into \`$CURRENT_BRANCH\` (\`$HEAD_REV\`, $HEAD_DATE)
- **Merge Base:** \`$MERGE_BASE_SHORT\` "$MERGE_BASE_MSG" ($MERGE_BASE_DATE)
- **Date:** $(date '+%Y-%m-%d %H:%M:%S')
- **Total Conflicts:** $CONFLICT_COUNT

---

## Table of Contents

EOF
fi

# Generate TOC
COUNTER=1
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue
    ANCHOR=$(echo "$FILE" | sed 's|/|-|g' | sed 's|\.|-|g')
    echo "$COUNTER. [\`$FILE\`](#$ANCHOR)"
    COUNTER=$((COUNTER + 1))
done >> "$OUTPUT_DIR/conflict-analysis.md"

cat >> "$OUTPUT_DIR/conflict-analysis.md" << 'EOF'

---

EOF

# Generate analysis for each file
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue
    ANCHOR=$(echo "$FILE" | sed 's|/|-|g' | sed 's|\.|-|g')

    # Build file links section
    FILE_LINKS="- 📄 [Current file]($FILE)\n- 📊 [HEAD diff]($OUTPUT_DIR/diffs/head/$FILE.diff)\n- 📊 [Incoming diff]($OUTPUT_DIR/diffs/incoming/$FILE.diff)"
    if [ "$OPERATION_TYPE" = "rebase" ] && [ -s "$OUTPUT_DIR/diffs/commit/$FILE.diff" ]; then
        FILE_LINKS="$FILE_LINKS\n- 📊 [Commit diff]($OUTPUT_DIR/diffs/commit/$FILE.diff) ← **What this commit actually changes**"
    fi

    cat >> "$OUTPUT_DIR/conflict-analysis.md" << EOF

## $FILE

### Files

$(echo -e "$FILE_LINKS")

### HEAD Changes

EOF

    # Analyze HEAD changes
    if [ -s "$OUTPUT_DIR/diffs/head/$FILE.diff" ]; then
        ADDS=$(grep -c "^+[^+]" "$OUTPUT_DIR/diffs/head/$FILE.diff" 2>/dev/null || echo 0)
        DELS=$(grep -c "^-[^-]" "$OUTPUT_DIR/diffs/head/$FILE.diff" 2>/dev/null || echo 0)
        echo "- **Changes:** +$ADDS / -$DELS lines" >> "$OUTPUT_DIR/conflict-analysis.md"

        # Get commit history for this file on HEAD branch (limit to 3 most recent)
        echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
        echo "**Recent commits (HEAD):**" >> "$OUTPUT_DIR/conflict-analysis.md"
        echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
        git log --oneline "$MERGE_BASE_SHORT..$DIFF_HEAD_COMMIT" -- "$FILE" | head -3 | while read -r COMMIT_LINE; do
            echo "- \`$COMMIT_LINE\`" >> "$OUTPUT_DIR/conflict-analysis.md"
        done

        # If no commits found, note it
        if ! git log --oneline "$MERGE_BASE_SHORT..$DIFF_HEAD_COMMIT" -- "$FILE" | grep -q .; then
            echo "- *(No commits found - file may have been modified without commits)*" >> "$OUTPUT_DIR/conflict-analysis.md"
        fi
    else
        echo "- No changes" >> "$OUTPUT_DIR/conflict-analysis.md"
    fi

    cat >> "$OUTPUT_DIR/conflict-analysis.md" << 'EOF'

### Incoming Changes

EOF

    # Analyze incoming changes
    if [ -s "$OUTPUT_DIR/diffs/incoming/$FILE.diff" ]; then
        ADDS=$(grep -c "^+[^+]" "$OUTPUT_DIR/diffs/incoming/$FILE.diff" 2>/dev/null || echo 0)
        DELS=$(grep -c "^-[^-]" "$OUTPUT_DIR/diffs/incoming/$FILE.diff" 2>/dev/null || echo 0)
        echo "- **Changes:** +$ADDS / -$DELS lines" >> "$OUTPUT_DIR/conflict-analysis.md"

        # Get commit history for this file on incoming branch (limit to 3 most recent)
        echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
        echo "**Recent commits (incoming):**" >> "$OUTPUT_DIR/conflict-analysis.md"
        echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
        git log --oneline "$MERGE_BASE_SHORT..$DIFF_INCOMING_COMMIT" -- "$FILE" | head -3 | while read -r COMMIT_LINE; do
            echo "- \`$COMMIT_LINE\`" >> "$OUTPUT_DIR/conflict-analysis.md"
        done

        # If no commits found, note it
        if ! git log --oneline "$MERGE_BASE_SHORT..$DIFF_INCOMING_COMMIT" -- "$FILE" | grep -q .; then
            echo "- *(No commits found - file may have been modified without commits)*" >> "$OUTPUT_DIR/conflict-analysis.md"
        fi
    else
        echo "- No changes" >> "$OUTPUT_DIR/conflict-analysis.md"
    fi

    # For rebase: add commit-specific analysis and scope mismatch detection
    if [ "$OPERATION_TYPE" = "rebase" ]; then
        COMMIT_DIFF_FILE="$OUTPUT_DIR/diffs/commit/$FILE.diff"
        if [ -s "$COMMIT_DIFF_FILE" ]; then
            COMMIT_ADDS=$(grep -c "^+[^+]" "$COMMIT_DIFF_FILE" 2>/dev/null || echo 0)
            COMMIT_DELS=$(grep -c "^-[^-]" "$COMMIT_DIFF_FILE" 2>/dev/null || echo 0)

            cat >> "$OUTPUT_DIR/conflict-analysis.md" << EOF

### Commit-Specific Changes (what \`$CONFLICT_COMMIT_SHORT\` actually changes)

- **Changes:** +$COMMIT_ADDS / -$COMMIT_DELS lines
- 📊 [Commit diff]($OUTPUT_DIR/diffs/commit/$FILE.diff)

EOF

            # Detect scope mismatch: incoming diff >> commit diff
            INCOMING_ADDS=$(grep -c "^+[^+]" "$OUTPUT_DIR/diffs/incoming/$FILE.diff" 2>/dev/null || echo 0)
            INCOMING_DELS=$(grep -c "^-[^-]" "$OUTPUT_DIR/diffs/incoming/$FILE.diff" 2>/dev/null || echo 0)
            INCOMING_TOTAL=$((INCOMING_ADDS + INCOMING_DELS))
            COMMIT_TOTAL=$((COMMIT_ADDS + COMMIT_DELS))

            if [ "$INCOMING_TOTAL" -gt 0 ] && [ "$COMMIT_TOTAL" -gt 0 ]; then
                RATIO=$((INCOMING_TOTAL / COMMIT_TOTAL))
                if [ "$RATIO" -ge 3 ]; then
                    cat >> "$OUTPUT_DIR/conflict-analysis.md" << 'EOF'
> **⚠️ SCOPE MISMATCH WARNING**: The incoming diff is much larger than this commit's actual changes. This typically happens during interactive rebase when commits are reordered. The "incoming" side contains accumulated state from other branch commits that haven't been replayed yet. **DO NOT accept the full incoming side.** Instead, accept HEAD and apply only the specific changes from the commit diff (`diffs/commit/`).

EOF
                fi
            fi
        else
            cat >> "$OUTPUT_DIR/conflict-analysis.md" << EOF

### Commit-Specific Changes

- This commit does not modify this file directly. The conflict is from context changes.

EOF
        fi
    fi

    # Generate pattern-based analysis using the new function
    analyze_conflict_pattern "$FILE" >> "$OUTPUT_DIR/conflict-analysis.md"

    # Add file-type-specific guidance as additional context
    case "$FILE" in
        *.Designer.cs)
            cat >> "$OUTPUT_DIR/conflict-analysis.md" << 'EOF'
**Designer.cs Note:** This is auto-generated. Resolve parent .resx file first, then regenerate this file. Do NOT manually merge.

EOF
            ;;
        *.resx)
            cat >> "$OUTPUT_DIR/conflict-analysis.md" << 'EOF'
**Resource File Note:** Resource entries are typically additive. Merge all entries from both branches unless they have conflicting values for the same key.

EOF
            ;;
    esac

    echo "**Note**: Do NOT simply pick 'HEAD only' or 'incoming only' without analysis. Most conflicts should preserve intent from both branches." >> "$OUTPUT_DIR/conflict-analysis.md"
    echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
    echo "---" >> "$OUTPUT_DIR/conflict-analysis.md"
    echo "" >> "$OUTPUT_DIR/conflict-analysis.md"
done

# Generate conflict-plan.md
if [ "$OPERATION_TYPE" = "rebase" ]; then
cat > "$OUTPUT_DIR/conflict-plan.md" << EOF
# Rebase Conflict Resolution Plan

## Overview

This plan provides a structured approach to resolving all $CONFLICT_COUNT rebase conflicts.

**Rebase Information:**
- **Rebasing:** \`${SOURCE_BRANCH:-$CURRENT_BRANCH}\` onto \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE)
- **Original HEAD:** \`$ORIGINAL_HEAD_SHORT\` "$ORIGINAL_HEAD_MSG" ($ORIGINAL_HEAD_DATE)
- **Applying commit:** \`$CONFLICT_COMMIT_SHORT\` "$CONFLICT_COMMIT_MSG" ($CONFLICT_COMMIT_DATE) ← **This commit conflicts**
- **Merge base:** \`$MERGE_BASE_SHORT\` "$MERGE_BASE_MSG" ($MERGE_BASE_DATE)

---
EOF
else
cat > "$OUTPUT_DIR/conflict-plan.md" << EOF
# Merge Conflict Resolution Plan

## Overview

This plan provides a structured approach to resolving all $CONFLICT_COUNT merge conflicts.

**Branches:**
- **Source:** \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE)
- **Target:** \`$CURRENT_BRANCH\` (\`$HEAD_REV\`, $HEAD_DATE)
- **Base:** \`$MERGE_BASE_SHORT\` "$MERGE_BASE_MSG" ($MERGE_BASE_DATE)

---
EOF
fi

cat >> "$OUTPUT_DIR/conflict-plan.md" << 'EOF'


## How to Use This Plan

Each task below lists a conflicted file. The resolution strategy and reasoning for each file is in **conflict-analysis.md**. This plan is just a TODO list.

To resolve: Read the analysis for the specific file, then apply the resolution described there.

---

## Task List

EOF

# Generate tasks
COUNTER=1
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue
    ANCHOR=$(echo "$FILE" | sed 's|/|-|g' | sed 's|\.|-|g')

    cat >> "$OUTPUT_DIR/conflict-plan.md" << EOF

#### ☐ Task $COUNTER: \`$FILE\`


**See:** [conflict-analysis.md § $FILE](conflict-analysis.md#$ANCHOR) for resolution strategy

**Diffs:** \`diffs/head/$FILE.diff\` and \`diffs/incoming/$FILE.diff\`

---
EOF
    COUNTER=$((COUNTER + 1))
done

# Add post-resolution sections
cat >> "$OUTPUT_DIR/conflict-plan.md" << 'EOF'


## Post-Resolution

After resolving all conflicts:

- [ ] `git status` shows no unmerged files
- [ ] Build succeeds: `dotnet build`
- [ ] Fix any compilation errors
- [ ] Continue: `git rebase --continue` or `git merge --continue`

EOF

# Generate README.md - DRY version with only operation-specific differences
if [ "$OPERATION_TYPE" = "rebase" ]; then
    README_TITLE="Rebase Conflict Resolution"
    README_INTRO="This directory contains tools and analysis for resolving rebase conflicts while rebasing \`${SOURCE_BRANCH:-$CURRENT_BRANCH}\` onto \`$INCOMING_BRANCH\`."
    README_HEAD_COMMENT="Changes from target branch $INCOMING_BRANCH"
    README_INCOMING_COMMENT="Changes from commit being applied"
    README_INFO_SECTION="## Rebase Information

- **Rebasing:** \`${SOURCE_BRANCH:-$CURRENT_BRANCH}\` onto \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE)
- **Original HEAD:** \`$ORIGINAL_HEAD_SHORT\` \"$ORIGINAL_HEAD_MSG\" ($ORIGINAL_HEAD_DATE)
- **Applying commit:** \`$CONFLICT_COMMIT_SHORT\` \"$CONFLICT_COMMIT_MSG\" ($CONFLICT_COMMIT_DATE) ← Conflicts
- **Merge base:** \`$MERGE_BASE_SHORT\` \"$MERGE_BASE_MSG\" ($MERGE_BASE_DATE)
- **Total Conflicts:** $CONFLICT_COUNT files"
else
    README_TITLE="Merge Conflict Resolution"
    README_INTRO="This directory contains tools and analysis for resolving merge conflicts between \`$INCOMING_BRANCH\` and \`$CURRENT_BRANCH\`."
    README_HEAD_COMMENT="Changes from $CURRENT_BRANCH (HEAD)"
    README_INCOMING_COMMENT="Changes from $INCOMING_BRANCH"
    README_INFO_SECTION="## Merge Information

- **Source:** \`$INCOMING_BRANCH\` (\`$INCOMING_REV\`, $INCOMING_DATE)
- **Target:** \`$CURRENT_BRANCH\` (\`$HEAD_REV\`, $HEAD_DATE)
- **Base:** \`$MERGE_BASE_SHORT\` \"$MERGE_BASE_MSG\" ($MERGE_BASE_DATE)
- **Total Conflicts:** $CONFLICT_COUNT files"
fi

cat > "$OUTPUT_DIR/README.md" << EOF
# $README_TITLE

$README_INTRO

## Files

- **[conflict-plan.md](conflict-plan.md)** - Task list with $CONFLICT_COUNT conflicts, resolution strategies for each
- **[conflict-analysis.md](conflict-analysis.md)** - Detailed change analysis with recommendations
- **[verification-checklist.md](verification-checklist.md)** - Checklist to verify all changes are present
- **[conflicts.txt](conflicts.txt)** - Simple list of conflicted file paths

## Usage

These files are designed for **dual use**:

1. **Auto-resolution by the shy skill** - Agents read these files to understand conflicts and auto-resolve them intelligently
2. **Manual reference for IDE resolution** - You can read the analysis and view the diffs to manually resolve conflicts in your IDE

Whether you choose auto-resolution or manual resolution, the analysis provides context about what each branch changed and why.

## Folder Structure

\`\`\`
$OUTPUT_DIR/
├── README.md                       # This file
├── conflict-plan.md                # Main TODO list (start here)
├── conflict-analysis.md            # Detailed analysis reference
├── verification-checklist.md       # Post-resolution verification
├── conflicts.txt                   # List of $CONFLICT_COUNT conflicted files
├── diffs/
│   ├── head/                       # $README_HEAD_COMMENT
│   │   └── **/*.diff
│   └── incoming/                   # $README_INCOMING_COMMENT
│       └── **/*.diff
├── resolution_*.patch              # Created after resolution: diffs from HEAD
└── resolution_summary.md           # Created after resolution: high-level summary
\`\`\`

## Quick Start

1. Read **conflict-plan.md** for the task list and resolution workflow
2. For each task, choose a resolution strategy (recommended marked with ✅)
3. Tell the agent which task and strategy to use, or resolve manually in your IDE
4. Reference **conflict-analysis.md** for detailed change summaries
5. View \`.diff\` files in \`diffs/\` for full context

$README_INFO_SECTION
EOF

ANALYSIS_SCRIPT

# Make the temporary script executable and run it
chmod +x "$OUTPUT_DIR/generate-analysis.sh"
bash "$OUTPUT_DIR/generate-analysis.sh"
rm "$OUTPUT_DIR/generate-analysis.sh"
rm "$OUTPUT_DIR/.generate-analysis.vars"

# Generate verification checklist
cat > "$OUTPUT_DIR/verification-checklist.md" << 'CHECKLIST_EOF'
# Verification Checklist

Use this checklist to verify all expected changes are present after conflict resolution.

## Overview

Check each item below to ensure no changes were lost during resolution.

CHECKLIST_EOF

# Add checklist items for each conflicted file
echo "$CONFLICTS" | while read -r FILE; do
    [ -z "$FILE" ] && continue

    echo "" >> "$OUTPUT_DIR/verification-checklist.md"
    echo "## $FILE" >> "$OUTPUT_DIR/verification-checklist.md"
    echo "" >> "$OUTPUT_DIR/verification-checklist.md"

    # Extract key changes from HEAD diff
    HEAD_DIFF_FILE="$OUTPUT_DIR/diffs/head/$FILE.diff"
    if [ -f "$HEAD_DIFF_FILE" ]; then
        echo "### From HEAD Branch" >> "$OUTPUT_DIR/verification-checklist.md"
        echo "" >> "$OUTPUT_DIR/verification-checklist.md"

        # Extract added methods
        grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$HEAD_DIFF_FILE" 2>/dev/null | head -3 | while read -r LINE; do
            METHOD=$(echo "$LINE" | sed -n 's/^+.*\s\+\(\w\+\)\s*(.*$/\1/p')
            [ -n "$METHOD" ] && echo "- [ ] Method \`$METHOD()\` present" >> "$OUTPUT_DIR/verification-checklist.md"
        done

        # Extract removed code blocks (likely refactorings)
        REMOVED_LINES=$(grep -c "^-" "$HEAD_DIFF_FILE" 2>/dev/null || echo 0)
        if [ "$REMOVED_LINES" -gt 10 ]; then
            echo "- [ ] Refactoring applied (~$REMOVED_LINES lines removed)" >> "$OUTPUT_DIR/verification-checklist.md"
        fi
    fi

    # Extract key changes from incoming diff
    INCOMING_DIFF_FILE="$OUTPUT_DIR/diffs/incoming/$FILE.diff"
    if [ -f "$INCOMING_DIFF_FILE" ]; then
        echo "" >> "$OUTPUT_DIR/verification-checklist.md"
        echo "### From Incoming Branch" >> "$OUTPUT_DIR/verification-checklist.md"
        echo "" >> "$OUTPUT_DIR/verification-checklist.md"

        # Extract added methods
        grep "^+\s*\(public\|private\|protected\|internal\)\s.*\s\+\w\+\s*(" "$INCOMING_DIFF_FILE" 2>/dev/null | head -5 | while read -r LINE; do
            METHOD=$(echo "$LINE" | sed -n 's/^+.*\s\+\(\w\+\)\s*(.*$/\1/p')
            [ -n "$METHOD" ] && echo "- [ ] Method \`$METHOD()\` present" >> "$OUTPUT_DIR/verification-checklist.md"
        done

        # Extract added using statements
        grep "^+using " "$INCOMING_DIFF_FILE" 2>/dev/null | head -3 | while read -r LINE; do
            USING=$(echo "$LINE" | sed 's/^+using \(.*\);$/\1/')
            [ -n "$USING" ] && echo "- [ ] Using statement \`$USING\` present" >> "$OUTPUT_DIR/verification-checklist.md"
        done
    fi
done

cat >> "$OUTPUT_DIR/verification-checklist.md" << 'CHECKLIST_FOOTER'

## Build Verification

- [ ] Project builds successfully
- [ ] No new compilation errors
- [ ] All tests pass (if applicable)

## Additional Files to Check

Check if any refactorings require changes in related files:

- [ ] Related .cs files that may use moved methods
- [ ] Related .razor files that may reference changed code
- [ ] Controllers, components, or pages that depend on modified code

CHECKLIST_FOOTER

echo "  ✓ Created conflict-analysis.md"
echo "  ✓ Created conflict-plan.md"
echo "  ✓ Created README.md"
echo "  ✓ Created verification-checklist.md"

echo ""
echo -e "${GREEN}=== Analysis Complete ===${NC}"
echo ""
echo -e "Output directory: ${BLUE}$OUTPUT_DIR/${NC}"
echo "  - $CONFLICT_COUNT conflicted files"
echo "  - $(find "$OUTPUT_DIR/diffs" -name "*.diff" 2>/dev/null | wc -l) diff files generated"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review: $OUTPUT_DIR/conflict-plan.md"
echo "  2. Start resolving conflicts following the plan"
echo "  3. Use the agent to auto-resolve or resolve manually in your IDE"
echo ""
