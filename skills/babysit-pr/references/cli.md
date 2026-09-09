# CLI handoff

`scripts/reviewer.mjs` runs one reviewer turn, captures the response and saves its session ID. Author orchestrates PR writes, fixes, waiting and completion.

Check installed `codex exec --help` / `codex exec resume --help` or `claude --help` on a new host. Discover an available frontier model; pass medium/high explicitly. Reuse normal CLI authentication; never copy credentials into briefs.

Prepare isolated reviewer checkouts and a persistent local session directory outside tracked source. Request uses absolute paths and a discovered model ID:

```json
{
  "provider": "codex",
  "model": "ACTUAL_AVAILABLE_FRONTIER_MODEL_ID",
  "effort": "high",
  "cwd": "/absolute/reviewer-checkout",
  "promptFile": "/absolute/loop/round-1-brief.md",
  "roundId": "round-1"
}
```

Run `node <skill>/scripts/reviewer.mjs REQUEST.json SESSION_DIR --dry-run` to inspect without invoking a model; omit `--dry-run` to execute. Resume using same directory and a new round ID/brief. Changed provider/model/checkout requires a fresh session; effort may change medium ↔ high.

Helper passes stdin/arguments without a shell. Windows uses a native executable or Codex npm JavaScript entry point; optional `cli` specifies either. No visible window; logs stay private.

Codex uses read-only sandbox/never approvals; Claude uses plan mode with no permission prompts and restricted built-ins. Existing policies apply; Claude plan mode isn't an OS security boundary. Denied access means the author supplies evidence or reports a limitation, never adds bypass flags or removes nesting guards.

Use the host's process handle with bounded polls. Read `status.json`/`result.md`: `returned` means response received, not review passed. `active.lock` prevents concurrent turns. After interruption inspect `process.json`, process status and logs before removing a stale lock. Never duplicate a possibly running child. Failed rounds retain evidence and need a new round ID.

A supported separate-task mechanism may replace CLI when explicitly requested and compatible with provider/model. Don't create sidebar tasks merely to implement this skill.

References: [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive), [Claude CLI](https://code.claude.com/docs/en/cli-reference). Installed flags checked 2026-09-09; no fixed model catalog.
