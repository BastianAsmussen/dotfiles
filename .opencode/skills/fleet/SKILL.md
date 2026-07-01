---
name: fleet
description: Use this skill when the user's task decomposes into many independent, parallelizable subtasks — bulk refactors, multi-host changes, or "do all of these" requests. Maximizes throughput by spawning concurrent subagents. Trigger: "fleet mode", "throw a fleet at it", "spawn agents", "parallel", "at once".
metadata:
  when_to_use: fleet mode, throw a fleet, spawn agents, parallelize, many files at once, bulk refactor
---

# Fleet Pattern

When a task breaks down into independent, parallelizable subtasks, spin up a fleet of `task` subagents in a single message. Every subagent call in the same message runs concurrently.

## Decision: fleet vs direct

| Situation | Action |
|-----------|--------|
| 5+ independent file edits | Fleet |
| 3 files, sequential edits (B depends on A) | Direct, no fleet |
| 10 files, trivial one-line edits | Direct (overhead > work) |
| Bulk search across 20+ files | Fleet |
| Single file, 3 distinct changes | Direct |
| Multi-host changes (each independent) | Fleet |
| User says "do all of these", "fleet mode", "parallel", "at once" | Fleet |

**Golden rule:** If the overhead of launching agents outweighs work per item, go direct. If any subtask is trivial, batch it with others to a single subagent rather than giving it its own.

## Before spawning: design the tree

Write out which subtopics go to which agents and how results will aggregate. A one-line sketch per subagent prevents orphans and overlapping scopes.

```
Tree:
 ├── Agent A: search all callers of getCwd
 ├── Agent B: search all callers of setCwd
 └── Agent C: check both against the new API signature
```

## Fleet prompt structure

Each subagent prompt must be self-contained:

1. **Exact task** — what to find, change, or verify
2. **Scope** — specific files, directories, or patterns to operate on
3. **Expected output** — what the subagent should return
4. **Verification** — how the subagent confirms its work (lint, tests, typecheck)

Example:

```
Find all callers of the deprecated function `getCwd` in the project. Search
with grep across the entire repo. Return each file path, line number, and the
surrounding import context. Do NOT edit anything — report only.
```

## Gotchas

- Subagents start fresh on context — they don't know the broader task or what other agents are doing. Every prompt must be fully self-contained with explicit scope boundaries.
- Two agents editing the same file produce merge conflicts. Disjoint scope is mandatory. If there's any ambiguity about which agent owns a file, pre-assign it explicitly.

## Aggregation

After all subagents return, aggregate:

- **Refactors:** Verify no conflicts (two agents edited same file); resolve if any.
- **Research:** Combine findings into a single report grouped by theme.
- **Testing:** If agents ran verification, confirm all passed.

If any subagent failed or found issues, address those before reporting to the user.

## Recursive fleets

Every subagent can launch its own fleet (max depth 3). Include this in each subagent prompt:

```
You are a fleet subagent. If your task can be further decomposed, spawn your own
fleet. Aggregate all children's results before returning.
```

### When to recurse
- A subagent's scope is still too large for one agent
- A subagent discovers new independent subtasks mid-flight
- Bulk work on a directory tree where each subdirectory is self-contained

### Depth limits
- Max depth: 3 (orchestrator → fleet → sub-fleets)
- Each level should reduce scope by at least 10x
- If a leaf scope is still too large, trim scope rather than going deeper

### Tree-aware aggregation

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

Parent aggregates children's results before returning to the orchestrator. Each level strips irrelevant detail.

## Combining with deep-research

- Orchestrator plans (deep-research decomposition)
- Fleet executes parallel exploration
- Orchestrator aggregates and synthesizes
- Orchestrator runs verification

## Limits

- Flat fleet: at most 8-10 subagents per level
- Recursive tree: depth ≤ 3, total leaves ≤ ~1000
- Each subagent should target disjoint files to avoid merge conflicts
- If a subagent's scope is unclear, do a quick search first before spawning
- Subagents start fresh on context — don't assume they know the broader task
