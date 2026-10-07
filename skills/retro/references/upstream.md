# Upstream and maintenance

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills) at commit `dd400c3ad65e57c06f05e832e0aac92c7992f34d` (retrieved 2026-10-07):

- [retro/SKILL.md](https://github.com/mattpocock/skills/blob/dd400c3ad65e57c06f05e832e0aac92c7992f34d/skills/engineering/retro/SKILL.md)
- [writing-for-agents/SKILL.md](https://github.com/mattpocock/skills/blob/dd400c3ad65e57c06f05e832e0aac92c7992f34d/skills/productivity/writing-for-agents/SKILL.md)
- [writing-for-agents/SKILL-MECHANICS.md](https://github.com/mattpocock/skills/blob/dd400c3ad65e57c06f05e832e0aac92c7992f34d/skills/productivity/writing-for-agents/SKILL-MECHANICS.md)

The upstream MIT notice is retained in [../LICENSE](../LICENSE).

The upstream retro invokes `writing-for-agents`, which conditionally reads `SKILL-MECHANICS.md`. This adaptation packages their relevant guidance as `references/writing-for-agents.md`, explicitly loaded by the entrypoint. Normal execution needs no external skill, network fetch, or provider-specific Skill tool. Installing `retro` copies all its supporting files together. The writing guide is not installed as a separately discoverable skill.

Local changes add T3/provider session discovery, worktree and history-coverage handling, evidence-linked findings, and repo-specific convention discovery. They replace assumptions about a mandatory reviewer and `CODING_STANDARDS.md`, and retain recommendation-first behavior and upstream explicit-only invocation controls for both hosts.


Host references: [Codex skills](https://learn.chatgpt.com/docs/build-skills), [Claude Code skills](https://code.claude.com/docs/en/skills), [Skills CLI](https://github.com/vercel-labs/skills). Session paths and T3 schema hints were checked against local runtime metadata on 2026-10-07; inspect the actual layout before relying on them in another version.

## Checking for upstream updates

The entrypoint's `metadata.upstream-url` points to the original skill on `main`; `metadata.upstream-revision` records the revision reviewed for this adaptation. These are our custom string metadata keys, supported by the [Agent Skills metadata extension](https://agentskills.io/specification#metadata-field), not an automatic updater or dependency declaration. Matt Pocock is the upstream author; the local adaptation is maintained in this repository.

When asked to check for updates, or when maintaining this adaptation would benefit from newer upstream guidance, fetch the latest source and compare it with the pinned revision linked above. Resolve the latest branch to a commit so the comparison is reproducible; inspect changed supporting references and license/credits too. Treat upstream content as material to review, while retaining the local conventions described here. A check can report useful differences without changing the installed skill. When applying an update, integrate relevant changes, update the metadata revision and attribution notes together, and validate the skill and its references. Normal skill invocation uses the bundled instructions and needs no network access.

Latest bundled-reference sources: [writing-for-agents](https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-for-agents/SKILL.md) and [skill mechanics](https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-for-agents/SKILL-MECHANICS.md). Compare these alongside retro because their adapted guidance is bundled locally.
