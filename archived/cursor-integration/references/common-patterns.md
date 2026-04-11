# Common Integration Patterns

## Table of Contents
1. [Authentication](#authentication)
2. [Error Handling](#error-handling)
3. [Timeout Management](#timeout-management)
4. [Webhook Handler Pattern](#webhook-handler-pattern)
5. [Job Queue Pattern](#job-queue-pattern)
6. [Docker / VM Deployment](#docker--vm-deployment)
7. [MCP Server Configuration](#mcp-server-configuration)
8. [Rules and Project Configuration](#rules-and-project-configuration)
9. [Permissions and Security](#permissions-and-security)

---

## Authentication

### API Key (recommended for headless)

Get your key from: https://cursor.com/dashboard?tab=background-agents

```bash
# Environment variable (preferred)
export CURSOR_API_KEY=your_api_key_here

# Or per-invocation flag
cursor-agent -p "..." --api-key your_api_key_here
```

In code, always prefer environment variables over hardcoded keys:

```javascript
// Node.js
const proc = spawn('cursor-agent', args, {
  env: { ...process.env, CURSOR_API_KEY: process.env.CURSOR_API_KEY },
});
```

```python
# Python
env = {**os.environ, 'CURSOR_API_KEY': os.getenv('CURSOR_API_KEY')}
subprocess.run(cmd, env=env)
```

### Login-based (interactive only)

For development/testing, you can use interactive login:
```bash
cursor-agent login
```
This stores credentials locally. Not suitable for CI/CD or server deployments.

---

## Error Handling

### Exit Codes

- `0` — Success
- Non-zero — Failure. Error message written to stderr.

### Robust Error Handling Pattern

```javascript
async function safeCursorRun(prompt, options = {}) {
  const maxRetries = options.retries || 2;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const result = await runCursorAgent(prompt, {
        timeoutMs: options.timeoutMs || 300000,
        ...options,
      });

      if (result.is_error) {
        throw new Error(`Agent reported error: ${result.result}`);
      }

      return result;
    } catch (err) {
      const isTimeout = err.message.includes('timed out');
      const isTransient = err.message.includes('ECONNRESET') ||
                          err.message.includes('rate limit');

      if (attempt < maxRetries && (isTimeout || isTransient)) {
        const delay = Math.pow(2, attempt) * 1000;
        console.warn(`Attempt ${attempt + 1} failed, retrying in ${delay}ms: ${err.message}`);
        await new Promise(r => setTimeout(r, delay));
        continue;
      }

      throw err;
    }
  }
}
```

### Stream Error Detection

When using `stream-json`, errors can appear as:

```json
{ "type": "error", "message": "..." }
```

Or the process may exit with a non-zero code before a `result` event. Always
handle both cases:

```javascript
proc.on('close', (code) => {
  clearTimeout(timer);
  if (code !== 0 && !resolved) {
    reject(new Error(`cursor-agent failed with exit code ${code}`));
  }
});
```

---

## Timeout Management

The cursor-agent CLI can hang indefinitely. Always wrap it with a timeout.

### Process-level timeout (shell)

```bash
timeout 300 cursor-agent -p "..." --output-format json
```

### Process-level timeout (Node.js)

```javascript
const timer = setTimeout(() => {
  proc.kill('SIGTERM');
  setTimeout(() => proc.kill('SIGKILL'), 5000); // Force kill if still alive
}, 300000);
```

### Process-level timeout (Python)

```python
try:
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
except subprocess.TimeoutExpired:
    # Handle timeout
```

### ACP-level timeout

Set via environment variable:
```bash
export CURSOR_ACP_TIMEOUT_MS=300000  # 5 minutes per prompt
```

---

## Webhook Handler Pattern

Handle incoming webhooks (GitHub, Slack, etc.) by spawning a Cursor agent per event.

```javascript
const express = require('express');
const app = express();
app.use(express.json());

app.post('/webhook/github', async (req, res) => {
  const { action, pull_request } = req.body;

  if (action !== 'opened' && action !== 'synchronize') {
    return res.status(200).send('Ignored');
  }

  // Respond immediately — process async
  res.status(202).send('Processing');

  try {
    // Clone the repo to a temp dir
    const workDir = `/tmp/review-${pull_request.number}`;
    await exec(`git clone ${pull_request.head.repo.clone_url} ${workDir}`);
    await exec(`cd ${workDir} && git checkout ${pull_request.head.sha}`);

    const result = await runCursorAgent(
      `Review the code changes for security issues and best practices.
       Focus on the diff from ${pull_request.base.sha} to ${pull_request.head.sha}.`,
      { workspace: workDir, force: false, timeoutMs: 600000 }
    );

    // Post result as PR comment via GitHub API
    await postGitHubComment(pull_request, result.result);
  } catch (err) {
    console.error('Review failed:', err);
  }
});
```

---

## Job Queue Pattern

For high-volume integrations, use a job queue to manage cursor-agent workers.

```javascript
// Using BullMQ (Redis-based queue)
const { Queue, Worker } = require('bullmq');

const cursorQueue = new Queue('cursor-jobs');

// Producer: Add jobs
async function enqueueCursorJob(prompt, workspace, options = {}) {
  await cursorQueue.add('agent-run', {
    prompt,
    workspace,
    model: options.model || 'auto',
    force: options.force || false,
  });
}

// Worker: Process jobs (limit concurrency to avoid overload)
const worker = new Worker('cursor-jobs', async (job) => {
  const { prompt, workspace, model, force } = job.data;

  const result = await runCursorAgent(prompt, {
    workspace,
    model,
    force,
    timeoutMs: 600000,
  });

  return result;
}, { concurrency: 3 }); // Max 3 parallel agents
```

---

## Docker / VM Deployment

### Dockerfile for Cursor Agent Worker

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl git nodejs npm && rm -rf /var/lib/apt/lists/*

# Install Cursor CLI
RUN curl https://cursor.com/install -fsSL | bash

# Create non-root user
RUN useradd -m agent
USER agent
WORKDIR /home/agent

# Pre-trust workspace and set up config
RUN mkdir -p ~/.cursor && echo '{}' > ~/.cursor/mcp-approvals.json

ENV PATH="/home/agent/.local/bin:$PATH"

COPY worker.js .
CMD ["node", "worker.js"]
```

### VM Setup Script (for SlicerVM, cloud VMs, etc.)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install Cursor CLI
curl https://cursor.com/install -fsSL | bash
export PATH="$HOME/.local/bin:$PATH"

# Set API key
export CURSOR_API_KEY="$(cat /run/secrets/cursor-api-key)"

# Pre-create MCP approvals (required for MCP tools in headless mode)
mkdir -p ~/.cursor
cat > ~/.cursor/mcp-approvals.json << 'EOF'
{}
EOF

# Run agent
cursor-agent -p "$(cat /path/to/prompt.txt)" \
  --output-format json \
  --workspace /path/to/repo \
  --trust \
  --force
```

---

## MCP Server Configuration

The Cursor CLI auto-discovers MCP servers from `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/path/to/allowed"]
    }
  }
}
```

For headless MCP usage, you must also create `~/.cursor/mcp-approvals.json`
to pre-approve tool calls (otherwise the CLI will prompt interactively).

List available MCP servers and tools:
```bash
cursor-agent mcp
```

---

## Rules and Project Configuration

The CLI respects the same rules system as the Cursor editor:

- **Repo rules**: Place under `.cursor/rules/` in your project
- **Agent instructions**: `AGENTS.md` or `CLAUDE.md` at the repo root
- **CLI config**: `.cursor/cli.json` (project-level) or `~/.cursor/cli-config.json` (global)

This means your agent will follow project-specific conventions and guidelines
automatically when you point it at a workspace with these files.

---

## Permissions and Security

### Principle of Least Privilege

Lock down what the agent can do via permissions in `.cursor/cli.json`:

```json
{
  "permissions": {
    "allow": [
      "Shell(git)",
      "Shell(npm test)",
      "Read(src/**/*.ts)",
      "Write(src/**/*.ts)"
    ],
    "deny": [
      "Shell(rm -rf)",
      "Write(.env)",
      "Write(*.secret)"
    ]
  }
}
```

### Security Reminders

- The CLI can read, modify, and delete files, and execute shell commands.
- In `--print` mode, file writes require `--force`. Omit `--force` for read-only analysis.
- Always run in trusted, sandboxed environments (containers, VMs) for untrusted workloads.
- Never expose `CURSOR_API_KEY` in client-side code, logs, or public repos.
- Use permission rules to restrict file and shell access to only what's needed.
