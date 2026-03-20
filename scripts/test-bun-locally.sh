#!/bin/bash
set -e

# Test Paperclip with Bun locally (requires bun installed)
# This avoids Docker build times and lets you iterate quickly

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Testing Paperclip with Bun Runtime ===${NC}"

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${YELLOW}Bun not found. Install from: https://bun.sh${NC}"
    exit 1
fi

echo "Bun version: $(bun --version)"
echo ""

# ============================================
# 1. Install dependencies
# ============================================
echo -e "${BLUE}[1/4] Installing dependencies with Bun...${NC}"
time bun install
echo ""

# ============================================
# 2. Type checking
# ============================================
echo -e "${BLUE}[2/4] Type checking...${NC}"
time bun run -r esbuild-register scripts/typecheck.ts
echo ""

# ============================================
# 3. Build workspace packages
# ============================================
echo -e "${BLUE}[3/4] Building workspace packages...${NC}"
time bun run build
echo ""

# ============================================
# 4. Start dev server
# ============================================
echo -e "${BLUE}[4/4] Starting dev server...${NC}"
echo -e "${YELLOW}(Press Ctrl+C to stop)${NC}"
echo ""

# Start server in background with timeout
timeout 30s bun --hot server/src/index.ts || true

echo -e "${GREEN}✓ Test complete!${NC}"
echo ""
echo "To run Bun locally again:"
echo "  cd $REPO_ROOT"
echo "  pnpm install  # or: bun install"
echo "  pnpm dev      # or: bun --hot server/src/index.ts"
