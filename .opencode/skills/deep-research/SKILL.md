---
name: deep-research
description: Use this skill when the user requests in-depth research — investigating complex questions, writing comprehensive reports, or answering queries that require multi-source synthesis across web documentation and codebase exploration. Trigger: "deep research", "thorough research", "write a report", "investigate", "full picture".
metadata:
  when_to_use: deep research, comprehensive report, thorough research, investigate, full picture, multi-source synthesis
---

# Deep Research

Conduct multi-step, autonomous research producing comprehensive, cited reports.

## Phase 0: Plan before executing

Identify gaps in the current session's understanding. Decompose into subtopics: which need web research, which need codebase exploration. Write the decomposition plan before launching any subagents. Trim scope if the plan exposes circular dependencies or wildly asymmetric subtopics.

## Phase 1: Decompose

Break the user's question into 3-8 independent subtopics. Each subtopic:
- Self-contained (can be researched independently)
- Narrow enough for one exploration agent
- Mapped to specific research methods (web fetch, codebase search, or both)

## Phase 2: Competing hypotheses

Before researching, list 2-3 plausible but divergent answers to the user's question. Frame each as a testable hypothesis. During research, track which hypothesis the evidence supports. This prevents anchoring on the first plausible answer.

## Phase 3: Parallel Exploration

For each subtopic, launch an `explore` subagent with:
1. The exact research question
2. Which URLs to fetch (if known) or what to search for
3. Which parts of the codebase to search (if applicable)
4. Expected output format

Every subagent MUST include this instruction:

```
You are a deep-research subagent. Fetch relevant documentation from the web first.
Then search the codebase for how the thing is used in practice. Return a structured
summary with: what it is, why it's here, how it's wired, and which hosts/modules
use it. Cite specific file paths and line numbers.
```

## Phase 4: Refinement with self-critique

After gathering initial results, identify gaps:
- Any subtopic with insufficient detail → launch a focused follow-up agent
- Any contradiction between sources → resolve by fetching primary docs
- Any area where codebase usage differs from docs → note the discrepancy

**Before synthesis, self-critique the interim findings.** Ask:
- What evidence is missing that would disprove the leading hypothesis?
- Are there alternative explanations for the patterns observed in the codebase?
- What confidence level does each finding have (high/medium/low)?

**If research involves changing code, use plan mode first.** Explore, then plan, then implement, then verify.

## Phase 5: Confidence tracking

Tag every major finding with a confidence level:
- **High**: verified against primary docs AND confirmed in the codebase
- **Medium**: verified against one source (docs or codebase, not both)
- **Low**: inferred from context, convention, or third-party sources

If a decision depends on a low-confidence finding, flag it as a risk.

## Phase 6: Synthesis

Aggregate all subagent reports into a single comprehensive report:
- Group related findings thematically
- Include a summary table or matrix at the top
- Cite specific file paths (`path:line`) for code references
- Cite URLs for web sources
- Highlight key architectural insights, cross-references, and gotchas

## Phase 7: Verification

Run at least one verification command (test, lint, or check) before presenting results. Cross-check key claims against primary sources. If the research produced code changes, confirm the build passes.

## Gotchas

- Agents start with fresh context and don't know the broader task. Every subagent prompt must be fully self-contained — include file paths, expected output format, and explicit instructions.
- Web documentation may describe a different version than what's pinned in `flake.lock`. Always cross-reference web claims against the actual pinned revision before treating them as fact.

## Output Format

Every final report:
1. **Executive summary** — 2-3 sentences covering key findings, with leading hypothesis identified
2. **Confidence matrix** — table summarizing confidence per finding
3. **Structured details** — per-topic breakdown with citations
4. **Cross-reference table** — how things relate to each other
5. **Key files index** — where to find things in the codebase

## What NOT to do

- **Don't skip the decompose phase** — a single huge prompt in one subagent produces shallow, scattered results.
- **Don't present unsynthesized raw output** — raw subagent returns go through Phase 6 synthesis.
- **Don't trust web sources without cross-referencing the codebase** — docs can describe a different version than what's pinned.
- **Don't anchor on the first answer** — always maintain and evaluate competing hypotheses.

## Limitations

- Cannot run Python for data analysis (unlike OpenAI's). Use bash for computation.
- Web fetching may be rate-limited. Fall back to cached/knowledge-base information.
- Maximum depth: 3 levels of subagents (orchestrator → fleet → sub-fleets).
- For >10 subtopics, do it in waves of 5-8 parallel agents.

## Tool Selection

| Research Need | opencode Tool |
|---------------|---------------|
| Project README / docs | `webfetch` |
| API reference / schema | `webfetch` |
| How is X used in codebase | `grep` |
| Where is X defined | `glob` |
| Read key files | `read` |
| Sub-agent for parallel work | `task` with `explore` subagent |
| Aggregate findings | Direct synthesis in chat |
