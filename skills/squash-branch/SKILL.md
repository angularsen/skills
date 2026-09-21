---
name: squash-branch
description: Checkpoint a feature branch, merge the latest default branch, and squash to one recoverable commit, including changed submodule branches and authorized force-with-lease publication. Use for "squash this branch", "merge latest main and squash", or "clean up this branch before review".
---

# Squash branch

Produce one feature commit atop the fetched base, preserving the verified merged tree and named recovery refs. Honor review-before-publish and local-only requests.

## Prepare

- Read repository instructions; inspect status, branch, upstream, remotes, worktrees and initialized submodules. Do not interrupt an existing merge/rebase or rewrite a branch used by another worktree. Identify dependent feature branches and report any coordination needed; do not rewrite them implicitly.
- Identify the base remote (e.g. `upstream` for a fork) separately from the push remote. Discover its default with `git ls-remote --symref <remote> HEAD`; use another base only when requested. Consult host metadata/protection if the default is unclear, and stop if still ambiguous. Otherwise skip routine host-protection API checks.
- Never rewrite the default/base, a known protected branch, or `main`, `master`, `trunk`, `develop`, `development`, `maintenance`, `support`, `hotfix`, `release` or their `/*` descendants. Add repository-specific protected conventions. Never bypass a protection rejection; server enforcement is not guaranteed for credentials with bypass rights.
- Commit intended changes using repository conventions, excluding secrets/generated artifacts. Preserve unrelated work separately (e.g. a named stash recorded for recovery) so integration runs clean; restore it afterward without discarding conflicts. Record original HEAD and checkpoint SHA; create a unique `backup/<feature>-<timestamp>-before-merge` ref without overwriting existing backups.
- Treat changed submodules as separate repositories, deepest-first. Checkpoint, integrate and squash their feature branches too, before recording final parent gitlinks. For detached or protected-branch work, preserve the commit and use a dedicated feature branch; leave unchanged third-party submodules alone.

## Integrate and squash

1. Fetch and pin base and remote feature SHAs in each participating repository. Ensure the remote feature tip is contained in the checkpoint; integrate others' work first if necessary.
2. Merge the pinned base, resolve conflicts and commit. For gitlink conflicts, the chosen submodule commit must include the parent's required revision. Distinguish a moved gitlink from dirty submodule work; never stage an old checkout accidentally.
3. Review automatic merges and run relevant checks. Restore dependencies after package changes. If recursive fetch fails on an unrelated object, verify the exact required refs/objects before continuing and report the limitation.
4. Save the verified merge under a unique `backup/<feature>-<timestamp>-merged` ref. With a clean working tree and no operation in progress:

```bash
git reset --soft <pinned-base-sha>
git diff --cached --stat
git commit
```

Use a message describing the whole feature and preserve contributor credit under repository conventions. Verify `HEAD^` equals the pinned base, `<base>..HEAD` contains exactly one commit, `git rev-parse HEAD^{tree}` equals `git rev-parse <merged-backup>^{tree}`, and participating working trees are clean. No hard reset or cleanup is needed. If the base advances, integrate and verify again before claiming the result is current.

## Publish and hand off

Publish only when authorized. Push submodules before parents, keeping LFS hooks enabled. Recheck destination branch, default/base and protected-name rules, and clean status. Use the recorded remote SHA as an explicit lease:

```bash
git push --force-with-lease=refs/heads/<feature>:<expected-remote-sha> <remote> HEAD:refs/heads/<feature>
```

For a new branch, use an empty expected value. Never use plain `--force` or an implicit destination. On lease failure, inspect and integrate incoming work; do not blindly refresh the lease. Verify remote/local HEAD equality and upstream configuration. Report partial publication if a later parent push fails.

Report each repository's branch, original/checkpoint/merged/final/base SHAs, backup refs, checks and publication status. Keep full SHAs in a local recovery record outside the rewritten commits. Recover via a new branch/worktree at a backup; move the active branch back only when asked, preserving newer work and aligning clean submodules to its gitlinks. Do not automatically force-push a rollback.
