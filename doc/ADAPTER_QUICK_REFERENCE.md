# Adapter Quick Reference

Fast copy-paste commands to switch your CEO agent's inference provider.

## Current Setup

You're running Paperclip with:
- API: `http://localhost:3100`
- Auth: `local_trusted` (no login needed)
- Company created with CEO agent using `claude_local`

## Get Your IDs

```bash
# Get company ID (should be in URL or health response)
curl http://localhost:3100/api/health

# List agents in company
curl http://localhost:3100/api/companies/{companyId}/agents

# Note agent ID (the CEO agent)
```

## Option A: Switch to Process Adapter (Mock Testing)

### 1. Create mock script
```bash
mkdir -p ~/paperclip-agents
cat > ~/paperclip-agents/mock-ceo.sh << 'EOF'
#!/bin/bash
# Mock CEO agent
echo "Processing request" >&2
cat << 'RESP'
{"status": "completed", "message": "Task completed by mock CEO"}
RESP
EOF
chmod +x ~/paperclip-agents/mock-ceo.sh
```

### 2. Update existing CEO agent
```bash
COMPANY_ID="your-company-id"
AGENT_ID="your-agent-id"

curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "process",
    "adapterConfig": {
      "command": "bash",
      "args": ["/Users/karma/paperclip-agents/mock-ceo.sh"],
      "cwd": "/Users/karma/paperclip-agents"
    }
  }'
```

### 3. Test it
```bash
# Agent should now run with process adapter
# No Anthropic key needed!
```

---

## Option B: Switch to OpenCode Adapter (Real Inference)

### 1. Install OpenCode CLI
```bash
npm install -g opencode-cli
# or: pip install opencode-cli
```

### 2. Authenticate with free provider (e.g., Together.ai)
```bash
# Sign up free at https://www.together.ai
export TOGETHER_API_KEY="your-free-key-here"

# Test discovery
opencode models | grep together
```

### 3. Update CEO agent
```bash
COMPANY_ID="your-company-id"
AGENT_ID="your-agent-id"
MODEL="together/meta-llama/Llama-2-7b"  # or another free model

curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -H "Content-Type: application/json" \
  -d "{
    \"adapterType\": \"opencode_local\",
    \"adapterConfig\": {
      \"model\": \"${MODEL}\",
      \"command\": \"opencode\",
      \"cwd\": \"/Users/karma/paperclip-agents\"
    }
  }"
```

### 4. Test adapter
```bash
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/agents/test-environment \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "opencode_local",
    "adapterConfig": {
      "model": "together/meta-llama/Llama-2-7b",
      "command": "opencode",
      "cwd": "/Users/karma/paperclip-agents"
    }
  }'
```

---

## Option C: Switch to Codex Adapter

### 1. Install Codex CLI (if not already)
```bash
which codex
# Install: npm install -g codex-cli (or your method)
```

### 2. Update CEO agent
```bash
COMPANY_ID="your-company-id"
AGENT_ID="your-agent-id"

curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "codex_local",
    "adapterConfig": {
      "model": "claude-opus-4-1-20250805",
      "dangerouslyBypassSandbox": true,
      "cwd": "/Users/karma/paperclip-agents"
    }
  }'
```

---

## Option D: Create New Agent with Different Adapter

Instead of modifying existing, create a fresh agent:

```bash
COMPANY_ID="your-company-id"

# Create Process-based agent
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/agent-hires \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test CEO",
    "role": "ceo",
    "adapterType": "process",
    "adapterConfig": {
      "command": "echo",
      "args": ["Task completed"],
      "cwd": "/Users/karma/paperclip-agents"
    }
  }'
```

---

## Verify Your Changes

### Check agent config
```bash
COMPANY_ID="your-company-id"
AGENT_ID="your-agent-id"

curl http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID}
```

Expected output shows updated `adapterType`.

### Test environment
```bash
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/agents/test-environment \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "process",
    "adapterConfig": {
      "command": "bash",
      "cwd": "/Users/karma/paperclip-agents"
    }
  }'
```

Should return:
```json
{
  "status": "pass",
  "checks": [
    {"name": "command_available", "passed": true},
    {"name": "cwd_exists", "passed": true}
  ]
}
```

---

## Troubleshooting

### 401/403 Error
- Check you're accessing on `localhost:3100`
- Running in `local_trusted` mode? (should auto-auth)
- If authenticated mode, need board token

### 404 Agent Not Found
- Verify `{agentId}` is correct
- Check agent belongs to company: `GET /api/companies/{companyId}/agents`

### Environment test fails
- For process: Verify command exists (`which bash`, `which echo`)
- For opencode: Run `opencode models` to confirm CLI works
- Check `cwd` directory exists

### Agent still trying to use Claude
- Verify PATCH request succeeded (check response)
- Restart server if needed: `Ctrl+C` and restart Bun server
- Check agent config with GET request

---

## See Also

- [ADAPTER_SYSTEM.md](file:///Users/karma/Developer/forked/paperclip/doc/ADAPTER_SYSTEM.md) — Full documentation
- [TESTING_WITHOUT_ANTHROPIC_KEY.md](file:///Users/karma/Developer/forked/paperclip/doc/TESTING_WITHOUT_ANTHROPIC_KEY.md) — Detailed setup guide
- [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts) — All available adapters
