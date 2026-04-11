#!/usr/bin/env npx tsx
/**
 * health-check.ts — Validate AI Elements setup, versions, and configuration
 *
 * Usage: npx tsx scripts/health-check.ts [project_root]
 *
 * Checks:
 * 1. Node.js version (18+)
 * 2. package.json exists and has required dependencies
 * 3. AI SDK installed and version compatible
 * 4. shadcn/ui configured (components.json exists, CSS Variables mode)
 * 5. AI Elements components directory exists
 * 6. Tailwind CSS configured
 * 7. API route exists
 * 8. Environment variables present
 */

import { existsSync, readFileSync, readdirSync } from "fs";
import { join, resolve } from "path";

const PROJECT_ROOT = resolve(process.argv[2] || ".");

interface CheckResult {
  name: string;
  status: "pass" | "warn" | "fail";
  message: string;
  fix?: string;
}

const results: CheckResult[] = [];

function check(
  name: string,
  fn: () => { status: "pass" | "warn" | "fail"; message: string; fix?: string }
) {
  try {
    results.push({ name, ...fn() });
  } catch (e: any) {
    results.push({ name, status: "fail", message: e.message, fix: "Check manually" });
  }
}

function readJson(path: string): any {
  return JSON.parse(readFileSync(path, "utf-8"));
}

// --- Checks ---

check("Node.js version", () => {
  const version = process.version;
  const major = parseInt(version.slice(1).split(".")[0], 10);
  if (major >= 18) {
    return { status: "pass", message: `Node.js ${version}` };
  }
  return {
    status: "fail",
    message: `Node.js ${version} — requires 18+`,
    fix: "Upgrade Node.js to 18 or later",
  };
});

check("package.json exists", () => {
  const pkgPath = join(PROJECT_ROOT, "package.json");
  if (existsSync(pkgPath)) {
    return { status: "pass", message: "Found" };
  }
  return { status: "fail", message: "Not found", fix: "Run npm init" };
});

check("AI SDK installed (@ai-sdk/react)", () => {
  const pkgPath = join(PROJECT_ROOT, "package.json");
  if (!existsSync(pkgPath)) return { status: "fail", message: "No package.json" };
  const pkg = readJson(pkgPath);
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  if (deps["@ai-sdk/react"]) {
    return { status: "pass", message: `@ai-sdk/react: ${deps["@ai-sdk/react"]}` };
  }
  return {
    status: "fail",
    message: "Not installed",
    fix: "npm install ai @ai-sdk/react",
  };
});

check("AI SDK core (ai) installed", () => {
  const pkgPath = join(PROJECT_ROOT, "package.json");
  if (!existsSync(pkgPath)) return { status: "fail", message: "No package.json" };
  const pkg = readJson(pkgPath);
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  if (deps["ai"]) {
    return { status: "pass", message: `ai: ${deps["ai"]}` };
  }
  return {
    status: "fail",
    message: "Not installed",
    fix: "npm install ai",
  };
});

check("Next.js installed", () => {
  const pkgPath = join(PROJECT_ROOT, "package.json");
  if (!existsSync(pkgPath)) return { status: "fail", message: "No package.json" };
  const pkg = readJson(pkgPath);
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  if (deps["next"]) {
    return { status: "pass", message: `next: ${deps["next"]}` };
  }
  return {
    status: "fail",
    message: "Not installed",
    fix: "npm install next react react-dom",
  };
});

check("shadcn/ui configured (components.json)", () => {
  const configPath = join(PROJECT_ROOT, "components.json");
  if (!existsSync(configPath)) {
    return {
      status: "fail",
      message: "components.json not found",
      fix: "npx shadcn@latest init",
    };
  }
  const config = readJson(configPath);
  if (config.tailwind?.cssVariables === false) {
    return {
      status: "warn",
      message: "CSS Variables mode is disabled — AI Elements requires it",
      fix: 'Set "tailwind.cssVariables": true in components.json',
    };
  }
  return { status: "pass", message: "Configured" };
});

check("AI Elements components directory", () => {
  const dirs = [
    join(PROJECT_ROOT, "components", "ai-elements"),
    join(PROJECT_ROOT, "src", "components", "ai-elements"),
  ];
  for (const dir of dirs) {
    if (existsSync(dir)) {
      const files = readdirSync(dir).filter(
        (f) => f.endsWith(".tsx") || f.endsWith(".ts")
      );
      return {
        status: "pass",
        message: `Found at ${dir} (${files.length} component files)`,
      };
    }
  }
  return {
    status: "fail",
    message: "No ai-elements directory found",
    fix: "npx ai-elements@latest",
  };
});

check("Tailwind CSS configured", () => {
  const configFiles = [
    "tailwind.config.js",
    "tailwind.config.ts",
    "tailwind.config.mjs",
    "tailwind.config.cjs",
  ];
  for (const f of configFiles) {
    if (existsSync(join(PROJECT_ROOT, f))) {
      return { status: "pass", message: `Found ${f}` };
    }
  }
  const cssFiles = ["app/globals.css", "src/app/globals.css", "styles/globals.css"];
  for (const f of cssFiles) {
    const fullPath = join(PROJECT_ROOT, f);
    if (existsSync(fullPath)) {
      const content = readFileSync(fullPath, "utf-8");
      if (content.includes("@tailwind") || content.includes('@import "tailwindcss')) {
        return { status: "pass", message: `Tailwind configured in ${f}` };
      }
    }
  }
  return {
    status: "warn",
    message: "Tailwind config not found",
    fix: "Ensure Tailwind CSS is configured",
  };
});

check("API route exists", () => {
  const routes = [
    join(PROJECT_ROOT, "app", "api", "chat", "route.ts"),
    join(PROJECT_ROOT, "app", "api", "chat", "route.js"),
    join(PROJECT_ROOT, "src", "app", "api", "chat", "route.ts"),
    join(PROJECT_ROOT, "src", "app", "api", "chat", "route.js"),
  ];
  for (const r of routes) {
    if (existsSync(r)) {
      const content = readFileSync(r, "utf-8");
      const hasStreamText = content.includes("streamText");
      const hasUIResponse = content.includes("toUIMessageStreamResponse");
      if (hasStreamText && hasUIResponse) {
        return { status: "pass", message: `Found at ${r}` };
      }
      return {
        status: "warn",
        message: `Found ${r} but may be missing streamText or toUIMessageStreamResponse`,
        fix: "Ensure route uses streamText() and returns toUIMessageStreamResponse()",
      };
    }
  }
  return {
    status: "warn",
    message: "No chat API route found",
    fix: "Create app/api/chat/route.ts with streamText + toUIMessageStreamResponse",
  };
});

check("Environment variables", () => {
  const envFiles = [".env.local", ".env"];
  for (const f of envFiles) {
    const envPath = join(PROJECT_ROOT, f);
    if (existsSync(envPath)) {
      const content = readFileSync(envPath, "utf-8");
      const hasKey =
        content.includes("AI_GATEWAY_API_KEY") ||
        content.includes("OPENAI_API_KEY") ||
        content.includes("ANTHROPIC_API_KEY");
      if (hasKey) {
        return { status: "pass", message: `API key found in ${f}` };
      }
      return {
        status: "warn",
        message: `${f} exists but no AI API keys found`,
        fix: "Add AI_GATEWAY_API_KEY or provider-specific keys to .env.local",
      };
    }
  }
  return {
    status: "warn",
    message: "No .env.local found",
    fix: "Create .env.local with AI_GATEWAY_API_KEY=your-key",
  };
});

// --- Report ---

console.log("\n🏥 AI Elements Health Check\n");
console.log(`   Project: ${PROJECT_ROOT}\n`);

const icons = { pass: "✅", warn: "⚠️ ", fail: "❌" };
let hasFailure = false;
let hasWarning = false;

for (const r of results) {
  console.log(`${icons[r.status]} ${r.name}: ${r.message}`);
  if (r.fix) console.log(`   💊 Fix: ${r.fix}`);
  if (r.status === "fail") hasFailure = true;
  if (r.status === "warn") hasWarning = true;
}

console.log("\n" + "─".repeat(50));
if (hasFailure) {
  console.log("❌ Health check FAILED — fix the issues above.");
  process.exit(1);
} else if (hasWarning) {
  console.log("⚠️  Health check PASSED with warnings.");
  process.exit(0);
} else {
  console.log("✅ Health check PASSED — all good!");
  process.exit(0);
}
