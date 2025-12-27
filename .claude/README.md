# Claude Configuration

This directory contains Claude Code configuration for the Telegraph Workflows project.

## Setup Instructions

1. Copy the example file:
   ```bash
   cp .claude/mcp.json.example .claude/mcp.json
   ```

2. Edit `.claude/mcp.json` and replace `YOUR_N8N_API_KEY_HERE` with your actual API key

3. **NEVER commit `mcp.json`** - it's already in `.gitignore`

## Files

- `mcp.json.example` - Template (safe to commit)
- `mcp.json` - Your config with real keys (**NOT in Git**)
- `README.md` - This file

## n8n MCP Server

Provides tools for managing n8n workflows directly from Claude Code.

**Get your API key:**
1. Log in to https://automation.omnidm.ai
2. Settings → API → Generate new API key
