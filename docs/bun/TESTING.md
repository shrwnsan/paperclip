# Testing Paperclip with Bun Runtime

Quick reference for testing and benchmarking Paperclip with Bun.

## 1. Local Testing (Fastest)

No Docker required. Test Bun directly on your machine:

```bash
# Install Bun: https://bun.sh
# Then from repo root:
bun install
bun run build
bun --hot server/src/index.ts
```

In another terminal:
```bash
curl http://localhost:3100/api/health
# Expected: {"status":"ok"}
```

**Time to test:** 2-5 minutes  
**Best for:** Quick iteration, debugging, dev experience

---

## 2. Docker Testing

### Option A: Quick Bun Container

```bash
docker compose -f docker-compose.bun.yml up -d
sleep 10
curl http://localhost:3100/api/health
docker compose -f docker-compose.bun.yml ps  # view health status
docker compose -f docker-compose.bun.yml logs -f  # stream logs
docker compose -f docker-compose.bun.yml down  # cleanup
```

**Ports**: `3100` (API)  
**Mode**: `authenticated` (requires login, unlike local dev)  
**Note**: Uses embedded PostgreSQL, data persists in `./data/`

### Option B: Compare Node vs Bun

```bash
# Full comparison (builds images, takes ~10-15 min)
./scripts/compare-runtimes.sh --build

# Quick comparison (if images exist)
./scripts/compare-runtimes.sh
```

Generates: `report/runtime-comparison-YYYYMMDD_HHMMSS.md`

---

## 3. What Works on Both Runtimes

| Feature | Node | Bun | Notes |
|---------|------|-----|-------|
| TypeScript (native) | ✓ (via ts-node) | ✓ (built-in) | Bun faster |
| API endpoints | ✓ | ✓ | Identical behavior |
| Database (embedded PG) | ✓ | ✓ | Works identically |
| Hot reload (dev) | ✓ (nodemon) | ✓ (--hot flag) | Bun simpler |
| Docker build | ✓ | ✓ | Bun faster to build |
| pnpm lockfile | ✓ | ✓ | Bun reads pnpm-lock.yaml |

---

## 4. Key Differences

| Aspect | Node | Bun |
|--------|------|-----|
| **Startup** | 5-15s | 4-12s |
| **Memory (idle)** | 150-250 MB | 100-180 MB |
| **TypeScript** | Requires ts-node/tsx | Native (no transpile) |
| **Hot reload** | Manual (nodemon) | Built-in `--hot` |
| **Docker image** | ~1.5GB | ~1.2GB |
| **Build speed** | Slower | Faster (parallel) |
| **Ecosystem** | Mature | Growing |

---

## 5. Automated Benchmarking Scripts

All scripts are executable from repo root.

### Compare Node vs Bun (Docker)
```bash
./scripts/compare-runtimes.sh [--build]
```
**Output:** Startup time, memory, CPU stats, detailed report

### Test Bun Locally
```bash
./scripts/test-bun-locally.sh
```
**Output:** Runs install → typecheck → build → dev server

### Quick Health Checks
```bash
# Node
docker compose -f docker-compose.yml up -d
curl http://localhost:3100/api/health

# Bun
docker compose -f docker-compose.bun.yml up -d
curl http://localhost:3100/api/health
```

---

## 6. Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| Bun not found | Install from https://bun.sh |
| Docker build fails | `docker system prune -a` then retry |
| Port 3100 in use | `lsof -i :3100` then kill or use different port |
| Health check timeout | Check logs: `docker logs paperclip-bun` |
| Old data interfering | `docker compose down -v` (removes volumes) |

---

## 7. Performance Expectations

**Startup time difference:** 1-3 seconds (both acceptable)  
**Memory difference:** 50-70 MB (negligible at scale)  
**Throughput:** Essentially identical (I/O-bound workload)

**Verdict:** Pick based on **developer experience**, not raw performance.

---

## 8. For Production

If considering Bun for production:

1. **Test with real workload:** Run your actual agent jobs
2. **Monitor metrics:** CPU, memory, error rates over 24h
3. **Compare stability:** Both are production-ready, but test in your environment
4. **Fallback plan:** Keep Node image ready if issues arise

---

## 9. Next Steps

- [ ] Test Bun locally with `bun --hot server/src/index.ts`
- [ ] Run comparison: `./scripts/compare-runtimes.sh --build`
- [ ] Review report in `report/`
- [ ] Decide: Which runtime to standardize on?
- [ ] Update CI/CD if needed

---

## Documentation

Full benchmark details: [`BENCHMARK.md`](BENCHMARK.md)  
Bun setup details: `Dockerfile.bun`, `docker-compose.bun.yml`, `bunfig.toml`  
Docker details: See `doc/DOCKER.md`

---

## Test & Benchmark Scripts Reference

| Script | Purpose | Runtime |
|--------|---------|---------|
| `./scripts/compare-runtimes.sh` | Node vs Bun comparison | 15-20 min |
| `./scripts/test-bun-locally.sh` | Local Bun test (no Docker) | 5-10 min |
| `./scripts/quick-benchmark.sh` | Quick startup/memory check | 3-5 min |
| `./scripts/benchmark-runtime.sh` | Full multi-metric benchmark | 10-15 min |

All scripts are automated and generate reports in `report/`.
