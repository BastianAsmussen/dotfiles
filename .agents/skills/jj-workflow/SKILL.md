---
name: jj-workflow
description: Use for any version-control operation in this repo — committing, branching, reviewing history, or pushing. This repo uses jujutsu (jj) colocated on top of git, never raw git add/commit/branch.
---

# Jujutsu (jj) Workflow

This repo is a **jujutsu repo colocated on top of git**. Both `.jj/` and `.git/`
exist; `jj` owns the editing model, `git` is only the remote transport.
Running `jj` against a git remote always needs a `git fetch` first.

## Mental Model

- The working copy is always a **change** (think: a commit you're still editing).
- Changes are **anonymous by default** — no branch name required. Bookmarks
  (`jj bookmark`) are optional labels, the analog of git branches.
- The `master` bookmark tracks the git `master` branch. `@` is the working copy.
- Editing is non-linear and undoable: the commit you're editing is the working
  copy; `jj` keeps an operation log so almost everything is reversible.

## Core Commands

```sh
jj st                  # status: working-copy changes + parent/child info
jj log                 # history (this repo sets default-command = "log")
jj log -r '@ | @-'     # just the working copy and its parent
jj describe -m "msg"   # set the working copy's description (the "commit message")
jj new                 # start a new change on top of the current one
jj new @-              # start a new change *below* the current one (for stacking)
jj squash              # fold the working copy into its parent (amend)
jj diff                # show working-copy diff
jj bookmark list       # list bookmarks (the git branches)
```

The working copy already exists after a fresh clone — there is nothing to
"init" and no "uncommitted" limbo; every edit lives in `@` until you `jj new`.

## The Task Loop

1. Make changes (files, edits). They accumulate in `@` (the working copy).
2. `jj st` to review; `jj diff` to see the patch.
3. `jj describe -m "scope: summary"` to name it. This repo uses conventional
   prefixes seen in history, e.g. `docs(todo):`, `feat(...):`, `fix(...):`.
4. `jj new` to start the next piece of work. The previous change is now frozen
   (but still editable — just `jj edit <rev>` to revisit it).
5. To amend instead of stacking, stay on `@` and `jj squash` into the parent.

## Rewriting / Undo

```sh
jj edit <rev>          # make an old change the working copy again to edit it
jj undo                # undo the last operation (jj's op log, not git reflog)
jj restore --from <r>  # restore files from another revision
jj abandon <rev>       # drop a change entirely
```

`jj undo` is the primary safety net — it reverses *any* jj operation,
including a bad `squash`, `describe`, or `abandon`.

## Pushing / Pulling (the git boundary)

jj has no remote transport of its own; `git` handles the network:

```sh
git fetch origin                # fetch latest (always before pushing)
git push origin master          # push the master bookmark's commit
```

What `git push origin master` pushes is whatever commit the `master` bookmark
points at. If your work is a child of `master` (not yet squashed in), it will
**not** be pushed until you move the bookmark or squash down to it:

```sh
jj squash                      # fold @ into parent
jj bookmark move master --to @ # move master onto the working copy
git push origin master
```

Because `sign-on-push = true` and a GPG backend is configured
(key `0xD92D668B77A29897`), pushes are GPG-signed. jj writes a
`Change-Id:` header into commit messages (`write-change-id-header = true`);
keep it when editing descriptions.

## Colocated Git Rules (Never Do These)

- **Never `git add` / `git commit`** — jj manages the index and commits. A
  raw `git commit` desynchronizes `.jj/` from `.git/`.
- **Never `git checkout` / `git branch`** — use `jj edit` / `jj bookmark`.
- **Never `git merge` / `git rebase`** — use `jj` operations.
- `git status` is safe to *read* (it mirrors the colocated index), but
  `git reset --hard` and friends will destroy jj's working-copy state.

## Gitignore Note

`.jj/.gitignore` contains `/*`, which hides jj's internal store from git.
Never commit anything under `.jj/`; it is entirely jj's own state.

## Colocated-Specific Quirks

- On a fresh `git clone` there is no `.jj/` yet; run `jj git init` to create
  the colocated repo. This repo already has it — no action needed here.
- `jj git import` / `jj git export` are automatic in colocated mode; no manual
  sync step is required for normal edits.
- `jj log` may show changes with no bookmark. That's normal — bookmarks are
  only pinned at the `master` tip here.

## Config Sources

Repo is `jj 0.44.0`; effective settings come from `~/.config/jj/config.toml`
plus any repo override. The user is `Bastian Asmussen <bastian@asmussen.tech>`,
signing backend `gpg`, key `0xD92D668B77A29897`, and
`ui.default-command = "log"` (so a bare `jj` shows the log).
