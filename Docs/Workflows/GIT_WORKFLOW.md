# Git Workflow and Rollback

## Repository

- root: `F:/BrokenStreets`;
- remote: `https://github.com/moparmads/BrokenStreets.git`;
- default branch: `main`;
- repository: private;
- Git LFS: required for `.uasset` and `.umap`.

## Per-task flow

1. Check branch, `git status`, and base commit.
2. Stop and explain any unknown or overlapping changes.
3. Update the task packet to `Ready`.
4. Create a branch:
   - `feature/BS-###-short-name`;
   - `fix/BS-###-short-name`;
   - `docs/BS-###-short-name`.
5. Acquire an LFS lock before opening or editing any binary asset.
6. Make small, in-scope changes.
7. Inspect working tree and index separately: `git status --short --branch`, `git diff HEAD`, `git diff --cached --name-status`, `git diff --cached --check`, generated files, and `git lfs status`.
8. Create an atomic candidate commit on the branch. Its existence does not imply acceptance.
9. Run proportional checks on the exact candidate commit/tree. Madalin compiles and playtests when required. A fix creates a new candidate and invalidates old evidence for affected runtime files.
10. Update task, status, and evidence. A later documentation-only evidence commit may reference the candidate but must not change C++, Config, Content, `.uproject`, plugins, or build scripts.
11. Push the branch, review and merge into `main`, then push `main`.
12. Confirm local and remote `main` match, LFS objects are remote, and the working tree is clean. Release binary locks only after confirmation.

## Commit messages

Recommended format:

```text
docs: establish BS-008 project memory
feat: add BS-014 stable identifiers
fix: prevent duplicate BS-043 transactions
test: cover BS-024 profile recovery
chore: pin BS-009 build toolchain
```

Describe the result, never a vague activity such as “updates.” Include the task ID when it improves traceability.

## Binary assets

- `.uasset` and `.umap` must be LFS pointers.
- Never edit one binary asset concurrently on two branches.
- Close the Editor before rollback or revert of a loaded asset.
- Before editing: run `git lfs locks`, then `git lfs lock "Content/path/Asset.uasset"`. If the lock is absent, fails, or belongs to someone else, do not edit the asset.
- After staging: inspect attributes, `git lfs status`, and `git lfs ls-files`. Verify every staged blob from the index, not the smudged working-tree file: `git show ':Content/path/Asset.uasset' | git lfs pointer --check --stdin`. Any nonzero exit blocks the commit. After the candidate commit, run `git lfs fsck --pointers HEAD`.
- Before push: `git lfs push --dry-run origin HEAD` lists pending objects. After push, verify the remote and lock owner.
- After confirmed merge and push: `git lfs unlock "Content/path/Asset.uasset"`. Never use `--force` without explicit approval and a documented cause.
- Do not move or rename assets in File Explorer. Use Unreal Editor and fix redirectors in an explicit task.

BS-007B exercises the first controlled lock, pointer, push, and unlock workflow. Until then, `.gitattributes` alone does not prove the complete process.

## Candidate-bound evidence

The task packet records at least:

- candidate commit hash and, when a merge adds only metadata, the verified runtime/content tree;
- exact commands and tests, target, and build configuration;
- executor, engine, hardware, and topology;
- every runtime file changed after testing, which marks evidence `INVALIDATED` until rerun.

`git diff` without arguments sees only unstaged changes. Delivery audits use `git diff HEAD` and explicitly inspect the index; otherwise a fully staged task can look falsely empty.

## Prohibitions

- no `git reset --hard`;
- no force push to `main`;
- no destructive checkout or restore over user work;
- no automatic stash that hides unknown changes;
- no rushed LFS history rewrite;
- no secrets, Saved, Intermediate, Binaries, cache, or Source Art in commits.

## Rollback

For an accepted and pushed change:

1. identify the exact commit;
2. inspect save, asset, and migration impact;
3. create `fix/BS-###-rollback-*` when nontrivial;
4. use `git revert` for public history;
5. rebuild, test, and restore after revert;
6. update STATUS and ADR/system documents when the decision changes.

A code revert does not guarantee compatibility with a save or asset written by the newer version. Write the rollback plan before any schema change.

## Tags

Create tags only for:

- an important recoverable baseline;
- a vertical-slice gate;
- release candidate or release;
- a major save-migration checkpoint.

Do not tag every task.
