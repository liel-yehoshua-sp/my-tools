---
name: cursor-integration
description: >
  Build apps that integrate with Cursor's AI coding agent — trigger AI jobs from external apps, CI/CD,
  webhooks, or custom tooling via Cursor CLI headless mode and ACP (Agent Client Protocol). Use this skill
  whenever the user mentions Cursor CLI integration, headless Cursor, Cursor agent automation, spawning
  Cursor jobs programmatically, building apps that use Cursor as a backend agent, ACP with Cursor,
  cursor-agent scripting, parsing Cursor output, CI/CD with Cursor, or Cursor agents in Docker/VMs.
  Also trigger on "use Cursor from my app", "automate Cursor", "Cursor headless", "trigger Cursor agent",
  "cursor-agent in scripts", "ACP adapter", "cursor-acp", "background Cursor agents", or any system
  that programmatically controls Cursor. Covers the CLI approach (spawn cursor-agent) and ACP (JSON-RPC
  over stdio).
---

# Cursor Integration Skill

Build apps and systems that programmatically trigger and control Cursor's AI coding agent.

There are **two main integration paths**:

1. **Headless CLI** — Spawn `cursor-agent` with `--print` mode for fire-and-forget or streaming jobs.
   Best for scripts, CI/CD pipelines, webhooks, and simple automation.

2. **ACP (Agent Client Protocol)** — Use JSON-RPC over stdio for full session management, streaming,
   and bidirectional control. Best for IDEs, editors, orchestrators, and rich integrations.

Read the relevant reference file before building:
- For headless CLI integration → read `references/headless-cli.md`
- For ACP protocol integration → read `references/acp-protocol.md`
- For common patterns (auth, error handling, streaming parsers) → read `references/common-patterns.md`

---

## Quick Decision Guide

Ask the user what they're building. Use this to pick the right path:

| Use Case | Approach | Why |
|---|---|---|
| CI/CD pipeline step | Headless CLI | One-shot, no session state needed |
| Webhook handler (GitHub, Slack) | Headless CLI | Spawn agent per event, parse result |
| Custom IDE / editor plugin | ACP | Full session lifecycle, streaming UI |
| Orchestrator controlling multiple agents | ACP | Session management, cancel support |
| Background job queue | Headless CLI | Workers spawn agent per job |
| Interactive app with live streaming | ACP | Real-time chunks via notifications |
| Simple script / cron job | Headless CLI | Minimal setup |

---

## Prerequisites

Every Cursor integration needs:

1. **Cursor CLI installed** — `curl https://cursor.com/install -fsSL | bash`
   - Binary is called `cursor-agent` (or `agent` on some systems)
   - Verify: `cursor-agent --version`

2. **Authentication** — One of:
   - `CURSOR_API_KEY` environment variable (get from https://cursor.com/dashboard?tab=background-agents)
   - `--api-key <key>` flag per invocation
   - Prior `cursor-agent login` (interactive, not for headless)

3. **Cursor subscription** — The CLI uses your subscription's model access. Any model available in your plan works.

---

## Architecture Patterns

### Pattern 1: Fire-and-Forget (Headless CLI)

Your app spawns `cursor-agent -p "prompt" --output-format json` as a child process,
waits for it to exit, and reads the single JSON result from stdout.

```
Your App ──spawn──▶ cursor-agent -p "..." --output-format json
                   ◀──stdout── { "type": "result", ... }
```

### Pattern 2: Streaming Progress (Headless CLI)

Same as above but with `--output-format stream-json`. You get NDJSON events
line-by-line as the agent works — deltas, tool calls, and a final result event.

```
Your App ──spawn──▶ cursor-agent -p "..." --output-format stream-json
                   ◀──line 1── { "type": "system", "subtype": "init", ... }
                   ◀──line 2── { "type": "assistant", "message": { ... } }
                   ◀──line N── { "type": "result", "subtype": "success", ... }
```

### Pattern 3: Session-Based (ACP)

Your app communicates with an ACP adapter process over stdin/stdout using JSON-RPC.
Supports full session lifecycle: create, prompt, cancel, resume.

```
Your App ──JSON-RPC──▶ ACP Adapter ──spawn──▶ cursor-agent -p ... --output-format stream-json
         ◀──notify──               ◀──events──
```

---

## Key Flags Reference

These are the critical `cursor-agent` flags for integration:

| Flag | Purpose |
|---|---|
| `-p, --print` | Non-interactive mode. Required for headless/scripted use. |
| `--output-format <fmt>` | `json` (single result), `stream-json` (NDJSON events), `text` (human-readable). Default: `stream-json` |
| `-f, --force` | Allow file modifications in print mode. Without this, changes are only proposed, not applied. |
| `-m, --model <name>` | Select model (e.g., `gpt-5`, `claude-sonnet-4`, `auto`). |
| `--workspace <path>` | Set working directory for the agent. |
| `--trust` | Trust the workspace directory (skip confirmation). |
| `--resume <session-id>` | Resume a previous conversation by session ID. |
| `--api-key <key>` | API key (alternative to `CURSOR_API_KEY` env var). |
| `-H, --header "Name: Value"` | Add custom headers to agent requests. |

---

## Important Caveats

These are real-world gotchas discovered by the community. Mention them proactively:

1. **Cold start delay** — First invocation can take 30-60 seconds. Subsequent calls are faster. For CI/CD, consider a warm-up step.

2. **Hanging after completion** — The CLI can sometimes hang indefinitely after responding, even in `--print` mode. Always implement a timeout (e.g., `CURSOR_ACP_TIMEOUT_MS` or process-level timeout).

3. **No stdin pipe for prompts** — You can't pipe prompts via stdin. Use command substitution: `cursor-agent -p "$(cat prompt.txt)"`.

4. **MCP requires trust** — The CLI may require an initial interactive session to enable MCP usage and trust the working directory. Pre-create `~/.cursor/mcp-approvals.json` for headless MCP use.

5. **Windows requires WSL** — No native Windows support. Use WSL.

6. **`--force` is required for writes** — In print mode, without `--force`, file changes are proposed but not applied.

7. **`agent acp` subcommand** — Cursor recently added a native `agent acp` subcommand but it may not be available in all CLI versions. Check `cursor-agent --help` for availability. If missing, use a third-party ACP adapter like `cursor-agent-acp` (npm) or `cursor-acp`.

---

## What to Build

After the user describes their integration, help them build it step by step. Key deliverables typically include:

1. **A wrapper module** that spawns `cursor-agent` and parses output
2. **Error handling** with timeouts and retry logic
3. **Auth configuration** (API key management)
4. **Output parser** for the chosen format (JSON or stream-JSON)
5. **Session management** if using ACP or `--resume`

Always reference the appropriate file under `references/` for detailed implementation guidance.
