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
