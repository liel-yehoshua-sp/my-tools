# Workflow: Create a Component

> Use this workflow when integrating a specific AI Elements component into a project.

## Steps

### Step 1: Identify the Right Component

1. Read `references/components.md` to find the component matching the requirement
2. Let `{{COMPONENT}}` = the chosen component name (e.g., `reasoning`, `tool`, `message`)
3. Let `{{COMPONENT_FILE}}` = `references/components/{{COMPONENT}}.md`

### Step 2: Read the Component Detail File

Read `{{COMPONENT_FILE}}` to understand:
- **Description**: What the component does
- **Scenarios (Good Fit)**: Confirm the use case matches
- **Scenarios (Bad Fit)**: Confirm we're not misusing it; if it's a bad fit, follow the alternative
- **Sub-components**: Which sub-components are available
- **Testing Checklist**: What needs to be tested

### Step 3: Check If Already Installed

```bash
bash scripts/search-component.sh {{PROJECT_ROOT}} {{COMPONENT}}
```

- **If installed**: Skip to Step 5
- **If not installed**: Continue to Step 4

### Step 4: Install the Component

```bash
npx ai-elements@latest add {{COMPONENT}}
```

Verify the file exists at `@/components/ai-elements/{{COMPONENT}}.tsx`

### Step 5: Check Server Route Requirements

Read `references/rules.md` → Rule R7 for server-side requirements.

| If using... | Server route must include... |
|---|---|
| Reasoning | `sendReasoning: true` |
| Sources | `sendSources: true` |
| Confirmation | `requireApproval: true` on tool |
| Tool | Tool defined in `streamText({ tools })` |

Update the API route if needed.

### Step 6: Implement the Component

1. Add `"use client"` directive at top of the file (Rule R3)
2. Import the component and sub-components from `@/components/ai-elements/{{COMPONENT}}`
3. Wire to `useChat` hook (Rule R1)
4. Iterate `message.parts` and render the component for the matching part type (Rule R6)
5. Follow the composable pattern from `references/best-practices.md` → Practice #4

### Step 7: Validate Against Rules

Walk through each rule in `references/rules.md`:
- [ ] R1: Connected to AI SDK
- [ ] R2: Streamdown CSS imported (if using MessageResponse)
- [ ] R3: "use client" directive present
- [ ] R5: Conversation has fixed height container
- [ ] R6: Using message.parts, not message.content
- [ ] R7: Server route configured
- [ ] R10: CSS Variables mode

### Step 8: Validate Against Best Practices

Check against `references/best-practices.md`:
- [ ] Composable pattern (not monolithic)
- [ ] Status-aware rendering
- [ ] Type safety with TypeScript
- [ ] Proper dark mode handling

### Step 9: Run Testing Checklist

Use the testing checklist from `{{COMPONENT_FILE}}` to verify the implementation.

### Step 10: Validate Against Conventions

Check against `references/conventions.md`:
- [ ] Correct file location
- [ ] Correct import paths
- [ ] Correct naming
- [ ] Correct API route pattern
