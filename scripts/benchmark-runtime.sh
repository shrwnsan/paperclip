#!/bin/bash
set -e

# Paperclip Runtime Benchmarking Script
# Compares Node.js vs Bun runtime performance
# Metrics: startup time, memory, build time, request latency, throughput

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="${REPO_ROOT}/report"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/benchmark-${TIMESTAMP}.md"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_TIME_START=$(date +%s)

echo -e "${BLUE}=== Paperclip Runtime Benchmark ===${NC}"
echo "Report: $REPORT_FILE"
mkdir -p "$REPORT_DIR"

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
# Paperclip Runtime Benchmark Report

EOF

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up containers...${NC}"
    docker compose -f docker-compose.yml down -q 2>/dev/null || true
    docker compose -f docker-compose.bun.yml down -q 2>/dev/null || true
}

trap cleanup EXIT

# ============================================
# 1. BUILD TIME COMPARISON
# ============================================
echo -e "${BLUE}\n[1/5] Building Docker images...${NC}"

BUILD_REPORT="${REPORT_DIR}/build-${TIMESTAMP}.txt"

echo "## Build Times" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Node build
echo -ne "Building Node image... "
NODE_BUILD_START=$(date +%s%N)
docker compose -f docker-compose.yml build server > /tmp/node-build.log 2>&1
NODE_BUILD_END=$(date +%s%N)
NODE_BUILD_TIME=$(echo "scale=2; ($NODE_BUILD_END - $NODE_BUILD_START) / 1000000000" | bc)
echo -e "${GREEN}${NODE_BUILD_TIME}s${NC}"

# Bun build
echo -ne "Building Bun image... "
BUN_BUILD_START=$(date +%s%N)
docker compose -f docker-compose.bun.yml build > /tmp/bun-build.log 2>&1
BUN_BUILD_END=$(date +%s%N)
BUN_BUILD_TIME=$(echo "scale=2; ($BUN_BUILD_END - $BUN_BUILD_START) / 1000000000" | bc)
echo -e "${GREEN}${BUN_BUILD_TIME}s${NC}"

# Extract image sizes
NODE_IMAGE_SIZE=$(docker images --filter "reference=paperclip:latest" --format "{{.Size}}" 2>/dev/null || echo "unknown")
BUN_IMAGE_SIZE=$(docker images --filter "reference=paperclip-bun:latest" --format "{{.Size}}" 2>/dev/null || echo "unknown")

echo "| Runtime | Build Time | Image Size |" >> "$REPORT_FILE"
echo "|---------|-----------|-----------|" >> "$REPORT_FILE"
echo "| Node.js | ${NODE_BUILD_TIME}s | $NODE_IMAGE_SIZE |" >> "$REPORT_FILE"
echo "| Bun     | ${BUN_BUILD_TIME}s | $BUN_IMAGE_SIZE |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 2. STARTUP TIME & MEMORY (IDLE)
# ============================================
echo -e "${BLUE}\n[2/5] Measuring startup time and idle memory...${NC}"

echo "## Startup & Idle Memory" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Node startup
echo "Starting Node container..."
docker compose -f docker-compose.yml up -d server > /dev/null 2>&1
NODE_START=$(date +%s%N)
# Wait for health check
for i in {1..60}; do
    if curl -s http://localhost:3100/api/health > /dev/null 2>&1; then
        NODE_READY=$(date +%s%N)
        NODE_STARTUP_TIME=$(echo "scale=2; ($NODE_READY - $NODE_START) / 1000000000" | bc)
        echo -e "Node ready in ${GREEN}${NODE_STARTUP_TIME}s${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}Node startup timeout${NC}"
        NODE_STARTUP_TIME="timeout"
    fi
done

# Capture Node idle stats
sleep 5
NODE_IDLE_STATS=$(docker stats paperclip-server --no-stream 2>/dev/null | tail -1)
NODE_MEMORY=$(echo "$NODE_IDLE_STATS" | awk '{print $4}')

docker compose -f docker-compose.yml down -q

# Bun startup
echo "Starting Bun container..."
docker compose -f docker-compose.bun.yml up -d > /dev/null 2>&1
BUN_START=$(date +%s%N)
# Wait for health check
for i in {1..60}; do
    if curl -s http://localhost:3100/api/health > /dev/null 2>&1; then
        BUN_READY=$(date +%s%N)
        BUN_STARTUP_TIME=$(echo "scale=2; ($BUN_READY - $BUN_START) / 1000000000" | bc)
        echo -e "Bun ready in ${GREEN}${BUN_STARTUP_TIME}s${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}Bun startup timeout${NC}"
        BUN_STARTUP_TIME="timeout"
    fi
done

# Capture Bun idle stats
sleep 5
BUN_IDLE_STATS=$(docker stats paperclip-bun --no-stream 2>/dev/null | tail -1)
BUN_MEMORY=$(echo "$BUN_IDLE_STATS" | awk '{print $4}')

echo "| Runtime | Startup Time | Idle Memory |" >> "$REPORT_FILE"
echo "|---------|-------------|------------|" >> "$REPORT_FILE"
echo "| Node.js | ${NODE_STARTUP_TIME}s | $NODE_MEMORY |" >> "$REPORT_FILE"
echo "| Bun     | ${BUN_STARTUP_TIME}s | $BUN_MEMORY |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 3. LOAD TESTING (if autocannon available)
# ============================================
echo -e "${BLUE}\n[3/5] Running load tests...${NC}"

# Check if autocannon is available
if command -v autocannon &> /dev/null; then
    echo "## Load Test Results (30s @ 10 concurrent connections)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Bun is still running from previous step
    echo "Running load test against Bun..."
    BUN_LOAD=$(autocannon -c 10 -d 30 -q http://localhost:3100/api/health 2>/dev/null | grep -E "Throughput|Latency" | head -10)
    
    docker compose -f docker-compose.bun.yml down -q
    sleep 5
    
    docker compose -f docker-compose.yml up -d server > /dev/null 2>&1
    # Wait for health check
    for i in {1..60}; do
        if curl -s http://localhost:3100/api/health > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    echo "Running load test against Node..."
    NODE_LOAD=$(autocannon -c 10 -d 30 -q http://localhost:3100/api/health 2>/dev/null | grep -E "Throughput|Latency" | head -10)
    
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "Node.js:" >> "$REPORT_FILE"
    echo "$NODE_LOAD" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Bun:" >> "$REPORT_FILE"
    echo "$BUN_LOAD" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    echo "autocannon not found, skipping load tests"
    echo "Install with: npm install -g autocannon" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# ============================================
# 4. FINAL CLEANUP & SUMMARY
# ============================================
TOTAL_TIME_END=$(date +%s)
TOTAL_TIME=$(($TOTAL_TIME_END - $TOTAL_TIME_START))

echo -e "${BLUE}\n[4/5] Generating summary...${NC}"

echo "## Summary" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Total benchmark time:** ${TOTAL_TIME}s" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Key Findings:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ "$BUN_STARTUP_TIME" != "timeout" ] && [ "$NODE_STARTUP_TIME" != "timeout" ]; then
    STARTUP_DIFF=$(echo "scale=2; $NODE_STARTUP_TIME - $BUN_STARTUP_TIME" | bc)
    if (( $(echo "$STARTUP_DIFF > 0" | bc -l) )); then
        echo "- **Startup:** Bun is ${STARTUP_DIFF}s faster" >> "$REPORT_FILE"
    else
        echo "- **Startup:** Node is $(echo "$STARTUP_DIFF * -1" | bc)s faster" >> "$REPORT_FILE"
    fi
fi

if [ "$BUN_MEMORY" != "N/A" ] && [ "$NODE_MEMORY" != "N/A" ]; then
    echo "- **Idle Memory:** Bun: $BUN_MEMORY | Node: $NODE_MEMORY" >> "$REPORT_FILE"
fi

BUILD_DIFF=$(echo "scale=2; $NODE_BUILD_TIME - $BUN_BUILD_TIME" | bc)
if (( $(echo "$BUILD_DIFF > 0" | bc -l) )); then
    echo "- **Build Time:** Bun is ${BUILD_DIFF}s faster" >> "$REPORT_FILE"
else
    echo "- **Build Time:** Node is $(echo "$BUILD_DIFF * -1" | bc)s faster" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"

echo -e "${BLUE}\n[5/5] Benchmark complete!${NC}"
echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"
cat "$REPORT_FILE"
