#!/bin/bash

# Telegraph Workflows - Startup Check Script
# Verifies environment and displays project status

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Telegraph Workflows - Startup Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Check for n8n-mcp availability
echo -e "${YELLOW}📦 Checking n8n-mcp availability...${NC}"
if command -v npx &> /dev/null; then
  echo -e "${GREEN}✓ npx is available${NC}"
  echo "  You can use: npx -y n8n-mcp"
else
  echo -e "${YELLOW}⚠ npx not found (install Node.js)${NC}"
fi
echo ""

# 2. Check Claude MCP configuration
echo -e "${YELLOW}🔧 Checking Claude MCP configuration...${NC}"
if [ -f ".claude/mcp.json" ]; then
  echo -e "${GREEN}✓ .claude/mcp.json exists${NC}"
  if grep -q "YOUR_N8N_API_KEY_HERE" .claude/mcp.json 2>/dev/null; then
    echo -e "${YELLOW}⚠ API key not configured (still has placeholder)${NC}"
  else
    echo -e "${GREEN}✓ API key appears to be configured${NC}"
  fi
else
  echo -e "${YELLOW}⚠ .claude/mcp.json not found${NC}"
  echo "  Run: cp .claude/mcp.json.example .claude/mcp.json"
  echo "  Then edit with your API key"
fi
echo ""

# 3. List workflows
echo -e "${YELLOW}📋 Workflow Files:${NC}"
if [ -d "workflows" ]; then
  workflow_count=$(ls -1 workflows/*.json 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${GREEN}✓ Found $workflow_count workflow files${NC}"
  ls -1 workflows/*.json | sed 's/^/  /'
else
  echo -e "${YELLOW}⚠ No workflows directory${NC}"
fi
echo ""

# 4. Git status
echo -e "${YELLOW}📊 Git Repository Status:${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Git repository initialized${NC}"

  # Current branch
  branch=$(git branch --show-current)
  echo "  Branch: $branch"

  # Remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  Remote: $remote_url"
  fi

  # Status
  if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${GREEN}✓ Working tree is clean${NC}"
  else
    echo -e "${YELLOW}⚠ You have uncommitted changes${NC}"
    git status --short | sed 's/^/  /'
  fi
else
  echo -e "${YELLOW}⚠ Not a git repository${NC}"
fi
echo ""

# 5. Configuration files
echo -e "${YELLOW}⚙️  Configuration Files:${NC}"
files=("config/product-catalog.json" "config/credentials.example.json")
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓ $file${NC}"
  else
    echo -e "${YELLOW}⚠ $file not found${NC}"
  fi
done
echo ""

# 6. Documentation
echo -e "${YELLOW}📚 Documentation:${NC}"
docs=("README.md" "docs/SETUP.md" "docs/WORKFLOWS.md" "docs/ARCHITECTURE.md")
for doc in "${docs[@]}"; do
  if [ -f "$doc" ]; then
    echo -e "${GREEN}✓ $doc${NC}"
  fi
done
echo ""

# 7. Project structure summary
echo -e "${YELLOW}📁 Project Structure:${NC}"
echo "  $(find workflows -name '*.json' 2>/dev/null | wc -l | tr -d ' ') workflow files"
echo "  $(find docs -name '*.md' 2>/dev/null | wc -l | tr -d ' ') documentation files"
echo "  $(find config -name '*.json' 2>/dev/null | wc -l | tr -d ' ') configuration files"
echo "  $(find scripts -name '*.sh' 2>/dev/null | wc -l | tr -d ' ') utility scripts"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ready to work! 🚀${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Configure .claude/mcp.json with your API key"
echo "  2. Run: npm run validate (to check workflows)"
echo "  3. Run: npm run deploy (to deploy to automation.omnidm.ai)"
echo ""
