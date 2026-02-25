# orchestrator-dev v4.0

Enterprise AI development team plugin for Claude Code.
Full SDLC from requirement to delivery: **PM → SA → Dev → QA ∥ Security → Docs → commit**

---

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

---

## What's New in v3.1
- **Snapshot/Rollback** — Dev snapshots every file before editing. Ctrl+C → rollback available instantly
- **Interrupt recovery** — state.md tracks every step. Session start auto-detects incomplete work
- **Parallel fix loop** — QA + Security fixes run in same Dev pass when independent (faster)
- **Shared Definition of Done** — orchestrator verifies all DoD items before commit (not just agent self-report)
- **Structured Memory Schema** — typed entities (Project/Feature/Decision/Pattern/RecurringBug/VulnPattern) for consistent cross-session recall
- **Self-Improvement Agent** — analyzes recurring patterns from reports, proposes + applies agent instruction improvements with user approval
- **Security pattern priority** — CRITICAL → HIGH → MEDIUM → LOW scan order, stop overwhelm, full coverage

## What's New in v4.0
- **PM agent** — brainstorming → spec before SA touches codebase
- **Adaptive pipelines** — 7 pipeline types, not linear always
- **QA ∥ Security parallel** — run simultaneously
- **Real-time progress** — `[AGENT] emoji action → tool`
- **2 human checkpoints** — after PM spec + after SA plan

---

## Team

| Agent | Role | Model |
|---|---|---|
| orchestrator | classify, route, checkpoint, DoD, parallel dispatch | opus |
| pm | requirement → spec.md | opus |
| sa | codebase analysis → plan.md | opus |
| dev | implement + snapshot/rollback | opus |
| qa | quality + coverage (parallel) | sonnet |
| security | OWASP scan by priority (parallel) | sonnet |
| docs | docs + diagrams | sonnet |
| self-improve | learn from patterns → improve agents | opus |

---

## Pipelines

```
TRIVIAL    → Dev → DoD → done
STANDARD   → SA → Dev → QA ∥ Security → DoD → commit
FULL SDLC  → PM →[✋]→ SA →[✋]→ Dev → QA ∥ Security → Docs → DoD → commit
EXPLORE    → SA (analyze only)
REVIEW     → QA ∥ Security
SECURITY   → Security only
DOCS       → Docs only
```

## Fix Loop (QA + Security)
```
both pass           → proceed
QA only fails       → Dev fix QA → re-run QA
SEC only fails      → Dev fix SEC → re-run SEC
both fail, independent → Dev fix both in one pass → re-run both
both fail, conflicting → fix QA first → fix SEC → re-run both
max: QA=3x, SEC=2x
```

---

## Interrupt Recovery

Every session start checks `.claude/team/state.md`:
```
⚠️  Interrupted session detected
pipeline: FULL_SDLC | interrupted: DEV — 3/7 replacing getUserById
files_modified: src/api/user.ts
snapshots: .claude/team/snapshots/ (rollback available)
→ Resume? (yes / rollback / start fresh / show details)
```

---

## Definition of Done (checked by orchestrator before commit)
```
□ ide:getDiagnostics = 0 errors
□ all tests pass
□ qa_result = PASS
□ security_result = PASS
□ docs updated (FULL SDLC)
□ no TODO/FIXME from this task
□ state.md status = COMPLETE
□ no secrets in modified files
```

---

## Memory Schema

| Entity | Saved by | Fields |
|---|---|---|
| Project | SA (first time) | name, stack, conventions, encoding |
| Feature | PM/orchestrator | name, status, spec_path, plan_path |
| Decision | SA | context, choice, rationale, alternatives |
| Pattern | SA/QA | name, description, example_file |
| TechDebt | QA | description, location, impact |
| RecurringBug | QA (3+ times) | pattern, root_cause, fix |
| VulnPattern | Security | category, pattern, risk, fix |

---

## Self-Improvement

Triggered automatically when recurring patterns detected, or manually:
```bash
Use the self-improve agent to analyze recent patterns and improve the plugin
```

Proposal written to `.claude/team/self-improve-proposal.md` → user approves → applied.

---

## Tool Priority (enforced by hooks)

**mcp_server > skills > built-in**

| Blocked | Use instead |
|---|---|
| Grep | `mcp__serena__search_for_pattern` / `find_symbol` |
| Glob | `mcp__serena__find_file` |

| Warned | Prefer instead |
|---|---|
| Edit (symbol) | `mcp__serena__replace_symbol_body` / `rename_symbol` |
| Write | `mcp__serena__create_text_file` |
| WebSearch | `mcp__web_reader__webReader` / `context7` |
| Read | `mcp__serena__get_symbols_overview` / `doc-forge` |

---

## Install

### Step 1: Download + place files
Download all files to `~/.claude/orchestrator-dev-marketplace/`

### Step 2: Restructure
```bash
cd ~/.claude

mkdir -p orchestrator-dev-marketplace/.claude-plugin
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/agents
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts

mv orchestrator-dev-marketplace/marketplace.json  orchestrator-dev-marketplace/.claude-plugin/
mv orchestrator-dev-marketplace/plugin.json       orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin/
mv orchestrator-dev-marketplace/orchestrator.md   orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/pm.md             orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/sa.md             orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/dev.md            orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/qa.md             orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/security.md       orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/docs.md           orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/self-improve.md   orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/hooks.json        orchestrator-dev-marketplace/orchestrator-dev/hooks/
mv orchestrator-dev-marketplace/tool-guard.py     orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/
mv orchestrator-dev-marketplace/prompt-guard.py   orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/
mv orchestrator-dev-marketplace/session-start.sh  orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/

chmod +x orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/*.py
chmod +x orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/*.sh

find orchestrator-dev-marketplace -type f | sort
```

Expected:
```
orchestrator-dev-marketplace/.claude-plugin/marketplace.json
orchestrator-dev-marketplace/README.md
orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin/plugin.json
orchestrator-dev-marketplace/orchestrator-dev/agents/dev.md
orchestrator-dev-marketplace/orchestrator-dev/agents/docs.md
orchestrator-dev-marketplace/orchestrator-dev/agents/orchestrator.md
orchestrator-dev-marketplace/orchestrator-dev/agents/pm.md
orchestrator-dev-marketplace/orchestrator-dev/agents/qa.md
orchestrator-dev-marketplace/orchestrator-dev/agents/sa.md
orchestrator-dev-marketplace/orchestrator-dev/agents/security.md
orchestrator-dev-marketplace/orchestrator-dev/agents/self-improve.md
orchestrator-dev-marketplace/orchestrator-dev/hooks/hooks.json
orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/prompt-guard.py
orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/session-start.sh
orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/tool-guard.py
```

### Step 3: Register + Install
```bash
/plugin marketplace add ~/.claude/orchestrator-dev-marketplace
/plugin install orchestrator-dev@orchestrator-dev-marketplace
```

### Step 4: Verify
```bash
/agents
# orchestrator, pm, sa, dev, qa, security, docs, self-improve
```

### Step 5: Restart Claude Code

---

## Usage

```bash
# Auto-route
แก้ bug ที่ payment crash ตอน timeout
สร้าง feature OAuth login
review โค้ดใน src/api/auth.ts

# Direct
Use the orchestrator agent to [task]
Use the self-improve agent to analyze recent patterns
```

## Reports
```bash
cat .claude/team/state.md             # pipeline state + interrupt info
cat .claude/team/snapshots/manifest.md # file snapshots for rollback
cat .claude/team/spec.md              # PM spec
cat .claude/team/plan.md              # SA plan
cat .claude/team/qa-report.md         # QA findings
cat .claude/team/security-report.md   # security findings
cat .claude/team/self-improve-proposal.md # improvement proposals
```

## Requirements
- Claude Code with plugin support
- `jq`: `brew install jq`
- MCP: serena, memory, ide, filesystem, doc-forge, web_reader, fetch, sequentialthinking, context7
- Skills: superpowers, pr-review-toolkit, commit-commands, feature-dev, code-simplifier, claude-md-management
