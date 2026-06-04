---
description: Analyze merge/rebase conflicts with Shy
allowed-tools:
  - Bash(bash .agents/skills/shy/analyze-conflict.sh:*)
  - Bash(bash .claude/skills/shy/analyze-conflict.sh:*)
  - Bash(.agents/skills/shy/analyze-conflict.sh:*)
  - Bash(.claude/skills/shy/analyze-conflict.sh:*)
---

## Context

Generates merge/rebase conflict analysis, and regenerates if one already exists.

Useful when:
- Files have changed since last analysis
- Want fresh analysis after manual edits
- Need to update recommendations

## Instructions

Run the script:

```bash
bash .agents/skills/shy/analyze-conflict.sh
```

If `.agents/skills/shy` is not installed but `.claude/skills/shy` is, run:

```bash
bash .claude/skills/shy/analyze-conflict.sh
```
