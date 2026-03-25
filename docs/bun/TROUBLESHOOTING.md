# Bun Troubleshooting

## Common Issues

### Module Not Found

```
error: Cannot find package 'drizzle-orm'
```

**Solution**: Bun handles workspaces differently than pnpm. Reset:
```bash
rm -rf node_modules bun.lockb
bun install
```

### Port Already in Use

```bash
# Find and kill process
lsof -i :3100
kill -9 <PID>
```

### Docker Issues

```bash
# Clean rebuild
docker compose -f docker-compose.bun.yml down -v
docker system prune -a
docker compose -f docker-compose.bun.yml up --build
```

### Health Check Timeout

```bash
# Check logs
docker logs paperclip-bun

# Common causes:
# - Database not ready (wait longer)
# - Missing env vars (check .env)
# - Port conflict (change in docker-compose.bun.yml)
```

### Hot Reload Not Working

Make sure you're using the `--hot` flag:
```bash
bun --hot server/src/index.ts
```

### TypeScript Errors

Bun's TypeScript is stricter. Check:
```bash
# Clear Bun's cache
rm -rf ~/.bun/install/cache
bun install

# Run typecheck
bun run typecheck
```

### Install Fails

```bash
# Clear all caches
rm -rf node_modules bun.lockb
rm -rf ~/.bun/install/cache
bun install
```

## Hybrid Approach (If Bun Fails)

If Bun workspaces don't work for your setup:

```bash
# Install with pnpm, run with Bun
pnpm install
bun run server/src/index.ts
```

## Debugging

```bash
# Verbose output
bun --hot server/src/index.ts 2>&1 | tee bun.log

# Check Bun version
bun --version

# Test basic execution
bun -e "console.log('Bun works')"
```

## Status

| Feature | Status |
|---------|--------|
| Local development | ✅ Working |
| Docker builds | ✅ Working |
| API endpoints | ✅ Working |
| Hot reload | ✅ Working |
| Workspace deps | ⚠️ May need reset |
| Production | ⚠️ Use at own risk |
