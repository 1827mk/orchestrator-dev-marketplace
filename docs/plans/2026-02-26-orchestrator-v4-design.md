# Orchestrator Plugin v4.0 - Design Document

**Date:** 2026-02-26
**Status:** Approved
**Author:** User + Claude

---

## Overview

Upgrade orchestrator-dev plugin to v4.0 with:
- Orchestrator-First pattern (auto-route all requests)
- Smart intent classification (LLM-based, not keyword matching)
- Fast mode for small tasks
- Better progress indicators
- Auto-resume for interrupted sessions

---

## 1. Orchestrator-First Pattern

### Problem
Current plugin only "suggests" using orchestrator via hooks, but agent can ignore the suggestion.

### Solution
Redesign orchestrator.md to be the "default brain" that receives ALL requests first.

### Flow
```
User request (any format)
       ↓
┌─────────────────────────────────────┐
│   ORCHESTRATOR (Default Brain)      │
│   Analyze intent with LLM           │
│   → NOT keyword matching            │
└─────────────────────────────────────┘
       ↓
   Smart Classify
       ↓
   Route to appropriate pipeline
```

---

## 2. Smart Classify + Confirm on Complex

### Classification Logic (LLM-based)

| Pipeline | Criteria | Action |
|----------|----------|--------|
| TRIVIAL | <20 lines, obvious, config, typo | Execute immediately |
| STANDARD | bug fix, refactor, single-domain | Execute immediately |
| EXPLORE | analyze, explain, "what does this do" | Execute immediately |
| REVIEW | code review, audit, inspect | Execute immediately |
| SECURITY | security scan only | Execute immediately |
| DOCS | documentation only | Execute immediately |
| **FULL_SDLC** | new feature, architecture, breaking change | **Ask confirm first** |

### Confirm Format (for FULL_SDLC only)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 This task requires FULL SDLC pipeline:
   PM → SA → Dev → QA ∥ Security → Docs → Commit

   Includes checkpoints at PM and SA phases.

   Proceed? (yes / use STANDARD instead / cancel)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 3. Fast Mode for Small Tasks

### TRIVIAL Pipeline (Optimized)
```
→ state.md (step: DEV, status: RUNNING)
→ implement directly
→ ide:getDiagnostics (must=0)
→ Basic DoD check (errors only, no QA/Security)
→ state.md (status: COMPLETE)
```

### STANDARD Pipeline (Normal)
```
→ state.md (step: SA, status: RUNNING)
→ Task(subagent="sa")
→ state.md (step: DEV, status: RUNNING)
→ Task(subagent="dev")
→ state.md (step: QA_SECURITY, status: RUNNING)
→ Parallel: QA + Security
→ Fix loop if needed
→ Full DoD check
→ state.md (status: COMPLETE)
→ commit-push-pr
```

### Pipeline Comparison

| Step | TRIVIAL | STANDARD | FULL_SDLC |
|------|---------|----------|-----------|
| PM | Skip | Skip | Yes + Checkpoint |
| SA | Skip | Yes | Yes + Checkpoint |
| DEV | Yes | Yes | Yes |
| QA | Skip | Yes | Yes |
| Security | Skip | Yes | Yes |
| Docs | Skip | Skip | Yes |
| DoD Check | Basic | Full | Full |

---

## 4. Tool Priority (Unchanged)

Keep existing tool-guard.py behavior:

### BLOCK
- `Grep` → use `mcp__serena__search_for_pattern`
- `Glob` → use `mcp__serena__find_file`

### WARN
- `Edit` → prefer `mcp__serena__replace_symbol_body`
- `Write` → prefer `mcp__serena__create_text_file`
- `WebSearch` → prefer `mcp__fetch__fetch` or `mcp__context7__*`
- `Read` → prefer `mcp__serena__read_file` or `mcp__filesystem__read_text_file`

### Priority
```
mcp_server > skills > built-in
```

---

## 5. Auto-Resume Prompt

### Detection
Check `.claude/team/state.md` on session start:
- If `status != COMPLETE` and status exists → interrupted session

### Prompt Format
```
⚠️ INTERRUPTED SESSION DETECTED
─────────────────────────────────
Pipeline:      [pipeline]
Interrupted:   [step] — [substep]
Status:        [status]
Files:         [files_modified]
QA Result:     [qa_result] (attempt [n]/3)
SEC Result:    [security_result] (attempt [n]/2)
─────────────────────────────────
→ Resume from here?
  (yes / start fresh / show details / rollback)
```

---

## 6. Progress Indicator

### Format
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TASK: [task description]
📊 PIPELINE: [TRIVIAL|STANDARD|FULL_SDLC|...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[✅] PM    — [status or skipped]
[✅] SA    — [status or skipped]
[🔄] DEV   — [current action]
[⏳] QA    — [waiting or status]
[⏳] SEC   — [waiting or status]
[⏳] DOCS  — [waiting or skipped]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Status Icons
- `✅` Complete
- `🔄` In Progress
- `⏳` Waiting
- `⏭️` Skipped (for TRIVIAL)
- `❌` Failed
- `⛔` Blocked

### Update Frequency
- Update progress after each major step
- Show in orchestrator responses

---

## 7. Files to Modify

| File | Changes |
|------|---------|
| `orchestrator.md` | Add Orchestrator-First pattern, Smart Classify logic, Progress indicator format |
| `session-start.sh` | Enhance auto-resume prompt format |
| `prompt-guard.py` | Simplify - just remind about orchestrator-first, no complex routing logic |
| `state.md` format | Add progress tracking fields |

---

## 8. Agents (Unchanged)

Keep existing agents:
- orchestrator (enhanced)
- pm
- sa
- dev
- qa
- security
- docs
- self-improve

No subdivision needed.

---

## Success Criteria

1. User can say anything in natural language → orchestrator handles it
2. Small tasks complete faster (TRIVIAL pipeline)
3. Complex tasks ask for confirmation (FULL_SDLC)
4. Progress is always visible
5. Interrupted sessions are easy to resume
6. Tool priority remains enforced (mcp_server > skills > built-in)

---

## Next Steps

1. Update `orchestrator.md` with new logic
2. Update `session-start.sh` for better auto-resume
3. Simplify `prompt-guard.py`
4. Test with various task types
