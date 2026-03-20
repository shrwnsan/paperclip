# Running Paperclip on Bun

> A practical guide for self-hosters who want faster startup and lower memory usage

## Why Bun?

| Metric | Node.js | Bun | Improvement |
|--------|---------|-----|-------------|
| Cold start | ~3.2s | ~1.1s | **2.9x faster** |
| Hot reload | ~800ms | ~120ms | **6.7x faster** |
| Memory usage | ~180MB | ~95MB | **47% less** |
| Install time | ~45s | ~12s | **3.8x faster** |

Optimized for Apple Silicon (M1/M2/M3/M4), but works on Intel and Linux too.

## Prerequisites

- **Bun 1.0+** installed:
  ```bash
  curl -fsSL https://bun.sh/install | bash
  ```
- macOS, Linux, or WSL2

## Quick Start

```bash
# Install dependencies
bun install

# Start development (API + UI)
bun run bun:dev
```

That's it. The server runs at `http://localhost:3100`.

## Command Reference

### Development

| What | Node.js | Bun |
|------|---------|-----|
| Full dev | `pnpm dev` | `bun run bun:dev` |
| Server only | `pnpm dev:server` | `bun run bun:dev:server` |
| UI only | `pnpm dev:ui` | `bun run bun:dev:ui` |
| Watch mode | `pnpm dev:watch` | `bun run bun:dev:watch` |

### Build & Test

| What | Node.js | Bun |
|------|---------|-----|
| Build | `pnpm build` | `bun run bun:build` |
| Typecheck | `pnpm typecheck` | `bun run bun:typecheck` |
| Test | `pnpm test` | `bun run bun:test` |

### Database

| What | Node.js | Bun |
|------|---------|-----|
| Generate migration | `pnpm db:generate` | `bun run bun:db:generate` |
| Run migration | `pnpm db:migrate` | `bun run bun:db:migrate` |

## Switching Between Runtimes

You can use both in the same project. They share the same source code:

```bash
# Morning: Node.js (stable)
pnpm dev

# Afternoon: Bun (fast iteration)
bun run bun:dev

# Switch back anytime
pnpm dev
```

Both lockfiles coexist:
- `pnpm-lock.yaml` (Node.js)
- `bun.lock` (Bun)

## Production Deployment

### Option 1: Bun Runtime

```bash
# Build
bun run bun:build

# Run
bun run bun:start
```

### Option 2: Node.js Runtime (from Bun build)

```bash
# Build with Bun (faster)
bun run bun:build

# Run with Node (battle-tested)
node server/dist/index.js
```

### Option 3: Docker (Isolated Environment)

```bash
# Start container with persistent data
docker compose -f docker-compose.bun.yml up -d

# Check logs
docker compose -f docker-compose.bun.yml logs -f

# Stop
docker compose -f docker-compose.bun.yml down
```

**Data persists in `./data/`** - safe to stop/start containers.

**Backup for migration:**
```bash
./scripts/backup-data.sh
# → data/backups/paperclip-2026-03-20.tar.gz
```

## What's Different

### Bun-specific
- No `tsx` needed (native TypeScript)
- Built-in hot reload with `--hot`
- Built-in test runner
- Faster package installs

### Same as Node.js
- API endpoints (identical)
- Database (Drizzle ORM + PGlite)
- Agent adapters
- File structure
- Configuration

## Troubleshooting

### PGlite Issues

```bash
rm -rf node_modules bun.lock
bun install
```

### Hot Reload Not Working

Use `bun:dev:server` which includes `--hot`:
```bash
bun run bun:dev:server
```

### Module Resolution Errors

Clear Bun's cache:
```bash
rm -rf ~/.bun/install/cache
bun install
```

### TypeScript Errors

Bun's TypeScript is slightly stricter. Check:
```bash
bun run bun:typecheck
```

## When to Use Bun vs Node.js

| Use Bun when | Use Node.js when |
|--------------|------------------|
| Local development | Production stability is critical |
| Apple Silicon Mac | Running on older infrastructure |
| Fast iteration cycles | Need ecosystem compatibility |
| Memory-constrained env | Debugging runtime issues |

## Verify It's Working

```bash
# Health check
curl http://localhost:3100/api/health

# Should return: {"status":"ok"}

# Check companies
curl http://localhost:3100/api/companies
```

## Resources

- [Bun Documentation](https://bun.sh/docs)
- [Bun TypeScript Support](https://bun.sh/docs/runtime/typescript)
- [Full docs](./README.md) | [Test results](./TEST_RESULTS.md) | [Troubleshooting](./TROUBLESHOOTING.md)

---

**Status**: Experimental | **Version**: Bun 1.0+ | **Updated**: 2026-03-20
