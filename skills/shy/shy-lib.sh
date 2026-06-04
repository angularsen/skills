#!/bin/bash
# shy-lib.sh - Shared functions for shy conflict analysis tools

# Resolves a commit SHA or branch name to a clean branch name
# Prefers master/main branches, filters out symrefs, converts remotes/origin/foo to origin/foo
#
# Usage: resolve_branch_name_for_commit <commit-or-branch> [prefer-master-main]
# Arguments:
#   commit-or-branch: Git commit SHA or branch name
#   prefer-master-main: If "true", prefer branches ending with master/main (default: false)
# Returns: Branch name on stdout, empty if not found
resolve_branch_name_for_commit() {
    local commit="$1"
    local prefer_master="${2:-false}"

    # Verify commit exists
    if ! git rev-parse --verify "$commit" > /dev/null 2>&1; then
        return 1
    fi

    local branch_name=""

    if [ "$prefer_master" = "true" ]; then
        # Find branch name preferring master/main:
        # - grep -v '\->' excludes symrefs like "remotes/origin/HEAD -> origin/master"
        # - grep -E '(master|main)$' prefers branches ending with master or main
        # - sed 's/^[*+ ]*//' removes leading spaces and markers
        # - sed 's/remotes\///' converts "remotes/origin/master" to "origin/master"
        branch_name=$(git branch --all --contains "$commit" \
            | grep -v '\->' \
            | grep -E '(master|main)$' \
            | sed 's/^[*+ ]*//' \
            | sed 's/remotes\///' \
            | head -1)
    fi

    # Fallback to any branch if master/main not found or not preferred
    if [ -z "$branch_name" ]; then
        branch_name=$(git branch --all --contains "$commit" \
            | grep -v '\->' \
            | grep -v '^[*+]' \
            | sed 's/^  *//' \
            | sed 's/remotes\///' \
            | head -1)
    fi

    echo "$branch_name"
}

# Gets the onto commit for an active rebase
# Returns: Full commit SHA on stdout, empty if not in rebase
get_rebase_onto_commit() {
    local merge_path=$(git rev-parse --git-path rebase-merge/onto 2>/dev/null)
    local apply_path=$(git rev-parse --git-path rebase-apply/onto 2>/dev/null)

    if [ -f "$merge_path" ]; then
        cat "$merge_path"
    elif [ -f "$apply_path" ]; then
        cat "$apply_path"
    fi
}

# Gets the original HEAD before rebase started
# Returns: Full commit SHA on stdout, empty if not in rebase
get_rebase_original_head() {
    local merge_path=$(git rev-parse --git-path rebase-merge/orig-head 2>/dev/null)
    local apply_path=$(git rev-parse --git-path rebase-apply/orig-head 2>/dev/null)

    if [ -f "$merge_path" ]; then
        cat "$merge_path"
    elif [ -f "$apply_path" ]; then
        cat "$apply_path"
    fi
}

# Gets the commit that is currently being applied (causing conflict)
# Returns: Full commit SHA on stdout, empty if not in rebase or no conflict
get_rebase_stopped_commit() {
    local stopped_sha_path=$(git rev-parse --git-path rebase-merge/stopped-sha 2>/dev/null)

    if [ -f "$stopped_sha_path" ]; then
        cat "$stopped_sha_path"
    fi
}

# Gets the source branch name being rebased
# Returns: Branch name on stdout (without refs/heads/ prefix), empty if not in rebase
get_rebase_source_branch() {
    local merge_path=$(git rev-parse --git-path rebase-merge/head-name 2>/dev/null)
    local apply_path=$(git rev-parse --git-path rebase-apply/head-name 2>/dev/null)

    if [ -f "$merge_path" ]; then
        cat "$merge_path" | sed 's|refs/heads/||'
    elif [ -f "$apply_path" ]; then
        cat "$apply_path" | sed 's|refs/heads/||'
    fi
}

# Checks if currently in a rebase state
# Returns: 0 if in rebase, 1 otherwise
is_in_rebase() {
    local merge_path=$(git rev-parse --git-path rebase-merge 2>/dev/null)
    local apply_path=$(git rev-parse --git-path rebase-apply 2>/dev/null)
    [ -d "$merge_path" ] || [ -d "$apply_path" ]
}

# Checks if currently in a merge state
# Returns: 0 if in merge, 1 otherwise
is_in_merge() {
    local merge_head_path=$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)
    [ -f "$merge_head_path" ]
}

# Gets the commit being merged
# Returns: Full commit SHA on stdout, empty if not in merge
get_merge_commit() {
    local merge_head_path=$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)
    if [ -f "$merge_head_path" ]; then
        cat "$merge_head_path"
    fi
}
