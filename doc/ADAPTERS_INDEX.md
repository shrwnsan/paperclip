# Paperclip Adapters Documentation Index

Complete guide to Paperclip's multi-provider agent inference system.

## 📚 Documentation Files

### 1. [ADAPTER_SYSTEM.md](ADAPTER_SYSTEM.md) — Full Architecture Guide
**Read this for:** Deep understanding of how adapters work

- Complete adapter system architecture
- How the system discovers and loads adapters
- Server registry structure and design
- Agent configuration storage
- Agent hiring/creation workflow
- Environment testing framework
- How to add a new adapter

**Audience:** Developers, architects, anyone extending the system

---

### 2. [TESTING_WITHOUT_ANTHROPIC_KEY.md](TESTING_WITHOUT_ANTHROPIC_KEY.md) — Setup & Solutions
**Read this for:** Practical setup guides

- Your current situation analysis
- 4 recommended solutions ranked by complexity
- **Solution 1: Process Adapter** (recommended for testing)
- **Solution 2: OpenCode** (recommended for realistic testing)
- **Solution 3: HTTP Adapter** (for custom endpoints)
- **Solution 4: Codex/Gemini** (if you have them installed)
- How to switch existing agent's adapter
- Quick test setup with example scripts

**Audience:** Users trying to test without API keys

---

### 3. [ADAPTER_QUICK_REFERENCE.md](ADAPTER_QUICK_REFERENCE.md) — Copy-Paste Commands
**Read this for:** Fast implementation

- Pre-built shell commands for each approach
- Exact API calls to update agents
- Step-by-step CLI walkthroughs
- Verification commands
- Troubleshooting checklist

**Audience:** Users who want quick commands

---

## 🎯 Quick Start by Use Case

### "I need to test without an API key RIGHT NOW"
1. Read: [TESTING_WITHOUT_ANTHROPIC_KEY.md](TESTING_WITHOUT_ANTHROPIC_KEY.md) (2 min)
2. Use: [ADAPTER_QUICK_REFERENCE.md](ADAPTER_QUICK_REFERENCE.md) (5 min)
3. Run: Copy-paste the Process Adapter commands
4. Done! ✅

### "I want to understand how this works"
1. Read: [ADAPTER_SYSTEM.md](ADAPTER_SYSTEM.md) (15 min)
2. Review: [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts)
3. Explore: [packages/adapters](file:///Users/karma/Developer/forked/paperclip/packages/adapters) (sample implementations)
4. Done! ✅

### "I want to add a custom adapter"
1. Read: [ADAPTER_SYSTEM.md](ADAPTER_SYSTEM.md) section "Adding a New Adapter"
2. Check: [packages/adapters/process](file:///Users/karma/Developer/forked/paperclip/packages/adapters/process) (simple reference)
3. Follow: The 4-step process in the architecture doc
4. Register: In [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts), UI, and CLI
5. Done! ✅

### "I want to configure an alternative provider (z.ai)"
1. Check: z.ai API documentation (do they have HTTP REST API?)
2. If yes: Use [HTTP Adapter](ADAPTER_QUICK_REFERENCE.md#option-c-switch-to-http-adapter-for-zai)
3. If no (CLI only): Use [Process Adapter](ADAPTER_QUICK_REFERENCE.md#option-a-switch-to-process-adapter-mock-testing) or wrapper script
4. Update: Agent config via API or UI
5. Done! ✅

---

## 🏗️ System Overview

```
┌─────────────────────────────────────────┐
│         UI (OnboardingWizard)           │
│  Step 2: Select adapter type & config   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     API Routes (POST /agent-hires)      │
│  Validates config, tests environment   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Database (agents table)               │
│  Store: adapterType + adapterConfig     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Server Registry                        │
│  Load correct adapter by type           │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
    ┌───▼──┐      ┌──▼────┐
    │Claude│      │Process │  + 7 more adapters
    └──────┘      └────────┘
        │             │
        └──────┬──────┘
               │
    ┌──────────▼─────────────┐
    │  Workspace Runtime      │
    │  execute(agent, task)   │
    └────────────────────────┘
```

---

## 📋 Available Adapters

| Adapter | Type | Use Case | Setup Difficulty |
|---------|------|----------|-----------------|
| **Claude (local)** | `claude_local` | Default inference via Anthropic | Medium (needs API key) |
| **Codex** | `codex_local` | Alternative inference | Medium (CLI + config) |
| **Gemini** | `gemini_local` | Google Gemini inference | Medium (CLI + auth) |
| **OpenCode** | `opencode_local` | Multi-provider abstraction | Medium (CLI + provider auth) |
| **Pi** | `pi_local` | Pi agent inference | Medium (CLI + config) |
| **Cursor** | `cursor_local` | Cursor agent inference | Medium (CLI + config) |
| **Process** | `process` | Shell command execution | **Easy** (any bash command) |
| **HTTP** | `http` | Custom HTTP endpoints | Easy (just URL + headers) |
| **OpenClaw Gateway** | `openclaw_gateway` | Remote OpenClaw protocol | Hard (gateway setup) |

---

## 🔧 Common Operations

### Test Adapter Prerequisites
```bash
curl -X POST http://localhost:3100/api/companies/{companyId}/agents/test-environment \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "process",
    "adapterConfig": {"command": "bash", "cwd": "/path/to/workspace"}
  }'
```

### Update Agent's Adapter
```bash
curl -X PATCH http://localhost:3100/api/companies/{companyId}/agents/{agentId} \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "process",
    "adapterConfig": {"command": "bash", "args": ["script.sh"], "cwd": "/path"}
  }'
```

### Discover Available Models
```bash
curl http://localhost:3100/api/companies/{companyId}/agents/adapter-models/{adapterType}
```

### List All Agents
```bash
curl http://localhost:3100/api/companies/{companyId}/agents
```

---

## 🚀 Recommended Implementation Path

1. **Immediate (Now)**: Switch CEO to Process adapter for testing
2. **Short-term (This week)**: Explore OpenCode with free provider
3. **Medium-term (Later)**: Integrate with z.ai via HTTP adapter
4. **Long-term**: Consider custom adapter if needed

---

## 🔗 Key Source Files

- **Registry**: [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts)
- **Agent Schema**: [packages/db/src/schema/agents.ts](file:///Users/karma/Developer/forked/paperclip/packages/db/src/schema/agents.ts)
- **Agent Hiring Routes**: [server/src/routes/agents.ts#L767](file:///Users/karma/Developer/forked/paperclip/server/src/routes/agents.ts#L767)
- **Onboarding UI**: [ui/src/components/OnboardingWizard.tsx](file:///Users/karma/Developer/forked/paperclip/ui/src/components/OnboardingWizard.tsx)
- **Process Adapter**: [packages/adapters/process](file:///Users/karma/Developer/forked/paperclip/packages/adapters/process) (reference implementation)
- **Claude Adapter**: [packages/adapters/claude-local](file:///Users/karma/Developer/forked/paperclip/packages/adapters/claude-local) (full implementation)

---

## ❓ FAQ

**Q: Can I switch an agent's adapter without recreating it?**
A: Yes! Just PATCH the agent with new `adapterType` and `adapterConfig`.

**Q: Do I need to change code to use a different adapter?**
A: No. Configuration only. Adapters are registered at server startup.

**Q: What happens if I use an adapter that requires authentication?**
A: Environment test will fail. You must provide the required credentials in `adapterConfig`.

**Q: Can I have multiple agents with different adapters?**
A: Yes! Each agent independently stores its `adapterType` and `adapterConfig`.

**Q: Is the adapter system extensible?**
A: Yes! Add new adapters by implementing the `ServerAdapterModule` interface and registering in the registry.

**Q: What's the recommended adapter for testing?**
A: **Process adapter** (no auth needed) or **OpenCode with free provider** (real inference).

---

## 📖 Reading Order

1. **Just want to test?** → [TESTING_WITHOUT_ANTHROPIC_KEY.md](TESTING_WITHOUT_ANTHROPIC_KEY.md) → [ADAPTER_QUICK_REFERENCE.md](ADAPTER_QUICK_REFERENCE.md)

2. **Want to understand?** → [ADAPTER_SYSTEM.md](ADAPTER_SYSTEM.md) → Review source code

3. **Want to extend?** → [ADAPTER_SYSTEM.md](ADAPTER_SYSTEM.md) section "Adding a New Adapter" → Review existing adapters

---

## 📝 Last Updated

March 22, 2026 — Created during Bun runtime completion. All documentation current with main codebase.

---

**Need help?** Check the specific guide for your use case above. If stuck:
1. Verify your IDs (company, agent)
2. Run environment test to identify issues
3. Check agent config matches adapter requirements
4. Review error messages in server logs
