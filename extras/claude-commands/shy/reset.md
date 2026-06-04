---
description: Reset merge/rebase conflict files with Shy
allowed-tools:
  - Bash(git checkout:*)
---

Intelligently reset files back to conflicted state for a merge/rebase conflict based on user's request, or all files if no instructions are given.

## Command Template

Use this git command to reset files:

```bash
git checkout --conflict=merge <file-path>
```

## Instructions

1. **Read conflicts list**: Prefer `.agents/skills/shy/output/conflicts.txt`; if missing, read `.claude/skills/shy/output/conflicts.txt` to get all conflicted files
2. **Match pattern**: Based on user's request, match files using:
   - **Exact path**: `app/Vaskehjelp.UI.Shared/Components/CategoryRatingBreakdown.razor`
   - **Partial name**: Match files containing the text (e.g., "CategoryRatingBreakdown")
   - **Pattern keywords**:
     - `all` - All conflicted files
     - `all resources` or `resources` - All `.resx` and `.Designer.cs` files
     - `all UI` or `components` - All `.razor` files in `/Components/` directories
     - `all pages` or `pages` - All `.razor` files in `/Pages/` directories
     - `all razor` - All `.razor` files
3. **Show matches**: List matched files and ask for confirmation if multiple files
4. **Reset each file**: Run `git checkout --conflict=merge <file>` for each matched file in parallel
5. **Confirm**: Report which files were reset

## Usage Examples

User: `/shy:reset CategoryRatingBreakdown`
- Match: Files containing "CategoryRatingBreakdown"
- Reset: `app/Vaskehjelp.UI.Shared/Components/CategoryRatingBreakdown.razor`

User: `/shy:reset all resources`
- Match: All `.resx` and `.Designer.cs` files
- Reset: Multiple resource files in parallel

User: `/shy:reset all`
- Match: All files in conflicts.txt
- Reset: All conflicted files in parallel

User: `/shy:reset Strings.resx and CategoryRatingBreakdown`
- Match: Files matching either pattern
- Reset: Both files in parallel
