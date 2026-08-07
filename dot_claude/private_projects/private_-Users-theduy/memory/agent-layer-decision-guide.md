---
name: agent-layer-decision-guide
description: "Decision guide for placing an agent on the LangGraph/LangChain/Deep Agents stack — artifact URL, source HTML, and how theduy's own systems map onto it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: faa5e92e-67ac-4f52-8d85-e87e80a241e7
  modified: 2026-08-07T07:16:58.383Z
---

Companion slide 5 to the four-slide deck "Deep Agents vs LangChain vs LangGraph"
(Sydney Runkle, LangChain). Written 2026-08-06.

- **Artifact (private, updatable):** https://claude.ai/code/artifact/9fec3e89-a9d9-4f77-ac7d-02f6541514c5
- **Source HTML:** `~/tasks/which-layer-your-agent-belongs-on.html` — republish that same
  path with the Artifact tool to update in place; from another conversation pass the URL
  as `url` or a new artifact gets minted.
- Source deck images were in the job dir (`~/.claude/jobs/faa5e92e/`) and do not survive
  job deletion; the artifact is the durable copy.

**The procedure — ask in order, first yes wins:**
1. Can you draw the whole flow before seeing the input? → LangGraph (value is in topology).
2. Does one run outgrow one context window? → Deep Agents (filesystem/subagents/memory).
3. Must you account for every token reaching the model? → LangChain `create_agent`.
4. Should it improve at this job over time? → Deep Agents. Else bare loop.
All no / unknown → default to Deep Agents, drop down when something forces you.

**Sharpest tell:** a prompt containing "always do X before Y" is topology written as a
wish — the model re-decides it each run. Put it in a graph edge or middleware hook.
Inverse: a graph node with a dozen tools and a self-edge is a hand-rolled agent loop.

**Mapping onto this user's systems (from CLAUDE.md + memory, 2026-08-06):**
- `/s-auto` = LangGraph-shaped spine (fixed S2→S5 order, 5 halt conditions, `.s-run`
  resume file) with Deep-Agent nodes. See [[plugin-routing-priorities]], [[s-star-pipeline-guide]].
- Lesson-store recall (`bun recall.ts`, ranks + caps at 7) is correctly a **fixed step**,
  not an LLM decision. See [[graph-engineering-lesson-store]].
- Hermes/Wylios persona fleet = pure Deep Agents (per-persona memory, ambient triggers).
  See [[hermes-platform-topology]].
- `salonx-engineer` off-box = deterministic CI pipeline, one agentic build node.
  See [[gsd-offbox-pipeline]].

**Reframe worth keeping:** Claude Code *is* the harness layer (Deep Agents was inspired by
it). So "should I use `deepagents`?" reduces to "does this agent need to run outside a
Claude Code session?"
