# Plugin Trust Model

## Overview

Paperclip plugins are **trusted code**. Installation grants full access to the plugin's capabilities. This is analogous to npm packages or VS Code extensions—users are expected to vet and trust plugins before installing them.

## Security Boundaries

### Server-Side Runtime

Plugin code executes in the Node.js server process via `vm.createContext()` for module sandboxing.

**Important**: Per [Node.js documentation](https://nodejs.org/en/docs/guides/security/#the-node-vm-module), `vm.createContext` is **not a security boundary**. It provides module isolation, not process isolation.

**Current mitigations**:
- Board-only installation: Only admin users can install plugins
- Module allow-listing: Plugin require/import statements are validated against a whitelist
- Capability validation: Plugin manifests declare capabilities, which gate host RPC access

**Risk**: Plugin code has full access to Node.js APIs, environment variables, and the filesystem within the process permissions. Malicious plugins can read secrets, modify state, or attack other companies' data (if company isolation is incomplete).

### Client-Side UI Runtime

Plugin UI bundles execute as JavaScript in the host page context via dynamic `import(blobUrl)`.

**Current isolation**: None. Plugin UI runs with the same origin, DOM access, and local storage as the Paperclip board UI.

**Current mitigation**:
- Board installation gate: Only admin-installed plugins are loaded

**Risk**: Malicious plugin UI code can access board data, intercept requests, read cookies, and exfiltrate information.

## Trust Model

Plugins are treated as **trusted deployments**, not adversarial code. The security model relies on:

1. **Installation gating** — Only board operators (admins) can install plugins
2. **Vetting responsibility** — Operators must inspect and trust plugin sources before installation
3. **Company isolation** — Plugins operate within a single company context and cannot cross boundaries

Plugins are not sandboxed from:
- The server process or filesystem
- The host page DOM and storage
- Other plugins or company data (if vetting fails)

## Future Hardening Options

For future releases, consider:

- **Server-side**: Isolate plugin code to `worker_threads` with restricted module access and IPC-only communication
- **Client-side**: Load plugin UI in an `<iframe sandbox="allow-scripts">` with `postMessage()` bridge for host communication, combined with `script-src` CSP restrictions
- **Both**: Require explicit capability signing and runtime attestation of plugin code

See [PLUGIN_SPEC.md](./PLUGIN_SPEC.md) for the full plugin architecture.
