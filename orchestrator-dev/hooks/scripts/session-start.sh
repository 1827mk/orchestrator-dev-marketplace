#!/bin/bash
# SessionStart Hook — orchestrator-dev v3.0

if ! command -v jq >/dev/null 2>&1; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"⚠️ jq not found. Install: brew install jq"}}'
  exit 0
fi

[ -n "$CLAUDE_PROJECT_DIR" ] && mkdir -p "$CLAUDE_PROJECT_DIR/.claude/team" 2>/dev/null || true

# Check for interrupted session
INTERRUPTED=""
STATE_FILE=""
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/team/state.md"
  if [ -f "$STATE_FILE" ]; then
    STATUS=$(grep "^status:" "$STATE_FILE" 2>/dev/null | awk '{print $2}')
    if [ "$STATUS" != "COMPLETE" ] && [ -n "$STATUS" ]; then
      PIPELINE=$(grep "^pipeline:" "$STATE_FILE" | awk '{print $2}')
      STEP=$(grep "^step:" "$STATE_FILE" | awk '{print $2}')
      SUBSTEP=$(grep "^substep:" "$STATE_FILE" | sed 's/^substep: //')
      FILES=$(grep "^files_modified:" "$STATE_FILE" | sed 's/^files_modified: //')
      QA=$(grep "^qa_result:" "$STATE_FILE" | awk '{print $2}')
      SEC=$(grep "^security_result:" "$STATE_FILE" | awk '{print $2}')
      QA_ATT=$(grep "^qa_attempts:" "$STATE_FILE" | awk '{print $2}')
      SEC_ATT=$(grep "^security_attempts:" "$STATE_FILE" | awk '{print $2}')
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
    fi
  fi
fi

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

OUTPUT=$(jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}')

echo "$OUTPUT"
exit 0
