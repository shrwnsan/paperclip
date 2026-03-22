# Paperclip Adapter System

This document explains how Paperclip's multi-provider inference adapter system works and how to configure agents to use different inference providers.

## Overview

Paperclip supports multiple inference providers through a modular **adapter system**. Instead of being locked into a single provider, agents can use:

- **Claude (local)** — Claude CLI + Anthropic API (default)
- **Codex (local)** — Codex inference
- **Gemini (local)** — Google Gemini CLI
- **OpenCode (local)** — Multi-provider abstraction (supports OpenAI, Anthropic, etc.)
- **Pi (local)** — Pi agent
- **Cursor (local)** — Cursor agent
- **Process** — Run shell commands
- **HTTP** — Call custom HTTP endpoints
- **OpenClaw Gateway** — Remote OpenClaw protocol

## Adapter System Architecture

### 1. Server-Side Registry

**File:** [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts)

Each adapter is a `ServerAdapterModule` that contains:
- `execute()` — Runs inference
- `testEnvironment()` — Validates adapter prerequisites
- `sessionCodec` — Encodes/decodes agent session state
- `models` — List of available models
- `listModels()` — Discovers models dynamically
- `agentConfigurationDoc` — UI schema for adapter configuration

Example adapter registration:
```typescript
const claudeLocalAdapter: ServerAdapterModule = {
  type: "claude_local",
  execute: claudeExecute,
  testEnvironment: claudeTestEnvironment,
  sessionCodec: claudeSessionCodec,
  models: claudeModels,
  supportsLocalAgentJwt: true,
  agentConfigurationDoc: claudeAgentConfigurationDoc,
  getQuotaWindows: claudeGetQuotaWindows,
};
```

### 2. Agent Configuration Storage

**Schema:** [packages/db/src/schema/agents.ts](file:///Users/karma/Developer/forked/paperclip/packages/db/src/schema/agents.ts)

Each agent stores:
```typescript
adapterType: text("adapter_type").notNull().default("process"),
adapterConfig: jsonb("adapter_config").$type<Record<string, unknown>>(),
runtimeConfig: jsonb("runtime_config").$type<Record<string, unknown>>(),
```

- `adapterType` — Which adapter to use (e.g., `claude_local`, `codex_local`)
- `adapterConfig` — Adapter-specific secrets (API keys, model IDs, etc.)
- `runtimeConfig` — Runtime behavior (heartbeat intervals, concurrency limits)

### 3. Agent Hiring/Creation

**Route:** [server/src/routes/agents.ts#L767-L850](file:///Users/karma/Developer/forked/paperclip/server/src/routes/agents.ts#L767-L850)

When hiring an agent via `POST /api/companies/{companyId}/agent-hires`:

```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "codex_local",
  "adapterConfig": {
    "model": "claude-opus-4-1-20250805",
    "dangerouslyBypassSandbox": true
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": true,
      "intervalSec": 3600
    }
  }
}
```

The system:
1. Resolves adapter defaults via `applyCreateDefaultsByAdapterType()`
2. Normalizes secrets via `secretsSvc.normalizeAdapterConfigForPersistence()`
3. Validates constraints via `assertAdapterConfigConstraints()`
4. Creates approval record (if `requireBoardApprovalForNewAgents`)
5. Persists agent with selected adapter

## How to Configure Agents with Alternative Providers

### Option 1: UI Onboarding Wizard

**File:** [ui/src/components/OnboardingWizard.tsx](file:///Users/karma/Developer/forked/paperclip/ui/src/components/OnboardingWizard.tsx)

During onboarding (Step 2):

1. **Select Adapter Type**: Click one of the available adapter buttons:
   - **Recommended**: Claude Code, Codex
   - **More Options**: Gemini CLI, OpenCode, Pi, Cursor, Process

2. **Configure Adapter Settings**:
   - **Working directory** — Where agent keeps local state
   - **Model** — Which model variant to use (varies by adapter)
   - **Environment** — Test adapter prerequisites (validates CLI/API access)

3. **Complete**: Agent is created with the selected adapter

Current default is `claude_local`. To use a different provider:
1. Create company (Step 1)
2. Select desired adapter from the grid (Step 2)
3. Configure working directory and model
4. Run environment test to verify credentials are available
5. Complete onboarding (Step 3)

### Option 2: Direct API Call

**Endpoint:** `POST /api/companies/{companyId}/agent-hires`

Create an agent with any supported adapter:

```bash
curl -X POST http://localhost:3100/api/companies/{companyId}/agent-hires \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CEO",
    "role": "ceo",
    "adapterType": "codex_local",
    "adapterConfig": {
      "model": "claude-opus-4-1-20250805",
      "dangerouslyBypassSandbox": true
    }
  }'
```

### Option 3: Modify Existing Agent

**Endpoint:** `PATCH /api/companies/{companyId}/agents/{agentId}`

Update an agent's adapter configuration:

```bash
curl -X PATCH http://localhost:3100/api/companies/{companyId}/agents/{agentId} \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "opencode_local",
    "adapterConfig": {
      "model": "openai/gpt-4"
    }
  }'
```

## Using OpenCode for Multi-Provider Support

**Package:** [@paperclipai/adapter-opencode-local](file:///Users/karma/Developer/forked/paperclip/packages/adapters/opencode-local)

OpenCode provides a unified interface to multiple inference providers. To use it:

1. Install the `opencode` CLI locally:
   ```bash
   npm install -g opencode-cli
   # or
   pip install opencode-cli
   ```

2. Authenticate your provider:
   ```bash
   opencode auth openai  # or 'anthropic', 'google', etc.
   ```

3. Discover available models:
   ```bash
   opencode models
   ```

4. Create agent with `adapterType: "opencode_local"` and specify model in format `provider/model-id`:
   ```json
   {
     "adapterType": "opencode_local",
     "adapterConfig": {
       "model": "openai/gpt-4-turbo",
       "command": "opencode",
       "cwd": "/path/to/workspace"
     }
   }
   ```

## Custom Inference Provider Integration

For custom endpoints (like z.ai), use the **HTTP adapter**:

**Endpoint:** `POST /api/companies/{companyId}/agent-hires`

```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "http",
  "adapterConfig": {
    "url": "https://z.ai/api/inference",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer YOUR_API_KEY"
    },
    "requestTemplate": {
      "messages": "{{messages}}",
      "model": "z-model"
    }
  }
}
```

Or use **Process adapter** to invoke a custom CLI:

```json
{
  "name": "CEO",
  "role": "ceo",
  "adapterType": "process",
  "adapterConfig": {
    "command": "custom-inference-cli",
    "args": ["--provider", "z.ai"],
    "cwd": "/path/to/workspace"
  }
}
```

## Environment Testing

Before an agent runs, the adapter's `testEnvironment()` is called to verify prerequisites:

**Endpoint:** `POST /api/companies/{companyId}/agents/test-environment`

Example (Claude):
```bash
curl -X POST http://localhost:3100/api/companies/{companyId}/agents/test-environment \
  -H "Content-Type: application/json" \
  -d '{
    "adapterType": "claude_local",
    "adapterConfig": {
      "env": {
        "ANTHROPIC_API_KEY": {"type": "secret", "value": "sk-..."}
      }
    }
  }'
```

Response shows health checks:
```json
{
  "status": "pass",
  "checks": [
    {"name": "claude_available", "passed": true},
    {"name": "claude_anthropic_api_key_configured", "passed": true},
    {"name": "claude_anthropic_api_key_overrides_subscription", "passed": false}
  ]
}
```

## Adding a New Adapter

To add support for a new inference provider:

1. **Create adapter package** in `packages/adapters/{provider-name}`:
   - Implement `execute()` — Main inference logic
   - Implement `testEnvironment()` — Prerequisite validation
   - Export `agentConfigurationDoc` — UI schema
   - Export `models` array or `listModels()` function

2. **Register in server** [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts):
   ```typescript
   import { execute as myExecute, testEnvironment as myTest } from "@paperclipai/adapter-myprovider/server";
   
   const myProviderAdapter: ServerAdapterModule = {
     type: "myprovider_local",
     execute: myExecute,
     testEnvironment: myTest,
     // ... other fields
   };
   ```

3. **Register in UI** [ui/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/ui/src/adapters/registry.ts):
   - Map adapter type to UI configuration component

4. **Register in CLI** [cli/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/cli/src/adapters/registry.ts):
   - Handle streaming/output formatting for terminal display

## Troubleshooting

### Agent fails with "Adapter not found"
- Verify `adapterType` is registered in [server/src/adapters/registry.ts](file:///Users/karma/Developer/forked/paperclip/server/src/adapters/registry.ts)
- Falls back to `process` adapter for unknown types

### Environment test fails
- Run test via onboarding UI or API
- Review returned `checks` array for specific failures
- Ensure CLI/API credentials are available in the configured working directory
- For Claude: check `ANTHROPIC_API_KEY` is set correctly

### Model discovery fails (OpenCode/Pi)
- Verify CLI is installed: `which opencode` or `which pi`
- Authenticate with provider: `opencode auth openai`
- List available: `opencode models` or `pi models`
- Ensure `cwd` is set to a valid directory

## References

- [SPEC-implementation.md](file:///Users/karma/Developer/forked/paperclip/doc/SPEC-implementation.md) — Overall system design
- [Adapter packages](file:///Users/karma/Developer/forked/paperclip/packages/adapters) — Reference implementations
- [Agent hiring route](file:///Users/karma/Developer/forked/paperclip/server/src/routes/agents.ts#L767) — Full API contract
