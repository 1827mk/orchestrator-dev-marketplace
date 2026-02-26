#!/usr/bin/env python3
"""
PreToolUse Hook — tool-guard.py v3.0
Priority: mcp_server > skills > built-in
Hard blocks: Grep, Glob
Soft warns: Edit, Write, WebSearch, Read
"""
import json, sys, os, datetime

LOG_FILE = os.path.join(os.path.expanduser("~"), ".claude", "tool-guard.log")

def log(tool, action, reason):
    try:
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a") as f:
            f.write(f"{ts} [{action}] tool={tool} reason={reason}\n")
    except Exception:
        pass

BLOCK = {
    "Grep": (
        "BLOCKED — mcp_server > built-in\n"
        "  search pattern/string  → mcp__serena__search_for_pattern\n"
        "  find class/function    → mcp__serena__find_symbol\n"
        "  find file              → mcp__serena__find_file"
    ),
    "Glob": (
        "BLOCKED — mcp_server > built-in\n"
        "  find files             → mcp__serena__find_file\n"
        "  browse structure       → mcp__filesystem__directory_tree\n"
        "  search files           → mcp__filesystem__search_files"
    ),
}

WARN = {
    "Edit": (
        "PREFER serena (mcp_server > built-in):\n"
        "  edit function/class body  → mcp__serena__replace_symbol_body\n"
        "  rename + cascade refs     → mcp__serena__rename_symbol\n"
        "  insert after symbol       → mcp__serena__insert_after_symbol\n"
        "  insert before symbol      → mcp__serena__insert_before_symbol\n"
        "  regex/string replace      → mcp__serena__replace_content\n"
        "Edit allowed ONLY for plain line-based changes with no symbol equivalent."
    ),
    "Write": (
        "PREFER mcp tools (mcp_server > built-in):\n"
        "  new code file             → mcp__serena__create_text_file\n"
        "  non-code/doc file         → mcp__filesystem__write_file\n"
        "Write allowed only when no mcp equivalent applies."
    ),
    "WebSearch": (
        "PREFER mcp web tools (mcp_server > built-in):\n"
        "  full page                 → mcp__web_reader__webReader\n"
        "  specific URL content      → mcp__fetch__fetch\n"
        "  library/framework docs    → mcp__context7__resolve-library-id → mcp__context7__get-library-docs\n"
        "WebSearch only when no URL or library is known."
    ),
    "Read": (
        "PREFER mcp tools (mcp_server > built-in):\n"
        "  understand structure      → mcp__serena__get_symbols_overview\n"
        "  read code file/chunk      → mcp__serena__read_file\n"
        "  read text file            → mcp__filesystem__read_text_file\n"
        "  read PDF/DOCX/HTML/CSV    → mcp__doc-forge__document_reader\n"
        "  read Excel                → mcp__doc-forge__excel_read\n"
        "  read multiple files       → mcp__filesystem__read_multiple_files\n"
        "  read image (remote URL)   → mcp__4_5v_mcp__analyze_image\n"
        "Read allowed only when none of the above apply."
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
            "additionalContext": f"⚠️ TOOL PRIORITY: mcp_server > built-in\n{WARN[tool_name]}"
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sys.exit(0)
