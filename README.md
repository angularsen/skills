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

Install Babysit PR globally for Codex and Claude Code on each machine:

```bash
npx skills add angularsen/skills --skill babysit-pr --agent claude-code codex --global --yes
```

Invoke with `$babysit-pr` in Codex, `/babysit-pr` in Claude Code, or ask “babysit these PRs.” It infers PRs from the session or accepts URLs, coordinates an independent reviewer from the other provider, addresses feedback and CI, and defaults to handing the result back for user re-review. Auto-complete requires your authorization.

The reviewer helper needs Node.js and the selected reviewer CLI (`codex` or `claude`) installed and authenticated on that machine. GitHub/Azure access uses the author's existing tools or authenticated CLI. Paths and frontier model IDs are resolved on the host; no machine-specific configuration or credentials ship with the skill. The installed Claude skill provides its own slash command, so no extra command wrapper is needed.

Update the installed copy later with:

```bash
npx skills update babysit-pr --global --yes
```

Claude Code can invoke installed skills directly with `/shy`. The older `/shy:resolve`, `/shy:analyze`, and `/shy:reset` command wrappers are Claude-specific and are not installed by `skills.sh`. To install those optional wrappers from a local clone:

```bash
# Project-local Claude commands
bash scripts/install-claude-shy-commands.sh --project /path/to/project
.\scripts\install-claude-shy-commands.ps1 -Project X:\path\to\project

# User-global Claude commands
bash scripts/install-claude-shy-commands.sh --user
.\scripts\install-claude-shy-commands.ps1 -User
```

## Agent cleanup

Install globally on any machine with an agent that supports skills:

```bash
npx skills add angularsen/skills --skill agent-cleanup --agent claude-code codex --global --yes
```

Invoke with `$agent-cleanup` in Codex, `/agent-cleanup` in Claude Code, or ask to clean up leftover agent processes. Uses available host tools on macOS, Linux, or Windows; no bundled daemon or cleanup dependency.

## Skills

| Skill | Description |
|-------|-------------|
| [agent-cleanup](skills/agent-cleanup/) | Reclaim CPU and memory from leftover agent sessions, dev servers, tests, and automation helpers |
| [babysit-pr](skills/babysit-pr/) | Coordinate cross-provider PR review, fixes, CI and re-review with a user-controlled completion policy |
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
