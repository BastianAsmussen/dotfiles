---
name: fleet
description: Parallelize independent subtasks — bulk refactors, multi-host changes, "do all of these". Maximize throughput with concurrent subagents.
metadata:
  when_to_use: fleet mode, throw a fleet, spawn agents, parallelize, many files at once, bulk refactor
---

# Fleet Pattern

When a task breaks into independent, parallelizable subtasks, spin up `task` subagents concurrently in one message.

## Decision matrix

| Situation | Action |
|-----------|--------|
| 5+ independent file edits | Fleet |
| Sequential edits (B depends on A) | Direct |
| 10 files, trivial one-liners | Direct (overhead > work) |
| Bulk search across 20+ files | Fleet |
| Multi-host changes (each independent) | Fleet |
| User says "do all of these", "fleet mode", "parallel", "at once" | Fleet |

**Rule:** If overhead outweighs per-item work, go direct. Batch trivial subtasks to one subagent.

## Before spawning

Sketch the tree — one line per subagent prevents overlap:
```
Tree:
 ├── Agent A: search callers of getCwd
 ├── Agent B: search callers of setCwd
 └── Agent C: check both against new API
```

## Prompt structure

Each subagent prompt must be self-contained:
1. Exact task — what to find, change, verify
2. Scope — specific files, directories, patterns
3. Expected output
4. Verification method

## Gotchas

- Subagents start fresh — no knowledge of broader task. Fully self-contained prompts.
- Two agents editing same file = merge conflicts. Disjoint scope mandatory.

## Aggregation

- **Refactors:** Verify no conflicts; resolve if any.
- **Research:** Combine into one report grouped by theme.
- **Testing:** Confirm all passed.

## Recursive fleets

Subagents can launch their own fleet (max depth 3):
```
Orchestrator
 ├── Subagent A (aggregates A1, A2, A3)
 │     ├── A1 (leaf)
 │     ├── A2 (leaf)
 │     └── A3 (leaf)
 └── Subagent B (aggregates B1, B2)
       ├── B1 (leaf)
       └── B2 (leaf)
```

Parent aggregates children before returning. Each level strips irrelevant detail.

## Deep-research combo

- Orchestrator plans (decomposition)
- Fleet executes parallel exploration
- Orchestrator synthesizes + verifies

## Limits

- Flat fleet: ≤8-10 subagents per level
- Recursive: depth ≤3, total leaves ≤~1000
- Disjoint files only
