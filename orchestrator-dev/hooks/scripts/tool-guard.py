#!/usr/bin/env python3
"""
Tool Guard — PreToolUse Hook
Hard blocks: Grep, Glob
Soft warns: Edit, Write, WebSearch, Read
"""
import json
import sys
import os
import datetime

LOG_FILE = os.path.join(os.path.expanduser("~"), ".claude", "tool-guard.log")

def log(tool_name, action, reason):
    try:
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a") as f:
            f.write(f"{ts} [{action}] tool={tool_name} reason={reason}\n")
    except Exception:
        pass  # logging must never break the hook

BLOCK = {
    "Grep": (
        "BLOCKED: Use MCP tools instead of Grep:\n"
        "  • mcp__serena__search_for_pattern  — regex/string search across codebase\n"
        "  • mcp__serena__find_symbol          — find class/function/method by name\n"
        "  • mcp__filesystem__search_files     — glob pattern file search"
    ),
    "Glob": (
        "BLOCKED: Use MCP tools instead of Glob:\n"
        "  • mcp__serena__find_file            — find files matching pattern\n"
        "  • mcp__filesystem__search_files     — filesystem glob search\n"
        "  • mcp__filesystem__directory_tree   — browse directory structure"
    ),
}

WARN = {
    "Edit": (
        "PREFER serena for symbol-level edits:\n"
        "  • Change function/class body  → mcp__serena__replace_symbol_body\n"
        "  • Rename symbol (cascade)     → mcp__serena__rename_symbol\n"
        "  • Insert after symbol         → mcp__serena__insert_after_symbol\n"
        "  • Insert before symbol        → mcp__serena__insert_before_symbol\n"
        "  • Regex/string replace        → mcp__serena__replace_content\n"
        "  Edit allowed ONLY for plain line-based changes with no symbol equivalent."
    ),
    "Write": (
        "PREFER MCP tools for file creation:\n"
        "  • New code file               → mcp__serena__create_text_file\n"
        "  • Non-code / doc file         → mcp__filesystem__write_file\n"
        "  Write allowed only when no MCP equivalent applies."
    ),
    "WebSearch": (
        "PREFER MCP web tools:\n"
        "  • Known URL (full page)        → mcp__web_reader__webReader\n"
        "  • Known URL (specific content) → mcp__fetch__fetch\n"
        "  • Library/framework docs       → mcp__context7__resolve-library-id then mcp__context7__get-library-docs\n"
        "  WebSearch allowed only when no URL or library is known."
    ),
    "Read": (
        "PREFER MCP tools for reading:\n"
        "  • Understand file structure    → mcp__serena__get_symbols_overview\n"
        "  • Read code file/chunk         → mcp__serena__read_file\n"
        "  • Read text file               → mcp__filesystem__read_text_file\n"
        "  • Read PDF/DOCX/HTML/CSV       → mcp__doc-forge__document_reader\n"
        "  • Read Excel                   → mcp__doc-forge__excel_read\n"
        "  • Read image (remote URL)      → mcp__4_5v_mcp__analyze_image\n"
        "  • Read multiple files          → mcp__filesystem__read_multiple_files\n"
        "  Read allowed only when none of the above apply."
    ),
}

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_name = data.get("tool_name", "")

if tool_name in BLOCK:
    log(tool_name, "BLOCK", BLOCK[tool_name].splitlines()[0])
    print(BLOCK[tool_name], file=sys.stderr)
    sys.exit(2)

if tool_name in WARN:
    log(tool_name, "WARN", WARN[tool_name].splitlines()[0])
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": f"⚠️ Tool preference reminder:\n{WARN[tool_name]}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
