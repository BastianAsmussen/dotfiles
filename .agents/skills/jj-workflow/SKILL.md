---
name: jj-workflow
description: Use for any version-control operation in this repo. Committing, branching, reviewing history, or pushing. This repo uses jujutsu (jj) colocated on top of git, never raw git add/commit/branch.
---

# Jujutsu (jj) Workflow

This repo is a **jujutsu repo colocated on top of git**. Both `.jj/` and `.git/`
exist; `jj` owns the editing model, `git` is only the remote transport.
Running `jj` against a git remote always needs a `git fetch` first.

## Mental Model

- The working copy is always a **change** (think: a commit you're still editing).
- Changes are **anonymous by default**. No branch name required. Bookmarks
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

The working copy already exists after a fresh clone. There is nothing to
"init" and no "uncommitted" limbo; every edit lives in `@` until you `jj new`.

## The Task Loop

1. Make changes (files, edits). They accumulate in `@` (the working copy).
2. `jj st` to review; `jj diff` to see the patch.
3. `jj describe -m "scope: summary"` to name it. This repo uses conventional
   prefixes seen in history, e.g. `docs(todo):`, `feat(...):`, `fix(...):`.
4. `jj new` to start the next piece of work. The previous change is now frozen
   (but still editable; just `jj edit <rev>` to revisit it).
5. To amend instead of stacking, stay on `@` and `jj squash` into the parent.

## Rewriting / Undo

```sh
jj edit <rev>          # make an old change the working copy again to edit it
jj undo                # undo the last operation (jj's op log, not git reflog)
jj restore --from <r>  # restore files from another revision
jj abandon <rev>       # drop a change entirely
```

`jj undo` is the primary safety net. It reverses *any* jj operation,
including a bad `squash`, `describe`, or `abandon`.

## Splitting the Working Copy

Need some paths in their own change while the rest stays put? Use `jj split`.
It is the supported way to divide a change. Do not hand-roll it with
`jj new` plus `jj restore --from @-`: restoring paths from a parent that
lacks them deletes them from the working copy, and `@-` rarely points where
you think it does mid-sequence.

```sh
jj split -m "docs(skills): ..." .agents/skills/
```

Named filesets become the first change (the parent) together with the `-m`
description; the remainder stays in `@` and keeps the old description.
Without filesets, `jj split` opens a diff editor instead.

## Pushing / Pulling (the git boundary)

Fetch via `git fetch`, but **push via `jj git push`, never raw `git push`**.
`jj git push` knows the local↔remote bookmark relationship, refuses to clobber
unrelated remote moves, and handles force-pushes (sideways bookmark moves
after a rewrite) without any `--force` flag — the operation itself is the
consent.

```sh
git fetch origin                        # fetch latest (always before pushing)
jj git push --bookmark master           # push whatever master points at
```

If your work is a child of `master` (not yet squashed in), move the bookmark
before pushing — or squash down first:

```sh
jj bookmark set master -r @-            # move master onto the parent of @
jj git push --bookmark master

# alternative: fold @ into parent, then push
jj squash
jj bookmark move master --to @
jj git push --bookmark master
```

After a rewrite of an already-pushed commit (e.g. `jj split --ignore-immutable`
on a commit reachable from `master`), `jj git push --bookmark master` is still
the right command — it reports the sideways move and force-pushes.
`git push --force` / `--force-with-lease` are not the tool here.

Because `sign-on-push = true` and a GPG backend is configured
(key `0xD92D668B77A29897`), pushes are GPG-signed. jj writes a
`Change-Id:` header into commit messages (`write-change-id-header = true`);
keep it when editing descriptions.

## Colocated Git Rules (Never Do These)

- **Never `git add` / `git commit`**. jj manages the index and commits. A
  raw `git commit` desynchronizes `.jj/` from `.git/`.
- **Never `git checkout` / `git branch`**. Use `jj edit` / `jj bookmark`.
- **Never `git merge` / `git rebase`**. Use `jj` operations.
- **Never `git push` / `git push --force`**. Use `jj git push --bookmark <name>`.
  It handles both fast-forward advances and sideways/force moves.
- `git status` is safe to *read* (it mirrors the colocated index), but
  `git reset --hard` and friends will destroy jj's working-copy state.

## Gitignore Note

`.jj/.gitignore` contains `/*`, which hides jj's internal store from git.
Never commit anything under `.jj/`; it is entirely jj's own state.

## Colocated-Specific Quirks

- On a fresh `git clone` there is no `.jj/` yet; run `jj git init` to create
  the colocated repo. This repo already has it; no action needed here.
- `jj git import` / `jj git export` are automatic in colocated mode; no manual
  sync step is required for normal edits.
- `jj log` may show changes with no bookmark. That's normal; bookmarks are
  only pinned at the `master` tip here.

## Config Sources

Repo is `jj 0.44.0`; effective settings come from `~/.config/jj/config.toml`
plus any repo override. The user is `Bastian Asmussen <bastian@asmussen.tech>`,
signing backend `gpg`, key `0xD92D668B77A29897`, and
`ui.default-command = "log"` (so a bare `jj` shows the log).

## Recovery

`jj abandon` hides a change; nothing is deleted. Hidden commits still resolve
by ID and every past operation is recorded.

```sh
jj op log                       # every operation, with the args used
jj op restore <op-id>           # rewind graph, refs, and working copy
jj obslog -r <change>           # every predecessor version of a change
jj restore --from <id> <paths>  # copy specific paths back onto @
git show <commit-id>:<path>     # read a file straight out of a hidden commit
```

Prefer surgical recovery (`jj restore --from`) over `jj op restore` when only
file content went missing: rewinding the op log also rewinds remote-tracking
refs updated by any fetch since.

## Sharp Edges

- Relative revisions move under you. `@-` names one commit before a
  `jj edit` / `jj new` / `jj abandon` and a different one after. Anything
  destructive gets an explicit change ID or commit ID, never `@-` or `@--`.
- `jj restore --from X <paths>` makes `@` match X for those paths; paths that
  exist in `@` but not in X are deleted. Restoring `modules/` from a commit
  without your new feature module removes the module.
- Commits reachable from `master` are immutable. `jj squash` across that
  boundary fails; stack on top or move the bookmark deliberately.
- `jj rebase` wants `-r <revs> --onto <dest>` on this version; bare
  positional destinations error out.
- The graph can change between sessions (another terminal, another agent).
  Re-check `jj st` and `jj op log` before trusting a remembered state.
