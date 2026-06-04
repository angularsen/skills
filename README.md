# Agent Skills

Reusable open source agent skills for project-local coding workflows. Works with AI coding agents that support the [Agent Skills](https://skills.sh) convention, including Codex, Claude Code, Cursor, Windsurf, and similar tools.

## Install

Install all skills from this repo:

```bash
npx skills add angularsen/skills
```

Install Shy into the current project:

```bash
npx skills add angularsen/skills --skill shy --agent claude-code codex
```

Install Shy globally for the current user:

```bash
npx skills add angularsen/skills --skill shy --agent claude-code codex --global
```

Adjust `--agent` for the tools you use, such as adding `cursor`. The Skills CLI also supports `--agent '*'`, but that installs to every known agent layout and is usually more than a project needs.

Claude Code can invoke installed skills directly with `/shy`. The older `/shy:resolve`, `/shy:analyze`, and `/shy:reset` command wrappers are Claude-specific and are not installed by `skills.sh`. To install those optional wrappers from a local clone:

```bash
# Project-local Claude commands
bash scripts/install-claude-shy-commands.sh --project /path/to/project
.\scripts\install-claude-shy-commands.ps1 -Project X:\path\to\project

# User-global Claude commands
bash scripts/install-claude-shy-commands.sh --user
.\scripts\install-claude-shy-commands.ps1 -User
```

## Skills

| Skill | Description |
|-------|-------------|
| [clonvex-dev-setup](skills/clonvex-dev-setup/) | Bootstrap a Clerk + Convex project with local and cloud dev modes (framework-agnostic) |
| [shy](skills/shy/) | Analyze and resolve Git merge/rebase conflicts with generated 3-way diffs and careful rebase scope checks |

## Creating Skills

Each skill is a folder under `skills/` with a `SKILL.md` file:

```
skills/
└── my-skill/
    ├── SKILL.md           # Frontmatter + instructions (required)
    └── references/        # Supporting docs, examples (optional)
```

Initialize a new skill:

```bash
npx skills init skills/my-skill
```
