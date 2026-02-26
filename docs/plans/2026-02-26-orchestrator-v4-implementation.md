# Orchestrator Plugin v4.0 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade orchestrator-dev plugin to v4.0 with Orchestrator-First pattern, smart classification, fast mode, and better progress indicators.

**Architecture:** Redesign orchestrator.md as the "default brain" that receives all requests, uses LLM-based intent classification (not keyword matching), and routes to appropriate pipelines with optimized fast mode for small tasks.

**Tech Stack:** Markdown agent definitions, Python hooks, Bash scripts, MCP servers (serena, memory, filesystem)

---

## Task 1: Update orchestrator.md - Orchestrator-First Pattern

**Files:**
- Modify: `orchestrator-dev/agents/orchestrator.md`

**Step 1: Add Orchestrator-First section at the top**

Add after the `## Identity` section:

```markdown
## Orchestrator-First Pattern

### Core Principle
YOU are the default brain. ALL user requests come to YOU first.

### First Action on ANY Request
1. Analyze the user's intent (use LLM reasoning, NOT keyword matching)
2. Classify into pipeline: TRIVIAL | STANDARD | FULL_SDLC | EXPLORE | REVIEW | SECURITY | DOCS
3. For FULL_SDLC only → ask user confirmation
4. For all others → execute immediately

### Intent Classification (LLM-Based)

Analyze the request holistically:
- What is the user trying to accomplish?
- What is the scope and complexity?
- What resources are involved?

Then classify:

| Signal | Pipeline |
|---|---|
| typo, config change, obvious fix <20 lines | **TRIVIAL** |
| bug fix, crash, single-domain change, refactor | **STANDARD** |
| "explain", "what does", "analyze", "explore" | **EXPLORE** |
| "review", "audit", "inspect this code" | **REVIEW** |
| "security scan", "check vulnerabilities" | **SECURITY** |
| "write docs", "update documentation" | **DOCS** |
| new feature, architecture change, breaking change | **FULL_SDLC** |

### Confirm for FULL_SDLC Only
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 This task requires FULL SDLC pipeline:
   PM → SA → Dev → QA ∥ Security → Docs → Commit

   Includes checkpoints at PM and SA phases.

   Proceed? (yes / use STANDARD instead / cancel)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

**Step 2: Update TRIVIAL pipeline for Fast Mode**

Replace the existing TRIVIAL section with:

```markdown
### TRIVIAL (Fast Mode)
```
→ Show progress indicator
→ state.md (step: DEV, status: RUNNING)
→ implement directly
→ ide:getDiagnostics (must=0)
→ Basic DoD check (errors only)
→ state.md (status: COMPLETE)
→ Show completion progress
```

Skip: QA, Security, Memory save, Full DoD
```

**Step 3: Add Progress Indicator section**

Add after `## Checkpoint Format`:

```markdown
## Progress Indicator

Show at START of task:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TASK: [concise task description]
📊 PIPELINE: [TRIVIAL|STANDARD|FULL_SDLC|...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Show after each step:
```
[✅] PM    — Spec complete (3 requirements defined)
[✅] SA    — Plan complete (2 files to modify)
[🔄] DEV   — Editing user.service.ts (1/3 changes)
[⏳] QA    — Waiting
[⏳] SEC   — Waiting
```

Status icons:
- ✅ Complete
- 🔄 In Progress
- ⏳ Waiting
- ⏭️ Skipped (TRIVIAL)
- ❌ Failed
- ⛔ Blocked

Show at END:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TASK COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pipeline: [pipeline]
Duration: [steps completed]
Files: [list of modified files]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
```

**Step 4: Commit**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git add orchestrator-dev/agents/orchestrator.md
git commit -m "feat(orchestrator): add orchestrator-first pattern with smart classify and progress indicators"
```

---

## Task 2: Update session-start.sh - Enhanced Auto-Resume

**Files:**
- Modify: `orchestrator-dev/hooks/scripts/session-start.sh`

**Step 1: Enhance interrupted session prompt**

Replace lines 27-36 with enhanced version:

```bash
      INTERRUPTED="⚠️  INTERRUPTED SESSION DETECTED
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 Pipeline:      $PIPELINE
  📍 Interrupted:   $STEP — $SUBSTEP
  📊 Status:        $STATUS
  📁 Files:         $FILES
  ✅ QA Result:     $QA (attempt $QA_ATT/3)
  🔒 SEC Result:    $SEC (attempt $SEC_ATT/2)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Options:
    • yes         → Resume from interrupted step
    • start fresh → Reset state.md + clear snapshots
    • show        → Read full state + reports
    • rollback    → Restore all snapshots first
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Step 2: Update CONTEXT to include Orchestrator-First**

Replace the CONTEXT variable (lines 41-87) with:

```bash
CONTEXT=$(cat <<EOF
## orchestrator-dev v4.0 Active — ORCHESTRATOR-FIRST

${INTERRUPTED}

### 🎯 ORCHESTRATOR-FIRST PATTERN
ALL requests → Orchestrator analyzes intent → routes to pipeline
You do NOT respond directly to codebase tasks. Delegate to orchestrator.

### TOOL PRIORITY (enforced)
mcp_server > skills > built-in

### Smart Classification
TRIVIAL    → <20 lines, obvious → Fast mode (skip QA/SEC)
STANDARD   → bug fix, refactor → SA → Dev → QA ∥ Security
FULL_SDLC  → new feature → PM →[✋]→ SA →[✋]→ Dev → QA ∥ Security → Docs
EXPLORE    → analyze, explain → SA only
REVIEW     → code review → QA + Security only
SECURITY   → security scan → Security only
DOCS       → documentation → Docs only

### Session Init (run now)
1. mcp__serena__prepare_for_new_conversation (skip gracefully if no project)
2. mcp__memory__search_nodes ← recall ALL project context
3. If interrupted session → ask user: Resume?

### Progress Indicator
Show progress bar at start and after each step:
[✅] PM  [✅] SA  [🔄] DEV  [⏳] QA  [⏳] SEC
EOF
)
```

**Step 3: Commit**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git add orchestrator-dev/hooks/scripts/session-start.sh
git commit -m "feat(hooks): enhance auto-resume prompt and orchestrator-first context"
```

---

## Task 3: Simplify prompt-guard.py

**Files:**
- Modify: `orchestrator-dev/hooks/scripts/prompt-guard.py`

**Step 1: Simplify to just remind about Orchestrator-First**

Replace the entire file content with:

```python
#!/usr/bin/env python3
"""
UserPromptSubmit Hook — prompt-guard.py v4.0
Simple reminder: Orchestrator-First pattern
"""
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

prompt = data.get("prompt", "").strip().lower()

# Skip trivial responses
TRIVIAL = {"hi", "hello", "thanks", "ok", "yes", "no", "sure", "okay"}
if prompt in TRIVIAL or len(prompt) < 5:
    sys.exit(0)

# Skip if already invoking orchestrator
ORCHESTRATOR_INVOKE = [
    "task(subagent",
    "subagent=",
    "orchestrator",
    "/agents"
]
if any(kw in prompt for kw in ORCHESTRATOR_INVOKE):
    sys.exit(0)

REMINDER = (
    "🎯 ORCHESTRATOR-FIRST (v4.0)\n"
    "You are the orchestrator. Analyze intent → classify pipeline → execute.\n\n"
    "Classification: TRIVIAL | STANDARD | FULL_SDLC | EXPLORE | REVIEW | SECURITY | DOCS\n"
    "FULL_SDLC only → ask confirm first.\n\n"
    "Show progress indicator. Update state.md after each step."
)

output = {
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": REMINDER
    }
}
print(json.dumps(output))
sys.exit(0)
```

**Step 2: Commit**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git add orchestrator-dev/hooks/scripts/prompt-guard.py
git commit -m "refactor(hooks): simplify prompt-guard for orchestrator-first pattern"
```

---

## Task 4: Update state.md format

**Files:**
- Modify: `orchestrator-dev/agents/orchestrator.md` (State File section)

**Step 1: Update State File section**

Replace lines 42-59 with:

```markdown
## State File (.claude/team/state.md)

Orchestrator writes before AND after EVERY step.
Dev updates substep + files_modified per edit.

```markdown
# Pipeline State
task: "[concise task description]"
pipeline: TRIVIAL|STANDARD|FULL_SDLC|EXPLORE|REVIEW|SECURITY|DOCS
step: PM|SA|DEV|QA_SECURITY|DOCS|COMPLETE
substep: "3/7 — replacing getUserById in user.service.ts"
status: RUNNING|WAITING_CONFIRM|QA_FAIL|SECURITY_FAIL|BLOCKED|COMPLETE
files_modified: src/api/user.ts, src/service/user.ts
snapshots_dir: .claude/team/snapshots/
diagnostics_last: PASS|FAIL|unknown
qa_result: pending|PASS|SKIP
security_result: pending|PASS|SKIP
qa_attempts: 0
security_attempts: 0
dod_check: pending|PASS|BASIC|FULL
last_updated: 2024-01-15T10:30:00
```

### Changes from v3:
- Added `task` field for progress display
- `qa_result`/`security_result` can be SKIP for TRIVIAL
- `dod_check` can be BASIC (TRIVIAL) or FULL (STANDARD+)

On COMPLETE → keep as audit trail. Never delete.
```

**Step 2: Commit**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git add orchestrator-dev/agents/orchestrator.md
git commit -m "feat(orchestrator): update state.md format with task field and SKIP support"
```

---

## Task 5: Update README.md

**Files:**
- Modify: `orchestrator-dev-marketplace/README.md`

**Step 1: Add v4.0 features section**

Add after the existing description:

```markdown
## v4.0 Features (2026-02-26)

### Orchestrator-First Pattern
- ALL requests go to orchestrator first
- LLM-based intent classification (not keyword matching)
- Smart routing to appropriate pipeline

### Fast Mode
- TRIVIAL pipeline skips QA, Security, full DoD
- Optimized for small tasks (<20 lines)

### Progress Indicators
- Visual progress bar for all pipelines
- Clear status icons: ✅ 🔄 ⏳ ⏭️ ❌ ⛔

### Auto-Resume
- Enhanced interrupted session detection
- Clear options: resume / start fresh / show / rollback
```

**Step 2: Update version references**

Replace all `v3.0` or `v3.1` with `v4.0`

**Step 3: Commit**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git add README.md
git commit -m "docs: update README for v4.0 with new features"
```

---

## Task 6: Final Commit and Tag

**Step 1: Review all changes**

```bash
cd /Users/tanaphat.oiu/.claude/orchestrator-dev-marketplace
git status
git log --oneline -5
```

**Step 2: Create version tag**

```bash
git tag -a v4.0 -m "Orchestrator v4.0: Orchestrator-First pattern, smart classify, fast mode, progress indicators"
```

---

## Summary

| Task | Description | Files Modified |
|------|-------------|----------------|
| 1 | Orchestrator-First pattern | orchestrator.md |
| 2 | Enhanced auto-resume | session-start.sh |
| 3 | Simplified prompt-guard | prompt-guard.py |
| 4 | Updated state.md format | orchestrator.md |
| 5 | Updated README | README.md |
| 6 | Final commit and tag | - |

---

## Testing Checklist

After implementation, test with:

1. **TRIVIAL task**: "fix typo in README" → should execute fast, skip QA/SEC
2. **STANDARD task**: "fix bug in ESCFMail.java" → should run SA → Dev → QA ∥ Security
3. **FULL_SDLC task**: "add new email provider integration" → should ask confirm first
4. **EXPLORE task**: "explain how SMTP works" → should run SA only
5. **Interrupted session**: Kill mid-task, restart → should show auto-resume prompt
