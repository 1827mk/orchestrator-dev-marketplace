#!/bin/bash
# SessionStart Hook — injects orchestrator-dev team context every session
# Covers: routing rules, memory rules, tool priority, enterprise constraints

if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/team"
fi

CONTEXT=$(cat <<'CONTEXT'
## orchestrator-dev v2.0 Active

### CRITICAL: Team Routing
ALWAYS delegate coding tasks to orchestrator:
  Task(subagent="orchestrator", description="[user request]")

Do NOT implement directly. This applies to ALL of:
  code-review | bug-fix | new-feature | refactor | security-scan | documentation | reading/analyzing code

Exception: trivial (<20 lines, obvious fix, no design decision) → implement directly

### Session Init (run now — every session)
1. mcp__serena__prepare_for_new_conversation
2. mcp__memory__search_nodes   ← global memory (NOT serena memory)

### Memory Rules
Global knowledge = mcp__memory__* only:
  mcp__memory__search_nodes       ← ALWAYS before any task
  mcp__memory__open_nodes         ← retrieve specific entities
  mcp__memory__read_graph         ← full knowledge graph
  mcp__memory__create_entities    ← save project entities (ask user first)
  mcp__memory__create_relations   ← save relationships (ask user first)
  mcp__memory__add_observations   ← save decisions (ask user first)

NEVER use mcp__serena__write_memory / read_memory for cross-session knowledge
serena memory = project-scoped onboarding notes only

### Tool Priority: MCP > Built-in (hooks enforce, violations blocked)

Code exploration:
  Never Grep  → mcp__serena__search_for_pattern / find_symbol
  Never Glob  → mcp__serena__find_file / mcp__filesystem__search_files

Code editing:
  Never Edit function/class → mcp__serena__replace_symbol_body
  Never Edit to rename      → mcp__serena__rename_symbol (auto-cascades refs)
  Never Write near symbol   → mcp__serena__insert_after/before_symbol
  Never Edit regex replace  → mcp__serena__replace_content
  After rename/replace: find-refs → fix-all → mcp__ide__getDiagnostics = 0

Reading:
  File structure    → mcp__serena__get_symbols_overview
  Code file         → mcp__serena__read_file
  PDF/DOCX/CSV/HTML → mcp__doc-forge__document_reader
  Excel             → mcp__doc-forge__excel_read
  Multiple files    → mcp__filesystem__read_multiple_files

Web:
  Never WebSearch for URL → mcp__web_reader__webReader (full page) or mcp__fetch__fetch (specific)

Verification (mandatory after every edit):
  mcp__ide__getDiagnostics → must = 0
  mcp__serena__think_about_task_adherence
  mcp__serena__think_about_collected_information
  mcp__serena__think_about_whether_you_are_done

### Enterprise Constraints
security: validate-input-at-boundary | no-secrets-in-logs | owasp-aware | auth-checks-controller+service
multi-tenant: tenant_id every query | no-cross-tenant-leak=critical
data: soft-delete-over-hard | no-select-star | pagination-required
observability: structured-logs(traceId/tenantId/userId/duration) | p99-latency
compliance: audit-trail | pii-handling-aware
db: SELECT only via mcp__dbhub__execute_sql | max 1000 rows | never INSERT/UPDATE/DELETE/DROP

### Team Reports
.claude/team/plan.md | qa-report.md | security-report.md | dev-blocked.md
CONTEXT
)

OUTPUT=$(jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}')

echo "$OUTPUT"
exit 0
