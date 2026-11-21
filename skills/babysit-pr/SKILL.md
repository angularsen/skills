---
name: babysit-pr
description: Babysit existing PRs to completion (squash-merged with their title and description) through comment fixes, independent cross-provider review, CI and mergeability checks, without involving the user except for genuine decisions. Use for requests like "babysit PR", "babysit this PR to completion", "shepherd these PRs", or "review and fix these PRs". Infer PRs from the session or current branch. Do not start merely because a PR was created.
---

# Babysit PR

Use `$babysit-pr`, `/babysit-pr`, or “babysit these PRs.” Accept PR URLs/numbers or infer them from this session/current branch. Include related backend/UI PRs in one coordinated review. Clarify only ambiguous scope. Review-only or CI-only requests stay within that narrower scope.

The author coordinates and makes code/PR changes. A separate reviewer checks the work, preferably using the other provider. No recursive babysitters or competing code writers.

**Babysitting means to completion.** The user hands the PR over and does not want to interact with it again. Drive it to a squash merge ([Finish](#finish)) without asking for approval, re-review or progress check-ins. Involve the user only for a genuine decision or clarification only they can give: product behavior, scope, a tradeoff between valid options, authorization beyond the PR, or a blocker. Stop at a handoff for human review only when the user explicitly asks for one ("babysit until ready for my review", "don't merge").

## Start

1. Read user instructions and repository guidance from the PR head checkout, not another clone. A user request to babysit covers PR comments and replies, scoped fixes, normal commits/pushes, CI rechecks and the final squash merge (auto-complete) once the loop converges. It does not authorize bypassing required human approvals or branch policies, force-push, rewriting others' commits, unrelated changes, manual deployment or messaging outside the PRs. Model-triggered selection without a user request adds no authorization and finishes at a handoff instead of a merge.
2. Read current PR heads/bases, published feedback, checks and mergeability. Resume existing local state/comment markers rather than duplicating a loop. Stop on merged/closed PRs and report their actual state without claiming unverified fixes passed. Reconcile running children before stopping or replacing them.
3. Prepare isolated reviewer checkouts of exact heads; preserve the author's uncommitted work. Fetch remote metadata and supply requirements, companion contracts, the published PR body/attachments and validation evidence. Read [conventions.md](references/conventions.md) to derive the applicable checks from repository guidance. Label author claims as claims, not reviewer conclusions.
4. Read [protocol.md](references/protocol.md) for state, comments and completion, and [cli.md](references/cli.md) to launch/resume the reviewer. Record jobs before waiting; keep state outside tracked source.

## Reviewer selection

Honor explicit choices; otherwise Claude authors use Codex reviewers and Codex authors use Claude reviewers. Resolve an available frontier model from the installed CLI/account or current official documentation. Don't guess IDs from display labels or silently substitute a cheaper model/provider. Record provider/model/effort and any fallback.

Pass **medium** for bounded work or small re-reviews; **high** for cross-service behavior, concurrency, payments, authorization, migrations or subtle state changes. Never default to low or ultra/max/xhigh. The helper accepts medium/high; an explicit user override requires adapting it. Report access/model failures and batch necessary fallback decisions.

## Work the loop

Repeat until converged:

1. **Comments.** Read every open comment and thread. Fix valid ones. When a comment is unclear, ask in a reply on that thread and also tell the user in the agent session, then continue with everything else. The user's own published comments are their instructions: when one conflicts with the handoff brief (e.g. it proposes changing a contract the brief says to keep), it is a user decision. Ask on the thread, finish all independent work, and report it as the blocker.
2. **Review.** Ask the reviewer to review the PR as a whole and, separately, the changes made for newly addressed comments since its last round.
3. **Agree.** Iterate with the reviewer on its findings to reach agreement. The author has the last say: on a remaining technical disagreement, record the reasoning in the ledger and the PR thread and move on, rather than escalating to the user.
4. **Change.** Make the agreed changes, test, commit, push and post replies.

**Converged** means no unaddressed comments and no actionable review feedback. "Close enough" is also converged: only P3 nits or subjective preferences remain, or another round would only churn wording. Record why. A concrete unmet documented convention is not a nit.

- Read published feedback: human comments, source threads, submitted reviews and relevant bots. Fetch compact fields and paginate fully. Skip unchanged/resolved history except our own items awaiting verification. Verify bot claims against code. Reject or flag suggestions beyond the user's original goal.
- Independent review covers functional regressions/cross-PR compatibility **and documented conventions**, including changed API documentation, tests, naming, and the published PR/document surfaces. Report functional and convention verdicts separately. A concrete unmet requirement blocks completion even if P3; avoid subjective style preferences and never instruct the reviewer to skip documented rules. Each finding needs a stable ID, severity P0–P3, certainty with rationale, PR/file/current diff line (or PR-body/document location), trigger and impact; convention findings also cite the rule. Report tests actually run and limitations.
- Post one maintained, attributed summary per PR and source comments per finding. Address valid feedback, test, commit and push. Explain false positives/disagreements with technical evidence. Resolve factual and technical questions between agents; batch the few user decisions about behavior, scope or authorization. Reviewer verification (or a recorded author decision) is required even if the author already closed the thread.
- **CI:** inspect failed-job logs on the current head. Fix failures caused by this PR. For transient infrastructure/flaky failures, rerun only failed jobs, at most three attempts per head/failure signature; record attempts. Don't rerun a head an agreed fix will replace. Never weaken checks or change unrelated code to obtain green CI. Escalate persistent infrastructure or ambiguous failures with evidence.
- **Mergeability:** use the actual target branch, not hardcoded main/master. Integrate a moved base only for conflicts, required policies or overlapping files, using repository conventions. Otherwise record that the host reports the PR mergeable. Resolve clear conflicts preserving both intentions; ambiguous conflicts need a user decision. No destructive abort/reset, rewriting other people's commits or force-push without authorization. Changed heads/bases invalidate review agreement.
- After each push, immediately resume CI/comment monitoring and send fixes, evidence and the ledger to the same reviewer. Re-review fixes and affected contracts; “pushed” is not done. Refresh and re-read the published body when behavior, scope or validation changes. Before editing it, measure the resulting squash message (e.g. `Merged PR <id>: <title>`, blank line, body) against host and repository limits (Azure: 4,000 characters). PR-body/doc/attachment edits also invalidate the affected convention verdict even when the head SHA is unchanged. Continue through pending checks/reviews. Stop for a blocker or after three unsuccessful attempts at the same issue without progress, not after three productive rounds.

## Finish

Default finish is **completed**: squash-merged with the PR's own title and description.

1. Gate: both agents agree on current heads/bases and the published review surfaces. Functional and convention findings are fixed, rejected with reasons or user-decided. Required checks pass and the PR is mergeable. No known review jobs or user decisions remain. Re-read the host-stored title/body after the final fix and update them if behavior, scope or validation changed.
2. Merge order: merge companion PRs in their contract/rollout order (e.g. backend before UI). Wait for an earlier PR to merge before completing a dependent one.
3. **Squash, and let the host compose the message.** Use the squash strategy and keep the host's default commit message, which is built from the PR title and description; don't hand-write one. GitHub applies the repository's squash settings when the subject and body are omitted (`gh pr merge --squash`). Azure applies its UI default (`Merged PR <id>: <title>` plus description) only in the UI. Via CLI/API, pass `--squash` and that same message explicitly, read back from the host, before enabling auto-complete or completing. A missing `--squash` produces a `Merge pull request <id> from <branch> into <target>` commit, which is a failed ship. Repository merge rules take precedence.
4. Verify after merge: the target-branch commit's full message contains the title and description, apart from host truncation of long bodies, and the PR reports merged/completed.

If a branch policy requires a human approval vote that is missing, that vote is the one thing to ask for. Agent agreement never replaces it, and never bypass or override policies. When the user asked for a human-review handoff instead, stop at the same gate without merging.

When requested, monitor for the specified inactivity period, e.g. 30 minutes since meaningful activity. Otherwise stop at completion. No indefinite watch or automatic 30-minute wait. Report PR links, merge commit, reviewed SHAs, fixes/validation, author-decided disagreements and any open decisions; interrupted monitoring/exhausted retries are not completion.
