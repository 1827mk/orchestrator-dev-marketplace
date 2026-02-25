#!/usr/bin/env python3
"""
UserPromptSubmit Hook — prompt-guard.py
Injects routing reminder every prompt so Claude delegates to orchestrator.
"""
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

prompt = data.get("prompt", "").strip().lower()

# Skip trivial/conversational prompts
TRIVIAL = {"hi", "hello", "thanks", "ok", "yes", "no", "sure", "okay"}
if prompt in TRIVIAL or len(prompt) < 5:
    sys.exit(0)

# Skip if already explicitly invoking an agent
AGENT_INVOKE = ["use the ", "task(subagent", "/agents", "subagent="]
if any(kw in prompt for kw in AGENT_INVOKE):
    sys.exit(0)

# All other prompts get routing reminder injected
# Codebase exploration ("project นี้คืออะไร", "อธิบาย", "analyze", etc.)
# is intentionally included — SA agent handles exploration
REMINDER = (
    "ROUTING RULE (orchestrator-dev plugin active):\n"
    "For ANY task involving the codebase — including exploration, explanation, "
    "analysis, review, fix, feature, refactor, security, or documentation — "
    "you MUST invoke Task(subagent=\"orchestrator\") first.\n"
    "This includes questions like 'what does this project do' or 'explain this code'.\n"
    "Do NOT use Bash/Read/Grep/Glob directly for codebase tasks.\n"
    "Exception: pure conversational questions with no codebase access needed."
)

output = {
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": REMINDER
    }
}
print(json.dumps(output))
sys.exit(0)
