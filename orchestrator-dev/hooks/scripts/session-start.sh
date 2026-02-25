#!/bin/bash
# SessionStart Hook — injects orchestrator-dev team context every session

# Dependency check
if ! command -v jq >/dev/null 2>&1; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"⚠️ jq not found. Install with: brew install jq — SessionStart hook skipped."}}' 
  exit 0
fi

if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude/team" 2>/dev/null || true
fi

CONTEXT=$(cat <<'CONTEXT'
## orchestrator-dev v2.0 Active

### CRITICAL: Team Routing
ALWAYS delegate coding tasks to orchestrator:
  Task(subagent="orchestrator", description="[user request]")

Do NOT implement directly. Applies to:
  code-review | bug-fix | new-feature | refactor | security-scan | documentation | reading/analyzing code

Exception: trivial (<20 lines, obvious fix, no design decision) → implement directly

### Session Init (run now)
1. mcp__serena__prepare_for_new_conversation  (skip gracefully if no active serena project)
2. mcp__memory__search_nodes                  ← global memory (NOT serena memory)

### MCP Availability & Fallbacks
- serena unavailable → use mcp__filesystem__* + built-in Read (warn user)
- memory unavailable → session-only context, no cross-session recall
- doc-forge unavailable → skip non-text file processing, use Read fallback
- context7 unavailable → skip library docs lookup, use web_reader instead
- ide unavailable → skip getDiagnostics, run Bash test runner manually

### Memory Rules (global = mcp__memory__* only)
  mcp__memory__search_nodes       ← ALWAYS before any task
  mcp__memory__create_entities    ← ask user before saving
  mcp__memory__add_observations   ← ask user before saving
NEVER use mcp__serena__write_memory for cross-session knowledge

### Tool Priority: MCP > Built-in (hooks enforce)
  Never Grep  → mcp__serena__search_for_pattern / find_symbol
  Never Glob  → mcp__serena__find_file
  Never Edit symbol → mcp__serena__replace_symbol_body / rename_symbol
  Never WebSearch for URL → mcp__web_reader__webReader / mcp__fetch__fetch
  Library docs → mcp__context7__resolve-library-id then mcp__context7__get-library-docs

### Verification (every edit — mandatory)
  mcp__ide__getDiagnostics → must = 0
  serena-think: think_about_task_adherence → think_about_collected_information → think_about_whether_you_are_done

### Enterprise Constraints
  security: validate-input-at-boundary | no-secrets-in-logs | owasp-aware
  multi-tenant: tenant_id every query | no-cross-tenant-leak=critical
  data: soft-delete-over-hard | no-select-star | pagination-required
  db: SELECT only via mcp__dbhub__execute_sql | max 1000 rows | never INSERT/UPDATE/DELETE/DROP

### Team Reports
  .claude/team/plan.md | qa-report.md | security-report.md | dev-blocked.md
CONTEXT
)

OUTPUT=$(jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}')

echo "$OUTPUT"
exit 0
