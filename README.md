# orchestrator-dev v2.0

Full AI development team plugin for Claude Code. Converts CLAUDE.md v29 enterprise workflow into a plugin with 5 specialized agents, MCP tool enforcement via hooks, and global memory management.

## Team

| Agent | Role |
|---|---|
| orchestrator | Team lead, classifies and routes all tasks |
| sa | Solution Architect, analyzes codebase and writes plan |
| dev | Developer, implements code per plan |
| qa | QA Engineer, reviews quality and test coverage |
| security | Security Reviewer, scans for vulnerabilities |
| docs | Technical Writer, updates docs and diagrams |

## Flow

```
user task → orchestrator → SA → Dev → QA → Security → Docs → commit-push-pr
                                  ↑____________↓ (fail, max 3x)
                                  ↑_________________↓ (fail, max 2x)
```

## Tool Enforcement (hooks)

| Built-in | Status | Use instead |
|---|---|---|
| Grep | 🚫 blocked | `mcp__serena__search_for_pattern` / `find_symbol` |
| Glob | 🚫 blocked | `mcp__serena__find_file` |
| Edit (symbol) | ⚠️ warned | `mcp__serena__replace_symbol_body` / `rename_symbol` |
| Write | ⚠️ warned | `mcp__serena__create_text_file` |
| WebSearch | ⚠️ warned | `mcp__web_reader__webReader` / `mcp__fetch__fetch` |
| Read | ⚠️ warned | `mcp__serena__get_symbols_overview` / `read_file` |

---

## Install

### Step 1: Download files

Download ทุกไฟล์จาก plugin นี้ไปที่ `~/.claude/orchestrator-dev-marketplace/`

> ⚠️ Claude.ai ไม่รักษา folder structure ตอน download — ไฟล์จะ flat ทั้งหมด ต้อง restructure ด้วย commands ด้านล่าง

### Step 2: Restructure folders

```bash
cd ~/.claude

# สร้าง structure ใหม่
mkdir -p orchestrator-dev-marketplace/.claude-plugin
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/agents
mkdir -p orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts

# ย้ายไฟล์ไปที่ถูกต้อง
mv orchestrator-dev-marketplace/marketplace.json orchestrator-dev-marketplace/.claude-plugin/
mv orchestrator-dev-marketplace/plugin.json      orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin/
mv orchestrator-dev-marketplace/orchestrator.md  orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/sa.md            orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/dev.md           orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/qa.md            orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/security.md      orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/docs.md          orchestrator-dev-marketplace/orchestrator-dev/agents/
mv orchestrator-dev-marketplace/hooks.json       orchestrator-dev-marketplace/orchestrator-dev/hooks/
mv orchestrator-dev-marketplace/tool-guard.py    orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/
mv orchestrator-dev-marketplace/session-start.sh orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/
mv orchestrator-dev-marketplace/README.md        orchestrator-dev-marketplace/

# Set permissions
chmod +x orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/tool-guard.py
chmod +x orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/session-start.sh

# Verify structure
find orchestrator-dev-marketplace -type f | sort
```

Expected output:
```
orchestrator-dev-marketplace/.claude-plugin/marketplace.json
orchestrator-dev-marketplace/README.md
orchestrator-dev-marketplace/orchestrator-dev/.claude-plugin/plugin.json
orchestrator-dev-marketplace/orchestrator-dev/agents/dev.md
orchestrator-dev-marketplace/orchestrator-dev/agents/docs.md
orchestrator-dev-marketplace/orchestrator-dev/agents/orchestrator.md
orchestrator-dev-marketplace/orchestrator-dev/agents/qa.md
orchestrator-dev-marketplace/orchestrator-dev/agents/sa.md
orchestrator-dev-marketplace/orchestrator-dev/agents/security.md
orchestrator-dev-marketplace/orchestrator-dev/hooks/hooks.json
orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/session-start.sh
orchestrator-dev-marketplace/orchestrator-dev/hooks/scripts/tool-guard.py
```

### Step 3: Register marketplace + install plugin

```bash
/plugin marketplace add ~/.claude/orchestrator-dev-marketplace
/plugin install orchestrator-dev@orchestrator-dev-marketplace
```

### Step 4: Verify

```bash
/agents
```

`orchestrator`, `sa`, `dev`, `qa`, `security`, `docs` ต้องปรากฏใน list

### Step 5: Restart Claude Code

Restart เพื่อให้ hooks และ session-start ทำงาน

---

## Usage

```
# Auto-route — พิมพ์ task ตรงๆ
review โค้ดใน src/api/auth.ts
fix bug ที่ payment service crash ตอน timeout
สร้าง feature ใหม่ตาม spec ใน /docs/feature-x.md

# Explicit
Use the orchestrator agent to [task]

# Direct agent
Use the sa agent to analyze /path/to/docs
Use the dev agent to implement .claude/team/plan.md
Use the qa agent to review latest changes
```

## Reports

```bash
cat .claude/team/plan.md            # SA implementation plan
cat .claude/team/qa-report.md       # QA findings
cat .claude/team/security-report.md # Security findings
cat .claude/team/dev-blocked.md     # Dev blocked reason (if any)
```

## Requirements

- Claude Code with plugin support
- `jq` installed: `brew install jq`
- MCP servers: serena, memory, ide, doc-forge, web_reader, fetch, sequentialthinking
- Skills: superpowers, pr-review-toolkit, commit-commands, feature-dev, code-simplifier
# orchestrator-dev-marketplace
