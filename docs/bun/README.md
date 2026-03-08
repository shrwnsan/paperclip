# Bun Runtime Support for Paperclip

> Experimental Bun runtime support, optimized for Apple Silicon (M1/M2/M3/M4) MacBooks

## 📚 Documentation

| Document | Description | Use Case |
|----------|-------------|----------|
| **[SUMMARY.md](./SUMMARY.md)** | Complete overview & quick start | Start here! |
| **[BUN.md](./BUN.md)** | Full usage documentation | Detailed guide |
| **[TEST_RESULTS.md](./TEST_RESULTS.md)** | Performance benchmarks | See the numbers |
| **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** | Issue resolution | Fix problems |
| **[SETUP_COMPLETE.md](./SETUP_COMPLETE.md)** | Setup completion guide | Reference |

## 🚀 Quick Start

```bash
# Navigate to worktree
cd .worktrees/feat-bun-runtime

# Run setup
./scripts/setup-bun.sh

# Start development
bun --hot server/src/index.ts
```

## 📊 Performance Results

| Metric | Node.js | Bun | Improvement |
|--------|---------|-----|-------------|
| Cold start | 14ms | 8ms | **1.75x faster** |
| Package.json | 14ms | 7ms | **2.0x faster** |
| TypeScript | ~20ms | 6ms | **3.3x faster** |

## ✅ Status

- 🟢 **Working**: Bun runtime, TypeScript support, performance improvements
- 🟡 **Known Issues**: Workspace dependencies (run from root), embedded PostgreSQL
- 📝 **Branch**: `feat/bun-runtime`
- 📁 **Worktree**: `.worktrees/feat-bun-runtime/`

## 📖 Reading Order

1. **SUMMARY.md** - Get the complete overview
2. **BUN.md** - Learn how to use Bun with Paperclip
3. **TEST_RESULTS.md** - See performance benchmarks
4. **TROUBLESHOOTING.md** - Resolve any issues

## 🔗 Related Files

- `bunfig.toml` - Bun configuration (root directory)
- `scripts/setup-bun.sh` - Automated setup script
- `scripts/benchmark-bun.sh` - Performance testing

---

**Status**: ✅ Ready for Apple Silicon testing
**Version**: Bun 1.3.10+
**Last Updated**: 2026-03-08
