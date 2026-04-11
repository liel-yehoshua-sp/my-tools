# ACP (Agent Client Protocol) Integration Reference

## Table of Contents
1. [What is ACP](#what-is-acp)
2. [Architecture](#architecture)
3. [Protocol Basics](#protocol-basics)
4. [ACP Methods](#acp-methods)
5. [Session Lifecycle](#session-lifecycle)
6. [Streaming Updates](#streaming-updates)
7. [Cursor-Specific Event Mapping](#cursor-specific-event-mapping)
8. [Adapter Options](#adapter-options)
9. [Building a Client](#building-a-client)
10. [Editor Integration Examples](#editor-integration-examples)

---

## What is ACP

ACP (Agent Client Protocol) is an open standard developed by JetBrains and Zed for
connecting AI coding agents to editors and other clients. It uses JSON-RPC 2.0 over
stdio with newline-delimited messages.

Think of it as: **LSP but for AI agents**. Any ACP client can talk to any ACP agent.
Cursor, Claude Code, Codex CLI, Gemini CLI, and others all speak (or can be adapted to
speak) ACP.

ACP handles the "where" (where the agent lives in your workflow), while MCP handles
the "what" (what tools and data the agent can access).

---

## Architecture

Cursor CLI does not natively speak ACP in all versions. There are two approaches:

### Option A: Native `agent acp` subcommand (if available)

Newer Cursor CLI versions may include `agent acp` which starts an ACP server
directly on stdio. Check: `cursor-agent --help` for the `acp` subcommand.

```
Your Client ──JSON-RPC/stdio──▶ cursor-agent acp
```

### Option B: Third-party ACP adapter (recommended for reliability)

Use an adapter that wraps `cursor-agent` in the ACP protocol:

```
Your Client ──JSON-RPC/stdio──▶ ACP Adapter ──spawn──▶ cursor-agent -p ... --output-format stream-json
             ◀──notifications──              ◀──events──
```

Available adapters:
- **`@blowmage/cursor-agent-acp`** (npm) — Full-featured TypeScript adapter
- **`cursor-acp`** (npm, by aLittlecrocodile) — Lightweight adapter, works with acpx
- **`cursor-agent-acp`** (Go, by spjoes) — Single binary, no Node.js dependency

---

## Protocol Basics

ACP uses JSON-RPC 2.0 over stdio. Messages are newline-delimited (`\n`).

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "session/new",
  "params": { "cwd": "/path/to/project" }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": { "sessionId": "abc-123" }
}
```

**Notification (server → client, no id):**
```json
{
  "jsonrpc": "2.0",
  "method": "session/notification",
  "params": { "sessionId": "abc-123", "update": { ... } }
}
```

---

## ACP Methods

| Method | Direction | Description |
|---|---|---|
| `initialize` | Client → Agent | Handshake. Client declares capabilities, agent responds with its own. |
| `session/new` | Client → Agent | Create a new session. Requires `cwd`. Returns `sessionId`. |
| `session/load` | Client → Agent | Attach to an existing session by ID. |
| `session/prompt` | Client → Agent | Send a prompt. Agent processes and streams updates via notifications. |
| `session/cancel` | Client → Agent | Cancel the running prompt (sends SIGTERM to the Cursor process). |
| `session/notification` | Agent → Client | Streaming update during prompt processing. |

---

## Session Lifecycle

### 1. Initialize

```json
// Client sends:
{
  "jsonrpc": "2.0",
  "id": 0,
  "method": "initialize",
  "params": {
    "protocolVersion": 1,
    "clientCapabilities": {
      "fs": { "readTextFile": true, "writeTextFile": true },
      "terminal": true
    },
    "clientInfo": { "name": "my-app", "version": "1.0.0" }
  }
}

// Agent responds:
{
  "jsonrpc": "2.0",
  "id": 0,
  "result": {
    "protocolVersion": 1,
    "agentCapabilities": {
      "loadSession": true,
      "promptCapabilities": { "image": true }
    },
    "agentInfo": { "name": "cursor-agent", "version": "..." }
  }
}
```

### 2. Create Session

```json
// Client:
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "session/new",
  "params": { "cwd": "/path/to/project" }
}

// Agent:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": { "sessionId": "sess-abc-123" }
}
```

### 3. Send Prompt

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "session/prompt",
  "params": {
    "sessionId": "sess-abc-123",
    "content": [{ "type": "text", "text": "Fix the failing tests" }]
  }
}
```

The agent starts streaming `session/notification` events and eventually
responds with a result.

### 4. Cancel (optional)

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "session/cancel",
  "params": { "sessionId": "sess-abc-123" }
}
```

---

## Streaming Updates

During `session/prompt`, the agent sends `session/notification` messages.
Each notification has an `update` field with a `type`:

### `agent_message_chunk`
Incremental text from the agent's response.

### `agent_thought_chunk`
Reasoning/thinking content.

### `tool_call` (in_progress)
Agent started using a tool (file read, write, terminal command).

### `tool_call_update` (completed)
Tool execution finished with results.

---

## Cursor-Specific Event Mapping

The ACP adapter translates Cursor CLI's stream-json events to ACP notifications:

| Cursor CLI Event | ACP Update Type |
|---|---|
| `assistant` (text content) | `agent_message_chunk` |
| `thinking` (delta) | `agent_thought_chunk` |
| `tool_call` (started) | `tool_call` (in_progress) |
| `tool_call` (completed) | `tool_call_update` (completed) |
| `result` | Resolves the prompt RPC (stop reason) |
| `error` | `agent_message_chunk` with error text |

Under the hood, the adapter runs:
```
cursor-agent -p "<prompt>" --output-format stream-json --workspace <cwd> --trust --force [--resume <session_id>]
```

The session_id from Cursor's first event is saved and reused with `--resume` on
subsequent prompts in the same ACP session.

---

## Adapter Options

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CURSOR_AGENT_BIN` | `agent` or `cursor-agent` | Path to the Cursor CLI binary |
| `CURSOR_ACP_TIMEOUT_MS` | `300000` | Per-prompt timeout in milliseconds |
| `CURSOR_API_KEY` | — | API key for headless authentication |

---

## Building a Client

### Node.js ACP Client Example

```javascript
const { spawn } = require('child_process');
const readline = require('readline');

class CursorACPClient {
  constructor(adapterCommand = 'cursor-agent-acp') {
    this.nextId = 0;
    this.pending = new Map();
    this.onNotification = null;

    this.proc = spawn(adapterCommand, [], {
      stdio: ['pipe', 'pipe', 'inherit'],
      env: { ...process.env },
    });

    const rl = readline.createInterface({ input: this.proc.stdout });
    rl.on('line', (line) => this._handleMessage(JSON.parse(line)));
  }

  _handleMessage(msg) {
    if (msg.id !== undefined && this.pending.has(msg.id)) {
      // Response to a request
      const { resolve, reject } = this.pending.get(msg.id);
      this.pending.delete(msg.id);
      if (msg.error) reject(new Error(msg.error.message));
      else resolve(msg.result);
    } else if (msg.method === 'session/notification') {
      // Streaming notification
      if (this.onNotification) this.onNotification(msg.params);
    }
  }

  _send(method, params) {
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      this.pending.set(id, { resolve, reject });
      const msg = JSON.stringify({ jsonrpc: '2.0', id, method, params });
      this.proc.stdin.write(msg + '\n');
    });
  }

  async initialize(clientInfo = { name: 'my-app', version: '1.0.0' }) {
    return this._send('initialize', {
      protocolVersion: 1,
      clientCapabilities: { fs: { readTextFile: true, writeTextFile: true }, terminal: true },
      clientInfo,
    });
  }

  async newSession(cwd) {
    return this._send('session/new', { cwd });
  }

  async prompt(sessionId, text) {
    return this._send('session/prompt', {
      sessionId,
      content: [{ type: 'text', text }],
    });
  }

  async cancel(sessionId) {
    return this._send('session/cancel', { sessionId });
  }

  close() {
    this.proc.kill('SIGTERM');
  }
}
```

### Usage

```javascript
const client = new CursorACPClient();

// Listen for streaming updates
client.onNotification = (params) => {
  const { update } = params;
  if (update.type === 'agent_message_chunk') {
    process.stdout.write(update.text);
  }
};

await client.initialize();
const { sessionId } = await client.newSession('/path/to/project');
const result = await client.prompt(sessionId, 'Fix the failing tests');
console.log('Done:', result);
client.close();
```

---

## Editor Integration Examples

### Zed Configuration

```json
// ~/.config/zed/settings.json
{
  "agent_servers": {
    "cursor-agent": {
      "command": "cursor-agent-acp",
      "args": [],
      "env": {}
    }
  }
}
```

Or with npx (no global install):
```json
{
  "agent_servers": {
    "cursor-agent": {
      "command": "npx",
      "args": ["@blowmage/cursor-agent-acp"],
      "env": {}
    }
  }
}
```

### JetBrains IDEs

Cursor is available in the ACP Registry for JetBrains IDEs (version 25.3+).
You can install it directly from the agent picker in AI Chat, or configure
it manually in Settings → Tools → AI Assistant → Agents.

### Custom Editor / App

Any app that speaks JSON-RPC over stdio can integrate:
1. Spawn the ACP adapter process
2. Send `initialize`, then `session/new`
3. Send `session/prompt` and listen for `session/notification`
4. Concatenate `agent_message_chunk` updates for the response
