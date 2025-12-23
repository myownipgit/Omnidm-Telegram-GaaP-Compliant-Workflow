#!/bin/bash

# Export Workflows Script
# Exports all 9 GaaP-compliant workflows from n8n instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
N8N_API_URL="${N8N_API_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"
OUTPUT_DIR="./workflows"

# Workflow IDs (replace with your actual workflow IDs)
declare -A WORKFLOWS=(
  ["B3EI57qh6gslgcZD"]="01-channel-ingress.json"
  ["idear9lu6nRXfT0G"]="02-identity-policy.json"
  ["3zhnQeLkdoVJnbCO"]="03-intent-builder.json"
  ["FFnvtk7UmI8LPKaa"]="04-camdx-publish.json"
  ["gm7uSuxs5H44rGq5"]="05-khqr-generator.json"
  ["rjfmdv6pfBR9dqdc"]="06-deliver-telegram.json"
  ["23BWKLLL4956pJFv"]="07-settlement-verify.json"
  ["SjGTAR6eJYXjpvNJ"]="08-fulfillment-grab.json"
  ["3H5GobR0OfXIoIKN"]="09-audit-camdl.json"
)

# Functions
print_header() {
  echo -e "${GREEN}============================================${NC}"
  echo -e "${GREEN}  n8n Workflow Export Utility${NC}"
  echo -e "${GREEN}  Cambodia GaaP-Compliant Workflows${NC}"
  echo -e "${GREEN}============================================${NC}"
  echo ""
}

print_error() {
  echo -e "${RED}ERROR: $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

check_dependencies() {
  if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
    print_warning "jq not found - JSON formatting will be skipped"
  fi
}

check_n8n_connection() {
  echo "Checking n8n connection..."

  if [ -z "$N8N_API_KEY" ]; then
    print_warning "N8N_API_KEY not set - using basic authentication"
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${N8N_API_URL}/healthz")

  if [ "$HTTP_CODE" != "200" ]; then
    print_error "Cannot connect to n8n at ${N8N_API_URL}"
    print_error "HTTP Status: ${HTTP_CODE}"
    echo ""
    echo "Please ensure:"
    echo "  1. n8n is running"
    echo "  2. N8N_API_URL is correct (default: http://localhost:5678)"
    echo "  3. N8N_API_KEY is set if authentication is enabled"
    exit 1
  fi

  print_success "Connected to n8n at ${N8N_API_URL}"
}

create_output_dir() {
  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    print_success "Created output directory: ${OUTPUT_DIR}"
  fi
}

export_workflow() {
  local workflow_id=$1
  local filename=$2
  local output_file="${OUTPUT_DIR}/${filename}"

  echo "Exporting workflow: ${filename}..."

  # Build curl command
  local CURL_CMD="curl -s"

  if [ -n "$N8N_API_KEY" ]; then
    CURL_CMD="${CURL_CMD} -H 'X-N8N-API-KEY: ${N8N_API_KEY}'"
  fi

  # Export workflow
  local response=$(eval "${CURL_CMD} '${N8N_API_URL}/api/v1/workflows/${workflow_id}'")

  if [ $? -ne 0 ]; then
    print_error "Failed to export ${filename}"
    return 1
  fi

  # Check if jq is available for formatting
  if command -v jq &> /dev/null; then
    echo "$response" | jq '.' > "$output_file"
  else
    echo "$response" > "$output_file"
  fi

  if [ -f "$output_file" ]; then
    print_success "Exported: ${filename}"
  else
    print_error "Failed to write: ${filename}"
    return 1
  fi
}

export_all_workflows() {
  local success_count=0
  local fail_count=0

  echo ""
  echo "Exporting ${#WORKFLOWS[@]} workflows..."
  echo ""

  for workflow_id in "${!WORKFLOWS[@]}"; do
    filename="${WORKFLOWS[$workflow_id]}"

    if export_workflow "$workflow_id" "$filename"; then
      ((success_count++))
    else
      ((fail_count++))
    fi
  done

  echo ""
  echo "Export Summary:"
  echo "  ✓ Successful: ${success_count}"

  if [ $fail_count -gt 0 ]; then
    echo "  ✗ Failed: ${fail_count}"
  fi

  echo ""
}

# Main execution
main() {
  print_header
  check_dependencies
  check_n8n_connection
  create_output_dir
  export_all_workflows

  print_success "Export complete! Workflows saved to: ${OUTPUT_DIR}"
  echo ""
  echo "Next steps:"
  echo "  1. Review exported workflows"
  echo "  2. Commit to Git: git add workflows/ && git commit -m 'Update workflows'"
  echo "  3. Push to GitHub: git push origin main"
}

# Run main function
main
