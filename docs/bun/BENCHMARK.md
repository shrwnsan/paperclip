# Benchmarking: Node.js vs Bun

## Quick Comparison

```bash
# Full comparison with image builds (~10-15 min)
./scripts/compare-runtimes.sh --build

# Quick comparison if images exist (~3-5 min)
./scripts/compare-runtimes.sh

# Quick startup/memory check
./scripts/quick-benchmark.sh
```

Output: `report/runtime-comparison-YYYYMMDD_HHMMSS.md`

## Manual Testing

### Local (No Docker)

```bash
# Test Bun
bun install
bun --hot server/src/index.ts &
curl http://localhost:3100/api/health
pkill -f "bun.*server"

# Test Node
pnpm install
pnpm dev &
curl http://localhost:3100/api/health
pkill -f "node.*server"
```

### Docker

```bash
# Node.js
docker compose -f docker-compose.yml up -d
docker stats --no-stream
curl http://localhost:3100/api/health
docker compose down

# Bun
docker compose -f docker-compose.bun.yml up -d
docker stats --no-stream
curl http://localhost:3100/api/health
docker compose -f docker-compose.bun.yml down
```

## Load Testing (Optional)

```bash
# Install autocannon
npm install -g autocannon

# Test either runtime
autocannon -c 10 -d 30 http://localhost:3100/api/health
```

## Metrics to Track

| Metric | How to Measure | Importance |
|--------|---------------|------------|
| Startup time | `time docker compose up` | High - affects deployment |
| Memory (idle) | `docker stats --no-stream` | Medium - cost & scaling |
| Throughput | `autocannon` / `wrk` | High - user experience |
| Latency (p95) | Load test tools | High - user experience |
| Image size | `docker images` | Low - cold start only |

## Expected Results (Apple Silicon M3)

| Metric | Node.js | Bun |
|--------|---------|-----|
| Cold start | 5-15s | 4-12s |
| Memory (idle) | 150-250 MB | 100-180 MB |
| Docker image | ~1.5GB | ~1.2GB |

## Interpretation

If startup differs by < 2-3 seconds, **both are viable**. Choose based on:
- Developer experience
- Team familiarity
- Production requirements

## CI/CD Integration

```yaml
# .github/workflows/benchmark.yml
name: Runtime Benchmark
on: [workflow_dispatch]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build images
        run: |
          docker build -t paperclip:node .
          docker build -t paperclip:bun -f Dockerfile.bun .
      - name: Run comparison
        run: ./scripts/compare-runtimes.sh
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: benchmark-report
          path: report/
```
