#!/bin/bash

# Telegraph Workflows - Local Validation Script
# Validates JSON syntax and workflow structure

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Telegraph Workflows - Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${RED}❌ jq is required but not installed${NC}"
  echo "  Install: brew install jq (macOS)"
  echo "          apt-get install jq (Ubuntu)"
  exit 1
fi

# Validation counters
total_files=0
valid_files=0
invalid_files=0

# 1. Validate JSON syntax
echo -e "${YELLOW}🔍 Step 1: Validating JSON syntax...${NC}"
for file in workflows/*.json config/*.json; do
  if [ -f "$file" ]; then
    ((total_files++))
    if jq empty "$file" 2>/dev/null; then
      echo -e "${GREEN}✓ Valid JSON: $file${NC}"
      ((valid_files++))
    else
      echo -e "${RED}❌ Invalid JSON: $file${NC}"
      ((invalid_files++))
    fi
  fi
done
echo ""

# 2. Validate workflow structure
echo -e "${YELLOW}🔍 Step 2: Validating workflow structure...${NC}"
for file in workflows/*.json; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")

    # Check for required fields
    has_name=$(jq -e '.name' "$file" >/dev/null 2>&1 && echo "yes" || echo "no")
    has_nodes=$(jq -e '.nodes' "$file" >/dev/null 2>&1 && echo "yes" || echo "no")
    has_connections=$(jq -e '.connections' "$file" >/dev/null 2>&1 && echo "yes" || echo "no")

    if [ "$has_name" = "yes" ] && [ "$has_nodes" = "yes" ] && [ "$has_connections" = "yes" ]; then
      echo -e "${GREEN}✓ Valid structure: $filename${NC}"
    else
      echo -e "${RED}❌ Invalid structure: $filename${NC}"
      [ "$has_name" = "no" ] && echo "    Missing 'name' field"
      [ "$has_nodes" = "no" ] && echo "    Missing 'nodes' field"
      [ "$has_connections" = "no" ] && echo "    Missing 'connections' field"
      ((invalid_files++))
    fi
  fi
done
echo ""

# 3. Validate GaaP naming convention
echo -e "${YELLOW}🔍 Step 3: Validating GaaP naming convention...${NC}"
for file in workflows/*.json; do
  if [ -f "$file" ]; then
    name=$(jq -r '.name' "$file" 2>/dev/null)

    if [[ "$name" =~ ^\[KH\.GaaS\] ]]; then
      echo -e "${GREEN}✓ GaaP naming: $name${NC}"
    else
      echo -e "${RED}❌ Invalid naming: $name${NC}"
      echo "    Must start with: [KH.GaaS]"
    fi
  fi
done
echo ""

# 4. Check for credentials in workflows
echo -e "${YELLOW}🔍 Step 4: Checking for exposed credentials...${NC}"
found_issue=false

patterns=(
  "password[\"']?\s*[:=]\s*[\"'][^\"']{8,}"
  "api[_-]?key[\"']?\s*[:=]\s*[\"'][^\"']{8,}"
  "secret[\"']?\s*[:=]\s*[\"'][^\"']{8,}"
  "token[\"']?\s*[:=]\s*[\"'][^\"']{8,}"
  "Bearer [A-Za-z0-9\-_]{20,}"
  "[0-9]{10}:[A-Za-z0-9_-]{35}"
)

for pattern in "${patterns[@]}"; do
  if grep -rE "$pattern" workflows/ config/ --exclude="*.example.json" 2>/dev/null; then
    echo -e "${RED}❌ Potential exposed credential found!${NC}"
    found_issue=true
  fi
done

if [ "$found_issue" = false ]; then
  echo -e "${GREEN}✓ No exposed credentials detected${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Total files checked: $total_files"
echo -e "${GREEN}Valid files: $valid_files${NC}"
if [ $invalid_files -gt 0 ]; then
  echo -e "${RED}Invalid files: $invalid_files${NC}"
  echo ""
  echo -e "${RED}❌ Validation FAILED${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ All validations PASSED${NC}"
  echo ""
  echo "Your workflows are ready to deploy!"
fi
