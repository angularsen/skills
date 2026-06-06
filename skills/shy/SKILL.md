---
name: shy
description: Analyze and resolve Git merge or rebase conflicts with generated 3-way diffs, conflict plans, rebase commit-scope checks, reset guidance, and verification. Use when a user invokes $shy, asks for Shy conflict help, has unmerged paths, is blocked by git merge/rebase conflicts, or wants to preserve intent from both branches during conflict resolution.
---

# Shy

Use Shy to handle Git merge and rebase conflicts carefully. It generates a per-file conflict plan, diffs from each side, optional commit-specific diffs for rebase conflicts, and a verification checklist.

## First Action

Always run:

```bash
git status
```

If `git status` shows no unmerged paths, tell the user there is no active conflict. If there are unmerged paths, continue with the workflow.

On Windows/PowerShell, run `git status` with native Git first and treat it as
authoritative. Do not rely on WSL/Bash helpers to detect the rebase state if
they disagree with native Git.

## Core Rule

For merges, preserve the intent from both branches whenever compatible.

For rebases, apply only the currently replayed commit's changes. The incoming side of conflict markers can include branch context from commits that have not replayed yet, especially after interactive reordering. Treat `output/diffs/commit/` as the ground truth for what the current commit actually changes.

## Tool Location

Find the installed skill directory before running scripts. Common project-local locations are:

- `.agents/skills/shy`
- `.claude/skills/shy`
- `.cursor/skills/shy`

Common user-global locations are:

- `$HOME/.agents/skills/shy` or `%USERPROFILE%\.agents\skills\shy`
- `$HOME/.codex/skills/shy` or `%USERPROFILE%\.codex\skills\shy`

Prefer `.agents/skills/shy` when it exists. If the skill was installed globally with `skills.sh`, use the matching user-global path. In the examples below, replace `.agents/skills/shy` with the actual installed directory if needed.

## Generate Analysis

After confirming conflicts exist, run:

```bash
bash .agents/skills/shy/analyze-conflict.sh
```

If no analysis exists and the user asks to resolve, this also works:

```bash
bash .agents/skills/shy/resolve.sh
```

The scripts generate output inside the installed skill directory by default:

```text
.agents/skills/shy/output/
├── conflict-plan.md
├── conflict-analysis.md
├── verification-checklist.md
├── conflicts.txt
└── diffs/
```

Use `generate-conflict-analysis.sh <branch-or-commit> --output <dir>` only when you need to override auto-detection or use a custom output directory.

## Present The Plan

Read `output/conflict-plan.md` and summarize:

- total conflicted files
- notable phases or file groups
- files that are safe candidates for auto-resolution
- files that look risky and may need user choice

Ask which task to start with unless the user already asked you to resolve everything.

## Auto-Resolution

For each task:

1. Read that file's section in `output/conflict-analysis.md`.
2. For rebases, read `output/diffs/commit/<file>.diff` first when it exists.
3. Read `output/diffs/head/<file>.diff` and `output/diffs/incoming/<file>.diff`.
4. Read the conflicted file with conflict markers.
5. Resolve by preserving compatible changes from both sides.
6. Stage the file with `git add <file>`.
7. Verify no conflict markers remain.

Useful checks:

```bash
git diff --name-only --diff-filter=U
git grep -n -E "^(<<<<<<<|=======|>>>>>>>)" -- .
```

## Codex/Windows Fallbacks

When running from Codex on Windows, the current shell is often PowerShell while
Shy's helpers are Bash scripts. Prefer Git Bash for the scripts when available,
especially for linked worktrees whose `.git` file points at a Windows path such
as `X:/...`; WSL Bash may report "not a git repository" because it cannot
resolve that `gitdir`.

Quote Git revspecs that PowerShell may parse as syntax. For example:

```powershell
git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
```

If a Bash helper fails with CRLF/shebang errors, use a normalized temporary copy
of the skill scripts or fall back to the manual workflow below. The source skill
should force LF for `*.sh`, but installed global copies may predate that fix.

Manual workflow when helpers cannot run:

1. Confirm the active conflict:
   ```bash
   git status
   git diff --name-only --diff-filter=U
   ```
2. For each conflicted file, inspect the three sides:
   ```bash
   git diff --base -- path/to/file
   git diff --ours -- path/to/file
   git diff --theirs -- path/to/file
   git show :1:path/to/file   # merge base
   git show :2:path/to/file   # ours / HEAD
   git show :3:path/to/file   # theirs / incoming
   ```
3. Resolve by the Core Rule, stage with `git add path/to/file`, then verify:
   ```bash
   git diff --name-only --diff-filter=U
   git grep -n -E "^(<<<<<<<|=======|>>>>>>>)" -- .
   ```

Use the anchored grep above. A broad search for `=======` can match decorative
separator lines in scripts and create false alarms.

## Resolution Heuristics

- `.resx`: merge additive `<data>` entries from both sides; ask if the same key has different values.
- `.Designer.cs`: resolve or regenerate only after the parent `.resx` is resolved; avoid manual merging unless necessary.
- `.cs`: combine non-overlapping methods, properties, using statements, and type changes. For moved code, search for the new location and apply the relevant side's change there.
- `.razor`: combine compatible UI layout and data/model changes. If both branches substantially rewrote the same markup or logic, explain the conflict and ask for direction.
- modify/delete: search for moved or renamed equivalents before accepting deletion or restoration.

## Resetting

If the user asks to reset a resolved file back to conflicted state, match the requested file or pattern against `output/conflicts.txt`, then run:

```bash
git checkout --conflict=merge <file-path>
```

Support loose patterns such as `all`, `resources`, `all resx`, `components`, `pages`, `razor`, exact paths, and partial filenames.

## Verification

When all conflicts are resolved:

1. Run `git status` and confirm no unmerged paths remain.
2. Run `validate-resolution.sh`:

   ```bash
   bash .agents/skills/shy/validate-resolution.sh
   ```

3. Review `output/verification-checklist.md`.
4. Run the project's build or test command if discoverable.
5. Tell the user whether they should continue with `git merge --continue`, `git rebase --continue`, or a normal merge commit.

For rebases, continue non-interactively unless the user explicitly wants to
edit the replayed commit message:

```bash
GIT_EDITOR=true git rebase --continue
```

In PowerShell:

```powershell
git -c core.editor=true rebase --continue
```

When verification depends on generated files, run generation and type checks
sequentially. For example, run Convex codegen first and wait for it to finish,
then run `tsc --noEmit`; do not run them in parallel.
