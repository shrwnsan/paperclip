#!/bin/bash
set -e

# Quick Paperclip Runtime Benchmark (assumes images already exist)
# Metrics: startup time, idle memory, basic health check

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="${REPO_ROOT}/report"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/benchmark-quick-${TIMESTAMP}.md"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL_TIME_START=$(date +%s)

echo -e "${BLUE}=== Paperclip Quick Benchmark ===${NC}"
mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" << 'EOF'
# Paperclip Runtime Benchmark Report

EOF

cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker compose -f docker-compose.yml down -q 2>/dev/null || true
    docker compose -f docker-compose.bun.yml down -q 2>/dev/null || true
    docker rm -f paperclip-server paperclip-bun 2>/dev/null || true
}

trap cleanup EXIT

# ============================================
# 1. NODE.JS BENCHMARK
# ============================================
echo -e "${BLUE}\n[1/2] Benchmarking Node.js...${NC}"
echo "## Node.js" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

docker compose -f docker-compose.yml up -d server 2>&1 | grep -E "Creating|created|Starting" || true

NODE_START=$(date +%s%N)
NODE_READY=0

for i in {1..60}; do
    if curl -s http://localhost:3100/api/health > /dev/null 2>&1; then
        NODE_READY=$(date +%s%N)
        NODE_STARTUP_TIME=$(echo "scale=3; ($NODE_READY - $NODE_START) / 1000000000" | bc)
        echo -e "✓ Ready in ${GREEN}${NODE_STARTUP_TIME}s${NC}"
        break
    fi
    [ $((i % 10)) -eq 0 ] && echo "  waiting... ($i/60)"
    sleep 1
done

sleep 3

if [ "$NODE_READY" -gt 0 ]; then
    NODE_STATS=$(docker stats paperclip-server --no-stream 2>/dev/null | tail -1 || echo "")
    NODE_CPU=$(echo "$NODE_STATS" | awk '{print $3}' 2>/dev/null || echo "N/A")
    NODE_MEM=$(echo "$NODE_STATS" | awk '{print $4}' 2>/dev/null || echo "N/A")
    
    echo "- **Startup time:** ${NODE_STARTUP_TIME}s" >> "$REPORT_FILE"
    echo "- **Idle CPU:** ${NODE_CPU}" >> "$REPORT_FILE"
    echo "- **Idle Memory:** ${NODE_MEM}" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

docker compose -f docker-compose.yml down -q 2>/dev/null || true
sleep 3

# ============================================
# 2. BUN BENCHMARK
# ============================================
echo -e "${BLUE}\n[2/2] Benchmarking Bun...${NC}"
echo "## Bun" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

docker compose -f docker-compose.bun.yml up -d 2>&1 | grep -E "Creating|created|Starting" || true

BUN_START=$(date +%s%N)
BUN_READY=0

for i in {1..60}; do
    if curl -s http://localhost:3100/api/health > /dev/null 2>&1; then
        BUN_READY=$(date +%s%N)
        BUN_STARTUP_TIME=$(echo "scale=3; ($BUN_READY - $BUN_START) / 1000000000" | bc)
        echo -e "✓ Ready in ${GREEN}${BUN_STARTUP_TIME}s${NC}"
        break
    fi
    [ $((i % 10)) -eq 0 ] && echo "  waiting... ($i/60)"
    sleep 1
done

sleep 3

if [ "$BUN_READY" -gt 0 ]; then
    BUN_STATS=$(docker stats paperclip-bun --no-stream 2>/dev/null | tail -1 || echo "")
    BUN_CPU=$(echo "$BUN_STATS" | awk '{print $3}' 2>/dev/null || echo "N/A")
    BUN_MEM=$(echo "$BUN_STATS" | awk '{print $4}' 2>/dev/null || echo "N/A")
    
    echo "- **Startup time:** ${BUN_STARTUP_TIME}s" >> "$REPORT_FILE"
    echo "- **Idle CPU:** ${BUN_CPU}" >> "$REPORT_FILE"
    echo "- **Idle Memory:** ${BUN_MEM}" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# ============================================
# 3. COMPARISON
# ============================================
echo -e "${BLUE}\nGenerating comparison...${NC}"
echo "## Comparison" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Metric | Node.js | Bun | Difference |" >> "$REPORT_FILE"
echo "|--------|---------|-----|-----------|" >> "$REPORT_FILE"

if [ "$NODE_READY" -gt 0 ] && [ "$BUN_READY" -gt 0 ]; then
    STARTUP_DIFF=$(echo "scale=3; $NODE_STARTUP_TIME - $BUN_STARTUP_TIME" | bc)
    if (( $(echo "$STARTUP_DIFF > 0" | bc -l) )); then
        DIFF_STR="${GREEN}Bun +${STARTUP_DIFF}s faster${NC}"
    elif (( $(echo "$STARTUP_DIFF < 0" | bc -l) )); then
        DIFF_STR="${YELLOW}Node +$(echo "$STARTUP_DIFF * -1" | bc)s faster${NC}"
    else
        DIFF_STR="Equal"
    fi
    echo "| Startup Time | ${NODE_STARTUP_TIME}s | ${BUN_STARTUP_TIME}s | $STARTUP_DIFF |" >> "$REPORT_FILE"
fi

echo "| Idle CPU | $NODE_CPU | $BUN_CPU | - |" >> "$REPORT_FILE"
echo "| Idle Memory | $NODE_MEM | $BUN_MEM | - |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

TOTAL_TIME_END=$(date +%s)
TOTAL_TIME=$(($TOTAL_TIME_END - $TOTAL_TIME_START))

echo "---" >> "$REPORT_FILE"
echo "**Total test time:** ${TOTAL_TIME}s | Generated: $(date)" >> "$REPORT_FILE"

echo -e "${GREEN}\n✓ Benchmark complete!${NC}"
echo -e "Report: ${REPORT_FILE}\n"
cat "$REPORT_FILE"
