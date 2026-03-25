# Eval: Bun Runtime Support

**Date**: 2026-03-25
**Status**: Completed
**Decision**: Keep as optional runtime, Node.js remains primary

## Summary

Evaluated Bun as an alternative runtime for Paperclip. Bun works but offers marginal benefits for our I/O-bound workload. Extracted useful tooling but keeping Node.js as the primary runtime.

## Evaluation Criteria

| Criteria | Result |
|----------|--------|
| Performance improvement | ✅ 2-3x faster cold start, ~50% less memory |
| Compatibility | ✅ Works with existing codebase |
| Developer experience | ✅ Native TypeScript, hot reload |
| Production readiness | ⚠️ Less mature ecosystem |
| Maintenance burden | ⚠️ Requires keeping two runtimes tested |

## Benchmark Results (Apple Silicon M3)

| Metric | Node.js 20 | Bun 1.0+ | Improvement |
|--------|-----------|----------|-------------|
| Cold start | ~3.2s | ~1.1s | **2.9x faster** |
| Hot reload | ~800ms | ~120ms | **6.7x faster** |
| Memory (idle) | ~180MB | ~95MB | **47% less** |
| Install time | ~45s | ~12s | **3.8x faster** |

## Key Findings

### What Works
- Server runs successfully with `bun run server/src/index.ts`
- All API endpoints function identically
- Docker builds work with `Dockerfile.bun`
- Benchmark scripts provide useful comparison data

### What Doesn't Work Well
- Workspace dependency resolution differs from pnpm
- Some `--filter` scripts need conversion
- Less mature debugging tooling

### Recommendation
Use Bun for local development on Apple Silicon, Node.js for production. The performance gains are real but not critical for an I/O-bound agent orchestration platform.

## Extracted Artifacts

Kept in the codebase:

| File | Purpose |
|------|---------|
| `docs/bun/` | Consolidated documentation |
| `Dockerfile.bun` | Multi-stage Docker build |
| `docker-compose.bun.yml` | Docker Compose config |
| `bunfig.toml` | Bun optimization config |
| `scripts/*benchmark*` | Runtime comparison tools |
| `scripts/*bun*` | Setup and testing scripts |

## Consolidation Notes

The original `docs/bun/` contained 6 files with overlapping content:
- **README.md**: Overview + quick start
- **BUN.md**: Detailed reference (outdated branch-specific info)
- **BENCHMARK.md**: Benchmarking guide
- **TESTING.md**: Testing procedures
- **TROUBLESHOOTING.md**: Issue resolution
- **RUNNING_ON_BUN.md**: Self-hoster guide

### Recommended Consolidation
These could be merged into 2-3 files:
1. **README.md** - Quick start + when to use
2. **BENCHMARK.md** - Benchmark results + procedures
3. **TROUBLESHOOTING.md** - Keep as reference

The detailed reference docs (BUN.md, TESTING.md, RUNNING_ON_BUN.md) have redundant information and branch-specific content that's no longer accurate.

## References

- Original branch: `feat/bun-runtime` (deleted after extraction)
- Benchmark scripts: `scripts/compare-runtimes.sh`, `scripts/quick-benchmark.sh`
