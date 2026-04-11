# Headless CLI Integration Reference

## Table of Contents
1. [Output Formats](#output-formats)
2. [Stream-JSON Event Types](#stream-json-event-types)
3. [Node.js Integration](#nodejs-integration)
4. [Python Integration](#python-integration)
5. [Shell Script Integration](#shell-script-integration)
6. [CI/CD Integration](#cicd-integration)
7. [Batch Processing](#batch-processing)
8. [Session Resumption](#session-resumption)

---

## Output Formats

### `json` — Single result object
Emits one JSON object (followed by a newline) when the run completes. No streaming events.
On failure, exits with non-zero code and writes error to stderr.

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 1234,
  "duration_api_ms": 1234,
  "result": "<full assistant text>",
  "session_id": "<uuid>"
}
```

### `stream-json` — NDJSON events (default)
Each line is a single JSON object representing a real-time event. The stream ends with
a terminal `result` event on success.

### `text` — Human-readable progress
Simplified text descriptions of agent actions. Good for logging/debugging.
Outputs like: `Read file`, `Edited file`, `Ran terminal command`, `Created new file`.

---

## Stream-JSON Event Types

### System Init
First event emitted. Contains metadata about the session.

```json
{
  "type": "system",
  "subtype": "init",
  "apiKeySource": "env|flag|login",
  "cwd": "/absolute/path",
  "session_id": "<uuid>",
  "model": "<model display name>",
  "permissionMode": "default"
}
```
Future fields like `tools` and `mcp_servers` may be added.

### User Message
Echo of the prompt sent to the agent.

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": [{ "type": "text", "text": "<prompt>" }]
  },
  "session_id": "<uuid>"
}
```

### Assistant Delta
Emitted multiple times as the agent generates its response. Each contains an incremental text chunk.

```json
{
  "type": "assistant",
  "message": {
    "role": "assistant",
    "content": [{ "type": "text", "text": "<delta chunk>" }]
  },
  "session_id": "<uuid>"
}
```
Concatenate all `message.content[].text` values in order to reconstruct the full response.

### Tool Call Events
Emitted when the agent uses tools (file reads, writes, terminal commands).

```json
{
  "type": "tool_call",
  "subtype": "started",
  "tool_name": "read_file",
  "tool_call_id": "<id>",
  "parameters": { ... }
}
```

```json
{
  "type": "tool_call",
  "subtype": "completed",
  "tool_call_id": "<id>",
  "result": { ... }
}
```

### Thinking Delta
Reasoning/thinking content (suppressed in print mode by default).

### Result (Terminal Event)
Final event on success:

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 5678,
  "duration_api_ms": 4321,
  "result": "<full concatenated assistant text>",
  "session_id": "<uuid>"
}
```

Important: `thinking` events are suppressed in print mode. Field additions may occur over time
(consumers should ignore unknown fields).

---

## Node.js Integration

### Fire-and-Forget (JSON output)

```javascript
const { spawn } = require('child_process');

function runCursorAgent(prompt, options = {}) {
  return new Promise((resolve, reject) => {
    const args = ['-p', prompt, '--output-format', 'json'];

    if (options.model) args.push('-m', options.model);
    if (options.force) args.push('--force');
    if (options.workspace) args.push('--workspace', options.workspace);
    if (options.trust) args.push('--trust');

    const proc = spawn('cursor-agent', args, {
      env: { ...process.env, CURSOR_API_KEY: options.apiKey || process.env.CURSOR_API_KEY },
      cwd: options.workspace || process.cwd(),
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (chunk) => { stdout += chunk; });
    proc.stderr.on('data', (chunk) => { stderr += chunk; });

    // Timeout protection — cursor-agent can hang
    const timeout = setTimeout(() => {
      proc.kill('SIGTERM');
      reject(new Error(`cursor-agent timed out after ${options.timeoutMs || 300000}ms`));
    }, options.timeoutMs || 300000);

    proc.on('close', (code) => {
      clearTimeout(timeout);
      if (code !== 0) {
        reject(new Error(`cursor-agent exited with code ${code}: ${stderr}`));
        return;
      }
      try {
        const result = JSON.parse(stdout.trim());
        resolve(result);
      } catch (e) {
        reject(new Error(`Failed to parse cursor-agent output: ${stdout}`));
      }
    });
  });
}
```

### Streaming (NDJSON)

```javascript
const { spawn } = require('child_process');
const readline = require('readline');

function streamCursorAgent(prompt, onEvent, options = {}) {
  return new Promise((resolve, reject) => {
    const args = ['-p', prompt, '--output-format', 'stream-json'];

    if (options.model) args.push('-m', options.model);
    if (options.force) args.push('--force');
    if (options.workspace) args.push('--workspace', options.workspace);
    if (options.trust) args.push('--trust');

    const proc = spawn('cursor-agent', args, {
      env: { ...process.env, CURSOR_API_KEY: options.apiKey || process.env.CURSOR_API_KEY },
      cwd: options.workspace || process.cwd(),
    });

    const rl = readline.createInterface({ input: proc.stdout });

    rl.on('line', (line) => {
      try {
        const event = JSON.parse(line);
        onEvent(event);
        if (event.type === 'result') {
          resolve(event);
        }
      } catch (e) {
        // Ignore non-JSON lines
      }
    });

    const timeout = setTimeout(() => {
      proc.kill('SIGTERM');
      reject(new Error('cursor-agent stream timed out'));
    }, options.timeoutMs || 300000);

    proc.on('close', (code) => {
      clearTimeout(timeout);
      if (code !== 0) reject(new Error(`cursor-agent exited with code ${code}`));
    });
  });
}
```

---

## Python Integration

### Fire-and-Forget

```python
import subprocess
import json
import os

def run_cursor_agent(prompt, *, model=None, force=False, workspace=None,
                     api_key=None, timeout=300):
    """Run cursor-agent and return the parsed JSON result."""
    cmd = ['cursor-agent', '-p', prompt, '--output-format', 'json']

    if model:
        cmd.extend(['-m', model])
    if force:
        cmd.append('--force')
    if workspace:
        cmd.extend(['--workspace', workspace, '--trust'])

    env = {**os.environ}
    if api_key:
        env['CURSOR_API_KEY'] = api_key

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=workspace,
        env=env,
    )

    if result.returncode != 0:
        raise RuntimeError(f"cursor-agent failed (code {result.returncode}): {result.stderr}")

    return json.loads(result.stdout.strip())
```

### Streaming

```python
import subprocess
import json
import os

def stream_cursor_agent(prompt, *, on_event=None, model=None, force=False,
                        workspace=None, api_key=None, timeout=300):
    """Stream cursor-agent events. Yields parsed event dicts."""
    cmd = ['cursor-agent', '-p', prompt, '--output-format', 'stream-json']

    if model:
        cmd.extend(['-m', model])
    if force:
        cmd.append('--force')
    if workspace:
        cmd.extend(['--workspace', workspace, '--trust'])

    env = {**os.environ}
    if api_key:
        env['CURSOR_API_KEY'] = api_key

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=workspace,
        env=env,
    )

    try:
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
                if on_event:
                    on_event(event)
                yield event
            except json.JSONDecodeError:
                pass
    finally:
        proc.terminate()
        proc.wait(timeout=10)
```

---

## Shell Script Integration

### Simple one-shot

```bash
#!/usr/bin/env bash
set -euo pipefail

export CURSOR_API_KEY="your-key-here"

# Run agent and get result as JSON
result=$(timeout 300 cursor-agent -p "Analyze this codebase for security issues" \
  --output-format json \
  --workspace /path/to/repo \
  --trust)

# Extract the result text
echo "$result" | jq -r '.result'
```

### Batch processing

```bash
#!/usr/bin/env bash
set -euo pipefail

export CURSOR_API_KEY="your-key-here"

find src/ -name "*.js" | while read -r file; do
  echo "Processing: $file"
  cursor-agent -p "Add JSDoc comments to $file" \
    --output-format text \
    --force \
    --trust
done
```

### Reading prompts from a file

The CLI does not support stdin pipes for prompts. Use command substitution:

```bash
cursor-agent -p "$(cat prompt.txt)" --output-format json
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Cursor CLI
        run: curl https://cursor.com/install -fsSL | bash

      - name: Run AI Review
        env:
          CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
        run: |
          result=$(cursor-agent -p \
            "Review the changes in this PR for security issues and code quality" \
            --output-format json \
            --trust)

          echo "$result" | jq -r '.result' > review.md

      - name: Post Review Comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `## AI Code Review\n\n${review}`
            });
```

---

## Session Resumption

For multi-turn interactions, capture the `session_id` from the first result and pass it
with `--resume`:

```javascript
// First turn
const result1 = await runCursorAgent("Plan the refactoring of the auth module");
const sessionId = result1.session_id;

// Second turn (continues the conversation)
const result2 = await runCursorAgent("Now implement the plan", {
  resume: sessionId,
  force: true,
});
```

When using `--resume`, add it to the args: `['--resume', sessionId]`.

You can list previous sessions with `cursor-agent ls`.
