---
name: babysit-pr
description: Babysit existing PRs through independent cross-provider review, feedback fixes, CI and mergeability checks, and re-review until ready for the user. Use for requests like "babysit PR", "babysit this PR", "shepherd these PRs", or "review and fix these PRs". Infer PRs from the session or current branch. Do not start merely because a PR was created.
---

# Babysit PR

Use `$babysit-pr`, `/babysit-pr`, or “babysit these PRs.” Accept PR URLs/numbers or infer them from this session/current branch. Include related backend/UI PRs in one coordinated review. Clarify only ambiguous scope. Review-only or CI-only requests stay within that narrower scope.

The author coordinates and makes code/PR changes. A separate reviewer checks the work, preferably using the other provider. No recursive babysitters or competing code writers.

## Start

1. Read user instructions and repository guidance. A request to babysit covers PR comments, scoped fixes, normal commits/pushes and CI rechecks. It does not authorize merging, deployment, force-push, unrelated changes or messaging outside the PRs. Model-triggered selection without a user request adds no authorization.
2. Read current PR heads/bases, published feedback, checks and mergeability. Resume existing local state/comment markers rather than duplicating a loop. Stop on merged/closed PRs and report their actual state without claiming unverified fixes passed. Reconcile running children before stopping or replacing them.
3. Prepare isolated reviewer checkouts of exact heads; preserve the author's uncommitted work. Fetch remote metadata and supply requirements, companion contracts and validation evidence. Label author claims as claims, not reviewer conclusions.
4. Read [protocol.md](references/protocol.md) for state, comments and completion, and [cli.md](references/cli.md) to launch/resume the reviewer. Record jobs before waiting; keep state outside tracked source.

## Reviewer selection

Honor explicit choices; otherwise Claude authors use Codex reviewers and Codex authors use Claude reviewers. Resolve an available frontier model from the installed CLI/account or current official documentation. Don't guess IDs from display labels or silently substitute a cheaper model/provider. Record provider/model/effort and any fallback.

Pass **medium** for bounded work or small re-reviews; **high** for cross-service behavior, concurrency, payments, authorization, migrations or subtle state changes. Never default to low or ultra/max/xhigh. The helper accepts medium/high; an explicit user override requires adapting it. Report access/model failures and batch necessary fallback decisions.

## Work the loop

- Read published feedback: human comments, source threads, submitted reviews and relevant bots. Fetch compact fields and paginate fully. Skip unchanged/resolved history except our own items awaiting verification. Verify bot claims against code. Reject or flag suggestions beyond the user's original goal.
- Independent review targets important functional regressions and cross-PR compatibility, including rollout order. Each finding needs a stable ID, severity P0–P3, certainty with rationale, PR/file/current diff line, trigger and impact. Report tests actually run and limitations.
- Post one maintained, attributed summary per PR and source comments per finding. Address valid feedback, test, commit and push. Explain false positives/disagreements with technical evidence. Resolve factual questions between agents; batch user decisions about behavior, tradeoffs or authorization. Reviewer verification is required even if the author already closed the thread.
- **CI:** inspect failed-job logs on the current head. Fix failures caused by this PR. For transient infrastructure/flaky failures, rerun only failed jobs, at most three attempts per head/failure signature; record attempts. Don't rerun a head an agreed fix will replace. Never weaken checks or change unrelated code to obtain green CI. Escalate persistent infrastructure or ambiguous failures with evidence.
- **Mergeability:** use the actual target branch, not hardcoded main/master. Integrate the base using repository conventions when required. Resolve clear conflicts preserving both intentions; ambiguous conflicts need a user decision. No destructive abort/reset, rewriting other people's commits or force-push without authorization. Changed heads/bases invalidate review agreement.
- After each push, immediately resume CI/comment monitoring and send fixes, evidence and the ledger to the same reviewer. Re-review fixes and affected contracts; “pushed” is not done. Continue through pending checks/reviews. Stop for a blocker or after three unsuccessful attempts at the same issue without progress, not after three productive rounds.

## Finish

Default finish is **ready for user re-review**: both agents agree on current heads/bases, findings are verified or user-decided, checks pass, mergeability is known, and no known review jobs or user decisions remain. Distinguish missing human approval from failed checks; don't claim merge-ready while host policies block it.

Auto-complete/merge requires user authorization, including any “trivial fixes only” condition. Material changes/edge cases return to the user under that condition. Apply repository merge requirements, including Azure's PR-title/description commit metadata. Agent agreement never replaces required human approval.

When requested, monitor for the specified inactivity period, e.g. 30 minutes since meaningful activity. Otherwise stop at the verified handoff. No indefinite watch or automatic 30-minute wait. Report PR links, reviewed SHAs, fixes/validation, open decisions and next step; interrupted monitoring/exhausted retries are not completion.
