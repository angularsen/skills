---
name: agent-cleanup
description: Inspect and reclaim CPU and memory from leftover AI agent sessions, dev servers, test runners, browser automation, and computer-use helpers. Use when a machine feels hot or slow, or the user asks to clean up agent-related processes.
---

# Agent cleanup

Find what is consuming resources, stop expendable local processes within the user's requested scope, and verify the improvement. Adapt to the host OS using available tools; no extra software is required.

## Inspect

Sample CPU and memory, then inspect the busiest processes and likely session leftovers. Check PID, parent tree, elapsed time, command, working directory, and listening ports as useful. Prioritize runaway dev servers, abandoned test runners, duplicate watchers, and idle automation/browser/computer-use helpers.

Age, a missing parent, or PPID 1 alone does not prove a process is abandoned. Distinguish ongoing agent work and intentional background services from leftovers. Inspect containers individually rather than treating their entire VM as disposable.

On macOS, useful starting points are `ps -axo pid,ppid,%cpu,rss,etime,comm -r`, `top -l 2 -s 3 -n 0`, `memory_pressure`, and targeted `lsof -a -p <pid> -d cwd`. Inspect full commands only where needed; avoid exposing credentials in arguments or environments. Use equivalent native tools on Linux or Windows.

## Clean up

A request to clean up authorizes stopping confidently identified leftovers. If the user says dev servers may be stopped even when in use, honor that scope without asking again. For inspection-only requests, report candidates without stopping them. Ask only about material uncertainty that changes what is safe to stop.

- Preserve the current agent/tool connection, active agent work, editors, user browser sessions, OS services, and shared databases unless the user includes them in scope. Computer-use helpers can be expendable, but first check whether an active task depends on them.
- Target verified PIDs and their relevant descendants, never blanket-kill all Node, Python, dotnet, or browser processes. Account for wrappers or supervisors that may restart children.
- Prefer graceful shutdown, allow it time to finish, and recheck survivors. Force-stop only an identified expendable process that refuses to exit; revalidate its identity before escalating. A zombie has already exited and cannot be freed by killing it again.
- Keep enough local command/path/port information to explain what stopped and how to restart it, without retaining secrets.
- Do not delete worktrees, caches, files, containers, or volumes as part of process cleanup unless requested. Avoid diagnostics that install or initialize tooling: on macOS, even an `xcrun simctl` query can trigger developer-component setup. Skip unavailable tools.

## Verify

Resample after shutdown settles. Check that targets exited and did not respawn; compare CPU and memory using the same measurements. Load averages lag, CPU percentages may be per-core, and unused RAM alone is not memory pressure. Report sampled improvement without implying a proven root cause.

Briefly state what stopped, what needs restarting, the before/after measurements, and any significant remaining load or unexpected side effects. Stop once worthwhile cleanup is complete; do not chase every background process.
