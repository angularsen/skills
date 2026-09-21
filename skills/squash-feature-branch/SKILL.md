---
name: squash-feature-branch
description: Checkpoint a feature branch, merge the latest default branch, resolve conflicts, and squash to one commit with recoverable history. Use for requests such as "squash this feature branch", "merge latest main and squash", or "clean up this branch before review", including changed submodule branches and safe force-with-lease publication.
---

# Squash a feature branch

Produce one feature commit whose parent is the fetched default-branch commit and whose tree equals the verified merge result. Preserve named recovery refs and report before/after SHAs. Honor a user-requested review or local-only boundary.

## Establish scope and protect shared branches

- Read repository instructions. Inspect status, current branch, upstream, remotes, linked worktrees, and recursively initialized submodules. Do not interrupt an existing merge/rebase or move a branch checked out by another worktree.
- Discover the remote default branch; do not assume `main` or `master`. Verify cached `origin/HEAD` against the host API or `git ls-remote --symref <remote> HEAD`. Use a different base only when requested.
- **Do not rewrite or force-push the default branch, the chosen base branch, a host-protected branch, or a shared maintenance/release branch.** Deny `main`, `master`, `trunk`, `develop`, `development`, and `maintenance`, `support`, `hotfix`, `release` (including their `/*` descendants). Add repository-specific protected names/patterns from instructions, conventions, branch policies and rulesets.
- Check host protection as well as names. GitHub branch protection and active rulesets both matter; Azure DevOps policies require matching repository, exact/prefix branch scope and policy purpose. Repository-wide file-size rules are not a blanket ban on feature rewrites. Do not bypass host protection. If protection cannot be verified, finish safe local preparation and report the publication blocker.
- A request to use this workflow authorizes its local checkpoint/merge/squash steps. Publish with force-with-lease when the user authorizes publishing rewritten history; otherwise hand back the local result. Do not infer production deployment, PR completion or default-branch mutation permission.

## Checkpoint, including submodules

1. Inspect the complete diff and commit the work in scope using repository conventions. If the user says "all changes", include all intended changes, but never blindly stage credentials, ignored data or generated build trees. Preserve unrelated work when scope is narrower.
2. Treat each changed submodule as its own repository. Work deepest-first: commit its changes, then commit the parent pointer. Record repository path, branch, original HEAD, checkpoint SHA and remote feature SHA.
3. Create unique named backup refs at the checkpoints, e.g. `backup/<feature>-<timestamp>-before-main`. Never overwrite an existing backup. A parent gitlink alone does not commit a dirty submodule.
4. When feature work spans submodule branches, integrate and squash those branches too. Apply the same default/protected-branch checks independently. Do not rewrite a submodule on a default/protected branch or detached HEAD; preserve its commit and use a dedicated feature branch when needed. Do not squash unchanged third-party submodules.

## Integrate and verify

- Fetch the base and feature refs for each repository and record exact SHAs. Confirm the fetched remote feature tip is contained in the checkpoint; if others have added work, integrate it before rewriting.
- Merge the pinned base SHA into the feature branch, resolve conflicts by comparing base/ours/theirs, then commit the resolved merge. Keep additions from both sides when compatible; do not blanket-select ours/theirs.
- Resolve submodule pointer conflicts to the intentionally integrated submodule commit, verifying it includes the parent base's required revision. A nested submodule checkout can look dirty solely because its gitlink moved: inspect its own status, preserve any work, then update it to the recorded commit. Do not accidentally stage an old checkout and regress the pointer.
- A fetch error for another branch's missing submodule object does not prove this base failed to fetch. Check the exact refs and required objects. Never claim a complete recursive fetch when it failed.
- Review auto-merged code too: duplicate imports, overlapping helpers and mismatched API routing can compile incorrectly despite no textual conflict. Preserve local environment isolation when combining configuration paths.
- Run relevant repository checks. Restore dependencies when the new base changes package versions; stale restore outputs are not source errors. Update stale tests to exercise the actual user flow rather than deleting assertions. Do not claim tests passed if only builds ran.
- Save the verified merged commit under another unique backup ref, e.g. `backup/<feature>-<timestamp>-merged`.

## Squash without changing the verified tree

With no in-progress operation and no uncommitted work, while still on the feature branch:

```bash
git reset --soft <pinned-base-sha>
git diff --cached --stat
git commit
```

Use a substantive commit message describing the entire resulting feature, not just the final fixes. Soft reset keeps the index and working tree; no hard reset or cleanup is needed.

Verify all of these:

- `git rev-parse HEAD^` equals the pinned base SHA.
- `git rev-list --count <pinned-base-sha>..HEAD` is `1`.
- `git diff --exit-code <merged-backup-ref> HEAD` succeeds, including gitlinks.
- Working trees are clean, including participating submodules.

Finish submodule squashes before recording final parent pointers. If a base moves during the operation, integrate and verify it again before claiming "latest"; do not merely change the squash parent under an unchanged tree.

## Publish with an explicit lease

Publish participating submodules first, then the parent, so every pushed gitlink is resolvable. Leave LFS hooks enabled.

Immediately before publishing, recheck destination remote/branch, protected-name rules, host protection, clean status and the remote feature SHA. Use the recorded remote SHA as an explicit lease:

```bash
git push --force-with-lease=refs/heads/<feature>:<expected-remote-sha> <remote> HEAD:refs/heads/<feature>
```

- Never use plain `--force`, a `+` refspec, `--mirror`, or an implicit push destination.
- If the lease fails, stop publishing that repository. Inspect the newly arrived commits and integrate them; do not refresh the lease and retry blindly.
- For a genuinely new feature branch, use an explicit empty expected value (branch must not already exist).
- Verify remote HEAD equals local HEAD and set the correct upstream if missing. Later ordinary commits should push normally.
- If a later parent push fails after submodules succeeded, retain the published child commits and backups; report precisely which pushes succeeded.

## Handoff and recovery

Report a compact table per rewritten repository: branch, original HEAD, checkpoint before main, merged backup, final squash, base, publication and checks. Keep full SHAs and backup-ref names in a local recovery record that survives reflog expiry. Do not add another feature commit solely to record its own SHA.

Prefer inspecting/recovering via a new branch or worktree at the checkpoint. Only move the active branch back when asked, after saving newer work and checking submodules. Restoring a parent alone does not restore submodule checkouts; align clean submodules to its gitlinks. Do not automatically force-push a rollback.
