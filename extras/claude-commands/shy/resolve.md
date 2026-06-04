---
description: Resolve merge/rebase conflicts with Shy
allowed-tools:
  - Bash(bash .agents/skills/shy/resolve.sh:*)
  - Bash(bash .claude/skills/shy/resolve.sh:*)
  - Bash(.agents/skills/shy/resolve.sh:*)
  - Bash(.claude/skills/shy/resolve.sh:*)
---

## Context

Intelligently handles merge conflicts based on current state:
- If conflict analysis exists: Execute resolution plan
- If in merge state but no analysis: Generate analysis
- If not in merge: Show instructions

## Instructions

Run the script:

```bash
bash .agents/skills/shy/resolve.sh
```

If `.agents/skills/shy` is not installed but `.claude/skills/shy` is, run:

```bash
bash .claude/skills/shy/resolve.sh
```
