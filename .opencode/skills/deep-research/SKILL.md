---
name: deep-research
description: In-depth multi-step autonomous research — investigating complex questions, multi-source synthesis across web docs and codebase.
metadata:
  when_to_use: deep research, comprehensive report, thorough research, investigate, full picture, multi-source synthesis
---

# Deep Research

Conduct multi-step, autonomous research producing comprehensive, cited reports.

## Phase 0: Plan

Identify knowledge gaps. Decompose into subtopics: which need web research, which need codebase exploration. Write the plan before launching subagents.

## Phase 1: Decompose

Break into 3-8 independent subtopics. Each: self-contained, narrow enough for one agent, mapped to web fetch or codebase search.

## Phase 2: Competing hypotheses

List 2-3 plausible but divergent answers before researching. Track which hypothesis evidence supports. Prevents anchoring.

## Phase 3: Parallel exploration

Launch `explore` subagents per subtopic with: exact question, URLs to fetch, codebase areas to search, expected output format. Subagent instruction:
```
You are a deep-research subagent. Fetch relevant documentation from the web first.
Then search the codebase for how the thing is used in practice. Return: what it is,
why it's here, how it's wired, which hosts/modules use it. Cite paths and line numbers.
```

## Phase 4: Refinement with self-critique

Identify gaps → focused follow-up agents. Resolve contradictions via primary docs. Note codebase vs docs discrepancies.
Self-critique: what evidence would disprove the leading hypothesis? Alternative explanations? Confidence per finding?

## Phase 5: Confidence tracking

Tag findings: **High** (verified in docs + codebase), **Medium** (one source), **Low** (inferred). Flag low-confidence dependencies as risks.

## Phase 6: Synthesis

Aggregate into single report: grouped thematically, summary table, path/line citations, URL citations, architectural insights.

## Phase 7: Verification

Run at least one verification command (test, lint, check) before presenting. Cross-check key claims.

## Output format

1. **Executive summary** — 2-3 sentences, leading hypothesis identified
2. **Confidence matrix** — table
3. **Structured details** — per-topic with citations
4. **Cross-reference table**
5. **Key files index**

## Gotchas

- Subagents start fresh. Every prompt must be fully self-contained.
- Web docs may describe different version than pinned in `flake.lock`. Cross-reference.
- If research involves code changes, explore → plan → implement → verify.

## Limitations

- No Python data analysis — use bash.
- Web fetching may be rate-limited. Fall back to cached info.
- Max depth: 3 levels (orchestrator → fleet → sub-fleets).
- >10 subtopics: do in waves of 5-8.

## Tool selection

| Need | Tool |
|------|------|
| Project README / docs | `webfetch` |
| API reference / schema | `webfetch` |
| How X is used in codebase | `grep` |
| Where X is defined | `glob` |
| Read key files | `read` |
| Parallel exploration | `task` with `explore` |
| Aggregate findings | Direct synthesis |
