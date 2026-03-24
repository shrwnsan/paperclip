# Benchmarking Paperclip Runtime (Node vs Bun)

This guide provides automated and manual methods to benchmark Paperclip on Node.js and Bun runtimes.

## Quick Start (Local Dev)

Test Bun locally without Docker (see [`TESTING.md`](TESTING.md) for full guide):

```sh
# Install Bun if needed: https://bun.sh
bun install
bun run build
bun --hot server/src/index.ts
```

Then in another terminal:
```sh
curl http://localhost:3100/api/health
```

**Pros:** Fast iteration, no Docker overhead  
**Cons:** Requires Bun installation

## Docker Comparison (Automated)

### Full Comparison with Image Building

Builds and benchmarks both Node and Bun containers (takes ~5-10 minutes):

```sh
./scripts/compare-runtimes.sh --build
```

This generates a report with:
- Image sizes
- Startup times
- Idle CPU/memory usage
- Performance analysis

**Output:** `report/runtime-comparison-YYYYMMDD_HHMMSS.md`

### Quick Comparison (Existing Images)

If images are already built:

```sh
./scripts/compare-runtimes.sh
```

## Manual Docker Testing

### Test Node.js Runtime

```sh
docker compose -f docker-compose.yml up
curl http://localhost:3100/api/health
docker stats
```

Health check response:
```json
{"status":"ok"}
```

### Test Bun Runtime

```sh
docker compose -f docker-compose.bun.yml up
curl http://localhost:3100/api/health
docker stats
```

## Metrics to Monitor

| Metric | Tool | Importance |
|--------|------|-----------|
| **Startup Time** | `docker logs` + timing | ⭐⭐⭐ High — affects deployment |
| **Memory (Idle)** | `docker stats` | ⭐⭐ Medium — cost & scaling |
| **CPU (Idle)** | `docker stats` | ⭐ Low — well-managed by both |
| **Throughput** | `autocannon` / `wrk` | ⭐⭐⭐ High — user experience |
| **Latency (p50/p95)** | Load test tools | ⭐⭐⭐ High — user experience |
| **Image Size** | `docker images` | ⭐ Low — mostly matters for cold-start edge |

## Load Testing (Optional)

If you want detailed throughput/latency metrics:

```sh
# Install autocannon globally
npm install -g autocannon

# Run load test (Node)
docker compose -f docker-compose.yml up -d
autocannon -c 10 -d 30 http://localhost:3100/api/health

# Run load test (Bun)
docker compose -f docker-compose.bun.yml up -d
autocannon -c 10 -d 30 http://localhost:3100/api/health
```

Output includes:
- **Throughput (req/sec)**
- **Latency percentiles (p50, p90, p95, p99)**
- **Memory & CPU during load**

## Interpreting Results

### Expected Startup Times
- **Node.js:** 5-15s (varies by system)
- **Bun:** 4-12s (often faster, but highly variable)

### Expected Idle Memory
- **Node.js:** 150-250 MB
- **Bun:** 100-180 MB (often lower)

### Key Takeaway

If startup time differs by < 2-3 seconds, **both are viable**. Pick based on:
- Developer experience
- Team familiarity
- Production requirements
- Monitoring/debugging tooling

## Automated Benchmarking Scripts

Located in `/scripts/`:

- **`compare-runtimes.sh`** — Main comparison tool
- **`test-bun-locally.sh`** — Test Bun without Docker
- **`benchmark-runtime.sh`** — Comprehensive multi-metric benchmark (legacy)

## Troubleshooting

### Containers won't start
```sh
docker compose down -v  # Clean volumes
docker system prune -a  # Clean unused images
```

### Health check times out
Check logs: `docker logs paperclip-bun` or `docker logs paperclip-server`

### Load test fails
Install autocannon: `npm install -g autocannon`  
Or use alternative: `npm install -g wrk` (if available)

## CI/CD Integration

For automated benchmarking in CI:

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
        run: docker build -t paperclip:node . && docker build -t paperclip:bun -f Dockerfile.bun .
      - name: Run comparison
        run: ./scripts/compare-runtimes.sh
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: benchmark-report
          path: report/
```

## Notes

- **pnpm vs Bun lockfiles:** Project uses `pnpm-lock.yaml`, not `bun.lock`
  - Bun is compatible and can read pnpm lockfiles
  - Running `bun install` creates a `bun.lock` alongside (don't commit)
  
- **Hot reload:** Bun supports `--hot` flag for dev; Node requires external tools

- **TypeScript:** Bun has native support; Node requires `ts-node` or `tsx`

- **Docker builds:** Both Dockerfiles use multi-stage builds for dev/production separation
