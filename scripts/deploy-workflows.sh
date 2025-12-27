#!/bin/bash

# Telegraph Workflows - Deploy Script
# Deploys workflows to automation.omnidm.ai using n8n-mcp

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Telegraph Workflows - Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if n8n-mcp is available
if ! command -v npx &> /dev/null; then
  echo -e "${RED}❌ npx is not installed${NC}"
  echo "  Install Node.js first: https://nodejs.org/"
  exit 1
fi

# Check if MCP config exists
if [ ! -f ".claude/mcp.json" ]; then
  echo -e "${RED}❌ .claude/mcp.json not found${NC}"
  echo "  Run: cp .claude/mcp.json.example .claude/mcp.json"
  echo "  Then edit with your API key"
  exit 1
fi

# Check if API key is configured
if grep -q "YOUR_N8N_API_KEY_HERE" .claude/mcp.json 2>/dev/null; then
  echo -e "${RED}❌ API key not configured${NC}"
  echo "  Edit .claude/mcp.json and add your real API key"
  exit 1
fi

# Validate workflows first
echo -e "${YELLOW}📋 Running validation...${NC}"
if [ -f "scripts/validate-workflows.sh" ]; then
  bash scripts/validate-workflows.sh
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Validation failed. Fix errors before deploying.${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠ Validation script not found, skipping...${NC}"
fi
echo ""

# Deploy workflows
echo -e "${YELLOW}🚀 Deploying workflows to automation.omnidm.ai...${NC}"
echo ""
echo "This script uses n8n-mcp tools to deploy workflows."
echo "For actual deployment, use Claude Code with the n8n-mcp server configured."
echo ""
echo "Steps:"
echo "  1. Ensure .claude/mcp.json is configured with your API key"
echo "  2. Open this project in Claude Code"
echo "  3. Ask Claude to deploy workflows using n8n-mcp tools"
echo ""
echo "Example prompts:"
echo "  - 'Deploy all workflows from /workflows/ to automation.omnidm.ai'"
echo "  - 'List current workflows on automation.omnidm.ai'"
echo "  - 'Update workflow 01-channel-ingress.json'"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Guide${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Manual deployment via n8n UI:"
echo "  1. Visit: https://automation.omnidm.ai"
echo "  2. Go to: Workflows → Import"
echo "  3. Select files from: workflows/"
echo "  4. Configure credentials in n8n UI"
echo "  5. Activate workflows"
echo ""
echo "For automated deployment, use n8n API or n8n-mcp tools from Claude Code."
echo ""
