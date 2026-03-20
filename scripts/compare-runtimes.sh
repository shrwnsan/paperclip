#!/bin/bash
set -e

# Paperclip Runtime Comparison
# Compares Node vs Bun startup time and memory usage
# Usage: ./scripts/compare-runtimes.sh [--build]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

REPORT_DIR="${REPO_ROOT}/report"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/runtime-comparison-${TIMESTAMP}.md"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$REPORT_DIR"

echo -e "${BLUE}=== Paperclip Runtime Comparison ===${NC}\n"

cleanup() {
    echo -e "\n${YELLOW}Cleaning up containers...${NC}"
    docker rm -f paperclip-node paperclip-bun 2>/dev/null || true
}

trap cleanup EXIT

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
# Paperclip Runtime Comparison Report

EOF

# ============================================
# Check Docker availability
# ============================================
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not found${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Building Docker images (if needed)...${NC}\n"

# Build with --build flag if specified
if [[ "$1" == "--build" ]]; then
    echo "Building Node image..."
    docker build -t paperclip:node -f Dockerfile . --target dev > /tmp/docker-node-build.log 2>&1 &
    NODE_BUILD_PID=$!
    
    echo "Building Bun image..."
    docker build -t paperclip:bun -f Dockerfile.bun . --target dev > /tmp/docker-bun-build.log 2>&1 &
    BUN_BUILD_PID=$!
    
    echo "Waiting for builds..."
    wait $NODE_BUILD_PID
    wait $BUN_BUILD_PID
    echo -e "${GREEN}✓ Builds complete${NC}\n"
fi

# Check if images exist
if ! docker image inspect paperclip:node > /dev/null 2>&1; then
    echo -e "${YELLOW}Node image not found. Building...${NC}"
    docker build -t paperclip:node -f Dockerfile . --target dev > /dev/null 2>&1
fi

if ! docker image inspect paperclip:bun > /dev/null 2>&1; then
    echo -e "${YELLOW}Bun image not found. Building...${NC}"
    docker build -t paperclip:bun -f Dockerfile.bun . --target dev > /dev/null 2>&1
fi

# Get image sizes
NODE_SIZE=$(docker image inspect paperclip:node --format='{{.Size}}' | numfmt --to=iec 2>/dev/null || docker image inspect paperclip:node --format='{{.Size}}')
BUN_SIZE=$(docker image inspect paperclip:bun --format='{{.Size}}' | numfmt --to=iec 2>/dev/null || docker image inspect paperclip:bun --format='{{.Size}}')

echo "Node image size: $NODE_SIZE"
echo "Bun image size: $BUN_SIZE"
echo ""

# ============================================
# Benchmark: Node
# ============================================
echo -e "${BLUE}Step 2: Benchmarking Node.js...${NC}"

docker run -d --name paperclip-node \
    -p 3101:3100 \
    -e NODE_ENV=development \
    -e PAPERCLIP_DATA_DIR=/app/data \
    paperclip:node > /dev/null 2>&1

NODE_START=$(date +%s%N)
NODE_READY_TIME=""

for i in {1..120}; do
    if curl -s http://localhost:3101/api/health > /dev/null 2>&1; then
        NODE_READY=$(date +%s%N)
        NODE_READY_TIME=$(echo "scale=3; ($NODE_READY - $NODE_START) / 1000000000" | bc)
        echo -e "✓ Node ready in ${GREEN}${NODE_READY_TIME}s${NC}"
        break
    fi
    sleep 0.5
    
    if [ $i -eq 120 ]; then
        echo -e "${RED}✗ Node startup timeout${NC}"
        NODE_READY_TIME="TIMEOUT"
    fi
done

sleep 2

if [ "$NODE_READY_TIME" != "TIMEOUT" ]; then
    NODE_STATS=$(docker stats paperclip-node --no-stream 2>/dev/null | tail -1)
    NODE_CPU=$(echo "$NODE_STATS" | awk '{print $3}')
    NODE_MEM=$(echo "$NODE_STATS" | awk '{print $4}')
    NODE_MEM_RAW=$(echo "$NODE_STATS" | awk '{print $5}')
fi

# ============================================
# Benchmark: Bun
# ============================================
echo -e "${BLUE}Step 3: Benchmarking Bun...${NC}"

docker run -d --name paperclip-bun \
    -p 3102:3100 \
    -e NODE_ENV=development \
    -e PAPERCLIP_DATA_DIR=/app/data \
    paperclip:bun > /dev/null 2>&1

BUN_START=$(date +%s%N)
BUN_READY_TIME=""

for i in {1..120}; do
    if curl -s http://localhost:3102/api/health > /dev/null 2>&1; then
        BUN_READY=$(date +%s%N)
        BUN_READY_TIME=$(echo "scale=3; ($BUN_READY - $BUN_START) / 1000000000" | bc)
        echo -e "✓ Bun ready in ${GREEN}${BUN_READY_TIME}s${NC}"
        break
    fi
    sleep 0.5
    
    if [ $i -eq 120 ]; then
        echo -e "${RED}✗ Bun startup timeout${NC}"
        BUN_READY_TIME="TIMEOUT"
    fi
done

sleep 2

if [ "$BUN_READY_TIME" != "TIMEOUT" ]; then
    BUN_STATS=$(docker stats paperclip-bun --no-stream 2>/dev/null | tail -1)
    BUN_CPU=$(echo "$BUN_STATS" | awk '{print $3}')
    BUN_MEM=$(echo "$BUN_STATS" | awk '{print $4}')
    BUN_MEM_RAW=$(echo "$BUN_STATS" | awk '{print $5}')
fi

# ============================================
# Generate Report
# ============================================
echo -e "${BLUE}Step 4: Generating report...${NC}\n"

cat >> "$REPORT_FILE" << EOF

## System Info
- **Docker:** $(docker --version)
- **Date:** $(date)

## Image Sizes

| Runtime | Size |
|---------|------|
| Node.js | $NODE_SIZE |
| Bun | $BUN_SIZE |

## Startup Performance

| Metric | Node.js | Bun |
|--------|---------|-----|
| Startup Time | ${NODE_READY_TIME}s | ${BUN_READY_TIME}s |
| Idle CPU | ${NODE_CPU} | ${BUN_CPU} |
| Idle Memory (%) | ${NODE_MEM} | ${BUN_MEM} |
| Idle Memory (Absolute) | ${NODE_MEM_RAW} | ${BUN_MEM_RAW} |

## Analysis

EOF

if [ "$NODE_READY_TIME" != "TIMEOUT" ] && [ "$BUN_READY_TIME" != "TIMEOUT" ]; then
    STARTUP_DIFF=$(echo "scale=3; $NODE_READY_TIME - $BUN_READY_TIME" | bc)
    if (( $(echo "$STARTUP_DIFF > 0" | bc -l) )); then
        echo "### Startup Time" >> "$REPORT_FILE"
        echo "**Bun is ${STARTUP_DIFF}s faster** ($(echo "scale=0; $STARTUP_DIFF / $NODE_READY_TIME * 100" | bc)% faster)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    elif (( $(echo "$STARTUP_DIFF < 0" | bc -l) )); then
        DIFF_ABS=$(echo "$STARTUP_DIFF * -1" | bc)
        echo "### Startup Time" >> "$REPORT_FILE"
        echo "**Node is ${DIFF_ABS}s faster** ($(echo "scale=0; $DIFF_ABS / $BUN_READY_TIME * 100" | bc)% faster)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

cat >> "$REPORT_FILE" << 'EOF'

## Conclusion

Both runtimes are production-ready for Paperclip. Consider:

- **Bun advantages:** Faster startup, built-in TypeScript, simpler config
- **Node advantages:** Mature ecosystem, broader compatibility, more debugging tools
- **Use Bun when:** You value developer experience, hot reload in dev, fast deployments
- **Use Node when:** Your team is familiar with Node, specific library requirements

### Recommendation

For local development: **Either is fine** — choose based on team preference
For production: **Test both** — measure against your actual workload

EOF

cat "$REPORT_FILE"

echo ""
echo -e "${GREEN}✓ Report saved: $REPORT_FILE${NC}"
