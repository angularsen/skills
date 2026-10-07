# Writing for agents

Adapted from Matt Pocock's `writing-for-agents` and `SKILL-MECHANICS.md`; see [upstream.md](upstream.md). This is bundled reference material, read directly by `retro`.

## Write pointers that cause the right lookup

A context pointer names out-of-context material and says when to read it. A skill description and an `AGENTS.md` link serve the same purpose. State the capability and one trigger per distinct branch; collapse synonyms. For required material, use an explicit loading instruction and an exact resolvable path.

Always-loaded instructions spend context on every turn. Material behind a pointer spends context when needed, but the pointer must be discoverable. Material available only by explicit invocation asks the user to remember it. Choose that tradeoff deliberately.

## Put detail where it is used

Keep shared steps and essential constraints in the entrypoint. Co-locate a concept's definition, rules, and caveats. Move substantial branch-specific reference into linked files and state when each is needed. Splitting a document only helps if the agent can still find all the material required for the task.

Make completion criteria observable: identify the actual condition that ends an investigation or proves a change. A vague instruction to understand or be thorough rarely changes behavior. Split a long workflow when real usage shows later steps repeatedly distracting from unfinished investigation, not merely to create more files.

Use familiar, precise terms that carry useful meaning. Prefer a concrete desired action over a list of forbidden alternatives; retain explicit prohibitions where they protect a real boundary.

## Prune by behavior

Keep one authoritative home for each instruction. Link to it where needed instead of repeating it. Configuration, scripts, directory layouts, and tool help are also authoritative sources: avoid caching details an agent can cheaply inspect unless a lookup is unusually costly.

For each proposed instruction, ask what future decision it changes. Delete generic advice, stale sediment, and duplicate explanation. Preserve the convention, reason, or trap that the environment does not reveal. Generalize from the session without baking its repo names, paths, model IDs, or one-off failures into universal rules.

## When recommending a skill

Use a skill for a repeatable workflow or independently useful reference with a clear discovery trigger. Keep supporting files inside its installation directory when they are needed for that skill to work on another machine. A relative Markdown link needs an instruction explaining when to read it; a skill name alone does not install or load a dependency.

For external skill dependencies, verify availability in the current host's catalog and read their entrypoint using that host's supported mechanism. If absent, report the missing dependency or use an explicitly documented bundled fallback. Do not invent a universal Skill tool or assume a metadata dependency field installs other skills.

Invocation controls are host-specific. Preserve existing explicit-only choices: Claude Code uses `disable-model-invocation: true`; Codex uses `policy.allow_implicit_invocation: false` in `agents/openai.yaml`. New skills should follow the user's intended invocation behavior and the host's current authoring guidance.
