# Testing Paperclip Without an Anthropic API Key

This guide covers how to test Paperclip's agent system without requiring an Anthropic API key for the CEO agent.

## Your Current Situation

You're running Paperclip with:
- ✅ Bun v1.3.11
- ✅ Local dev mode (`local_trusted` auth)
- ✅ Embedded PostgreSQL
- ✅ CEO agent created
- ❌ CEO agent needs Claude CLI auth (requires Anthropic API key)
- ✅ You want to use z.ai or custom inference provider instead

## Quick Solutions

### Solution 1: Use Process Adapter (Recommended for testing)

The **Process adapter** allows you to run any shell command as an "agent". Perfect for testing without external API keys.

**Via Onboarding UI:**
1. Go to Step 2 of onboarding
2. Click "More Agent Adapter Types"
3. Select **Process**
4. Set `Working directory` (required)
5. Set `Command` (e.g., `echo`, `bash`, `python script.py`)
6. Click "Test environment"
7. Complete onboarding

**Example: Mock inference via shell script**

Create `~/paperclip-agents/mock-inference.sh`:
```bash
#!/bin/bash
# Mock inference script
# Input: stdin with JSON task
# Output: JSON response

while read line; do
  echo "Completed task: $line" >&2
done

cat << 'EOF'
{
  "type": "tool_call",
  "result": "Mock processing complete"
}
EOF
```

Then configure CEO agent:
```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "process",
  "adapterConfig": {
    "command": "bash",
    "args": ["~/paperclip-agents/mock-inference.sh"],
    "cwd": "~/paperclip-agents"
  }
}
```

**Advantages:**
- ✅ No API keys needed
- ✅ Full control over agent behavior
- ✅ Fast iteration for testing
- ✅ Can mock specific responses

**Disadvantages:**
- ❌ Not real inference
- ❌ For testing/mocking only

---

### Solution 2: Use OpenCode with Free/Open Provider

**OpenCode** provides a unified interface to multiple providers. Use it with:
- **Open AI (free tier)** — Limited but free
- **Local models** — llama.cpp, ollama, vLLM
- **Open endpoints** — Together AI, Replicate (free trials)

**Setup:**

1. Install OpenCode:
   ```bash
   npm install -g opencode-cli
   # or
   pip install opencode-cli
   ```

2. Authenticate with a free provider (example: Ollama local model):
   ```bash
   opencode auth local
   # or with Together AI:
   opencode auth together
   export TOGETHER_API_KEY="your-free-tier-key"
   ```

3. List available models:
   ```bash
   opencode models
   ```

4. Create CEO agent via onboarding:
   - **Step 2**: Select **OpenCode**
   - **Model**: Choose from discovered models (e.g., `ollama/llama2`, `together/meta-llama/Llama-2-7b`)
   - **Working directory**: Set to `~/paperclip-agents`
   - **Test environment**: Should pass if your provider is authenticated
   - Complete onboarding

**Example config:**
```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "opencode_local",
  "adapterConfig": {
    "model": "ollama/neural-chat",
    "command": "opencode",
    "cwd": "~/paperclip-agents"
  }
}
```

**Advantages:**
- ✅ Real inference (though limited quality)
- ✅ Multiple provider options
- ✅ Works with local models (ollama, vLLM)
- ✅ Free tier options available

**Disadvantages:**
- ❌ Requires setting up local models or creating free accounts
- ❌ Model quality may be lower than Claude
- ⚠️ Some providers have rate limits

---

### Solution 3: Use HTTP Adapter for z.ai

If z.ai has an HTTP API endpoint, use the **HTTP adapter**:

```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "http",
  "adapterConfig": {
    "url": "https://api.z.ai/v1/inference",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer YOUR_Z_AI_TOKEN",
      "Content-Type": "application/json"
    },
    "requestTemplate": {
      "messages": "{{messages}}",
      "model": "z-model-id"
    }
  }
}
```

**Advantages:**
- ✅ Direct integration with z.ai
- ✅ Customizable request/response handling

**Disadvantages:**
- ❌ Requires z.ai HTTP API documentation
- ❌ May need custom payload transformation
- ⚠️ Limited by HTTP adapter implementation

---

### Solution 4: Add Custom Codex/Gemini Adapter

If you have **Codex** or **Gemini** CLI installed locally:

**Codex (local):**
```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "codex_local",
  "adapterConfig": {
    "model": "claude-opus-4-1-20250805",
    "dangerouslyBypassSandbox": true,
    "cwd": "~/paperclip-agents"
  }
}
```

**Gemini (local):**
```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "gemini_local",
  "adapterConfig": {
    "model": "gemini-2.0-flash",
    "cwd": "~/paperclip-agents"
  }
}
```

---

## How to Switch an Existing Agent's Adapter

If you already created a CEO agent with Claude but want to switch providers:

**Via API:**
```bash
curl -X PATCH http://localhost:3100/api/companies/{companyId}/agents/{agentId} \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "process",
    "adapterConfig": {
      "command": "bash",
      "args": ["/path/to/mock.sh"],
      "cwd": "~/paperclip-agents"
    }
  }'
```

**Via UI:**
1. Navigate to the agent in the UI
2. Edit the agent
3. Change `Adapter Type` field
4. Update adapter configuration
5. Save

---

## Recommended Approach for Your Situation

Given your constraints:
1. **Best for quick testing**: Use **Process adapter** with a mock script
2. **Best for realistic testing**: Use **OpenCode** with Ollama (local models)
3. **Best for long-term**: Set up with z.ai's HTTP endpoint

### Quick Test Setup

```bash
# 1. Create a mock inference script
mkdir -p ~/paperclip-agents
cat > ~/paperclip-agents/mock-ceo.sh << 'EOF'
#!/bin/bash
# Mock CEO agent responses
input=$(cat)
echo "Processing: $input" >&2
echo '{"status":"completed","response":"Mock task completed"}'
EOF
chmod +x ~/paperclip-agents/mock-ceo.sh

# 2. Start Paperclip
cd /Users/karma/Developer/forked/paperclip
bun run server/src/index.ts

# 3. Open UI and onboard
# - Create company
# - Step 2: Select "Process" adapter
# - Set working directory: ~/paperclip-agents
# - Set command: bash
# - Set args: ["/Users/karma/paperclip-agents/mock-ceo.sh"]
# - Test environment (should pass)
# - Complete onboarding

# 4. CEO agent now runs mock inference!
```

---

## Adapter Fallback Behavior

If an agent's configured adapter is not found:
- Falls back to **Process adapter** automatically
- Useful for graceful degradation
- Check server logs for warnings

---

## Next Steps

1. **Choose your approach** (Process, OpenCode, HTTP, or custom)
2. **Implement the adapter configuration**
3. **Test via onboarding UI** or API
4. **Run your CEO agent task** — should now work without Anthropic key

## References

- [ADAPTER_SYSTEM.md](file:///Users/karma/Developer/forked/paperclip/doc/ADAPTER_SYSTEM.md) — Full adapter system documentation
- [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts) — Available adapters
- [packages/adapters](file:///Users/karma/Developer/forked/paperclip/packages/adapters) — Adapter implementations
