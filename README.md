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

## Squash branch

Install globally:

```bash
npx skills add angularsen/skills --skill squash-branch --agent claude-code codex --global --yes
```

Invoke with `$squash-branch` in Codex, `/squash-branch` in Claude Code, or ask to “merge latest main and squash this feature branch.” It checkpoints and integrates changed submodule branches too, preserves recovery refs, and checks protected branches before an authorized force-with-lease push. Requires Git and authenticated remote access to publish. Host metadata checks are reserved for unclear default branches or conflicting protection information.

## Agent cleanup

Install globally on any machine with an agent that supports skills:

```bash
npx skills add angularsen/skills --skill agent-cleanup --agent claude-code codex --global --yes
```

Invoke with `$agent-cleanup` in Codex, `/agent-cleanup` in Claude Code, or ask to clean up leftover agent processes. Uses available host tools on macOS, Linux, or Windows; no bundled daemon or cleanup dependency.

## Retro

Review an agent session and suggest evidence-backed improvements to its instructions, tools, navigation, and checks. Adapted from [Matt Pocock's retro](https://github.com/mattpocock/skills/tree/main/skills/engineering/retro), with portable T3 Code, Codex, Claude Code, and Git worktree discovery.

From an up-to-date clone of this repo, install on each computer (Node.js/npm required):

```bash
npx --yes skills add . --skill retro --agent claude-code codex --global --yes
```

After the change is published to this repository, install without a clone on either computer:

```bash
npx --yes skills add angularsen/skills --skill retro --agent claude-code codex --global --yes
```

Rerun the appropriate command to refresh the installed copy; pull the clone first when installing from `.`. Start a fresh provider session if the running client has cached its skill list.

Invoke explicitly with `$retro` in Codex or `/retro` in Claude Code. In T3 Code, use the selected provider's skill invocation; if the UI does not expose it, ask the agent to read the installed `retro/SKILL.md` and run it. For example: “Use $retro on this session” or “Use /retro on the session from yesterday in this worktree.” No T3-specific plugin or command wrapper is needed.

The upstream `writing-for-agents` dependency and relevant skill mechanics are bundled as a reference, which `retro` instructs the agent to read. Only `retro` needs installation. It discovers each repo's conventions rather than requiring particular repo names or documentation files. It proposes changes by default; ask it to implement the recommendations when wanted. Session history stays on the machine/provider host that recorded it and is not synced by installation.

See [upstream and maintenance notes](skills/retro/references/upstream.md) for provenance and the dependency decision.

## Skills

| Skill | Description |
|-------|-------------|
| [agent-cleanup](skills/agent-cleanup/) | Reclaim CPU and memory from leftover agent sessions, dev servers, tests, and automation helpers |
| [babysit-pr](skills/babysit-pr/) | Coordinate cross-provider PR review, fixes, CI and re-review with a user-controlled completion policy |
| [clonvex-dev-setup](skills/clonvex-dev-setup/) | Bootstrap a Clerk + Convex project with local and cloud dev modes (framework-agnostic) |
| [retro](skills/retro/) | Review session evidence and recommend improvements; includes its writing guide and T3/Codex/Claude session discovery |
| [squash-branch](skills/squash-branch/) | Checkpoint, merge main, squash feature/submodule branches and publish with explicit leases |
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
