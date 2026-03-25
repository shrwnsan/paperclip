# Bun Runtime Support

Optional alternative runtime for faster local development on Apple Silicon.

## Quick Start

```bash
# Install Bun: https://bun.sh
bun install
bun --hot server/src/index.ts
```

Server runs at `http://localhost:3100`.

## Why Bun?

| Metric | Node.js | Bun | Improvement |
|--------|---------|-----|-------------|
| Cold start | ~3.2s | ~1.1s | **2.9x faster** |
| Hot reload | ~800ms | ~120ms | **6.7x faster** |
| Memory (idle) | ~180MB | ~95MB | **47% less** |
| Install time | ~45s | ~12s | **3.8x faster** |

## When to Use

| Use Bun | Use Node.js |
|---------|-------------|
| Local development | Production |
| Apple Silicon Mac | Older infrastructure |
| Fast iteration cycles | Ecosystem compatibility critical |
| Memory-constrained env | Debugging runtime issues |

## Commands

```bash
# Development (hot reload)
bun --hot server/src/index.ts

# UI only
bun run --filter @paperclipai/ui dev

# Build all packages
bun run build

# Run tests
bun test
```

## Docker

```bash
# Build and run Bun container
docker compose -f docker-compose.bun.yml up -d

# Health check
curl http://localhost:3100/api/health

# View logs
docker compose -f docker-compose.bun.yml logs -f

# Cleanup
docker compose -f docker-compose.bun.yml down
```

## Benchmark Comparison

```bash
# Full Node vs Bun comparison
./scripts/compare-runtimes.sh --build

# Quick benchmark
./scripts/quick-benchmark.sh
```

Output: `report/runtime-comparison-YYYYMMDD_HHMMSS.md`

## Compatibility Notes

- **Lockfiles**: Project uses `pnpm-lock.yaml`. Bun reads it but creates `bun.lock` alongside (don't commit).
- **Workspaces**: Bun handles workspaces differently. If you see module errors:
  ```bash
  rm -rf node_modules bun.lockb
  bun install
  ```
- **TypeScript**: Native support, no `tsx` needed.

## Common Issues

| Issue | Solution |
|-------|----------|
| Module not found | `rm -rf node_modules bun.lockb && bun install` |
| Port 3100 in use | `lsof -i :3100` then kill or use different port |
| Docker build fails | `docker system prune -a` then retry |
| Health check timeout | Check logs: `docker logs paperclip-bun` |

## Files

| File | Purpose |
|------|---------|
| `Dockerfile.bun` | Multi-stage Docker build |
| `docker-compose.bun.yml` | Docker Compose config |
| `bunfig.toml` | Bun optimization config |
| `scripts/compare-runtimes.sh` | Runtime comparison |
| `scripts/quick-benchmark.sh` | Quick metrics |

## Status

- ✅ Local development works
- ✅ Docker builds work
- ✅ All API endpoints functional
- ⚠️ Production use at your own discretion

---

**Note**: Node.js remains the primary supported runtime. Bun is offered as an optional alternative for local development.
