# Agent Skills

Reusable agent skills for bootstrapping projects. Works with any AI coding agent that supports the [Agent Skills](https://skills.sh) convention (Claude Code, Cursor, Windsurf, etc.).

## Install

```bash
npx skills add angularsen/skills
```

## Skills

| Skill | Description |
|-------|-------------|
| [clonvex-dev-setup](skills/clonvex-dev-setup/) | Bootstrap a Clerk + Convex project with local and cloud dev modes (framework-agnostic) |

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
