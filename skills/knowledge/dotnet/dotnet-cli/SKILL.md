---
name: dotnet-cli
description: >
  Comprehensive knowledge base for the .NET CLI (dotnet command-line interface). Use this skill
  whenever the user asks about any dotnet CLI command, .NET project scaffolding, building, testing,
  publishing, packaging, NuGet management, tool management, workload management, solution management,
  global.json configuration, or any .NET SDK command-line operation. Trigger on mentions of: 'dotnet',
  'dotnet new', 'dotnet build', 'dotnet run', 'dotnet test', 'dotnet publish', 'dotnet pack',
  'dotnet restore', 'dotnet sln', 'dotnet add', 'dotnet remove', 'dotnet tool', 'dotnet nuget',
  'dotnet workload', 'dotnet watch', 'dotnet format', 'dotnet clean', 'dotnet dev-certs',
  'dotnet ef', 'global.json', '.NET CLI', 'NuGet CLI', 'dotnet sdk', or any request to create,
  build, test, deploy, or manage a .NET project from the command line. Also trigger when the user
  mentions 'create a C# project', 'scaffold a .NET app', 'add a NuGet package', 'run unit tests',
  'publish to production', or similar .NET development tasks even without explicitly saying 'dotnet'.
---

# .NET CLI Knowledge Skill

Complete reference for the `dotnet` command-line interface based on official Microsoft documentation.

> **Source**: [learn.microsoft.com/en-us/dotnet/core/tools](https://learn.microsoft.com/en-us/dotnet/core/tools/)

---

## Quick Reference: Command Map

For detailed options and examples of each command category, read the corresponding reference file.

| Category | Commands | Reference File |
|---|---|---|
| **Core workflow** | `new`, `build`, `run`, `test`, `publish`, `pack`, `clean`, `restore`, `watch`, `format` | `references/core-commands.md` |
| **Project modification** | `package add/remove/list/update/search/download`, `reference add/remove/list`, `project convert` | `references/project-commands.md` |
| **NuGet** | `nuget push/delete/locals/verify/trust/sign/why`, `nuget add/remove/enable/disable/list/update source` | `references/nuget-commands.md` |
| **Tools** | `tool install/uninstall/update/list/run/search/restore` | `references/tool-commands.md` |
| **Workloads** | `workload install/uninstall/update/list/search/repair/restore/clean/config/history` | `references/workload-commands.md` |
| **Advanced** | `msbuild`, `sdk check`, `build-server`, `dev-certs`, `user-secrets`, `dotnet ef` | `references/advanced-commands.md` |
| **Configuration** | `global.json`, environment variables, `nuget.config`, `.editorconfig` | `references/configuration.md` |

---

## Command Structure

```
dotnet [driver-options] [command] [command-args] [command-options]
```

The **driver** (`dotnet`) has two roles:
1. **Run a framework-dependent app**: `dotnet myapp.dll`
2. **Execute a CLI command**: `dotnet build`

---

## Most Common Workflows (Quick Cheat Sheet)

### Create → Build → Run → Test → Publish

```bash
# Scaffold
dotnet new sln -n MySolution
dotnet new webapi -n MyApi -o src/MyApi
dotnet sln add src/MyApi/MyApi.csproj

# Develop
dotnet build                          # Build all projects in sln
dotnet run --project src/MyApi        # Run specific project
dotnet watch --project src/MyApi      # Hot-reload dev loop

# Test
dotnet new xunit -n MyApi.Tests -o tests/MyApi.Tests
dotnet add tests/MyApi.Tests reference src/MyApi
dotnet test                           # Run all tests in sln

# Package & Publish
dotnet publish -c Release -o ./publish   # Framework-dependent
dotnet publish -c Release --self-contained -r win-x64  # Self-contained
dotnet pack -c Release                   # Create NuGet package
```

### NuGet Package Management

```bash
dotnet add package Newtonsoft.Json              # Add package
dotnet add package Serilog --version 3.1.0      # Specific version
dotnet remove package Newtonsoft.Json            # Remove package
dotnet package list                              # List packages
dotnet package list --outdated                   # Show outdated
dotnet package update Newtonsoft.Json             # Update single (SDK 10+)
dotnet restore                                   # Explicit restore
```

### Project References

```bash
dotnet reference add ../Shared/Shared.csproj       # Add project ref
dotnet reference list                               # List refs
dotnet reference remove ../Shared/Shared.csproj     # Remove ref
```

### Solution Management

```bash
dotnet new sln -n MySolution              # Create solution
dotnet sln add src/**/*.csproj            # Add projects (glob)
dotnet sln remove src/Old/Old.csproj      # Remove project
dotnet sln list                           # List projects
```

### Tool Management

```bash
dotnet tool install -g dotnet-ef                 # Global tool
dotnet tool install dotnet-ef                    # Local tool (needs manifest)
dotnet new tool-manifest                         # Create .config/dotnet-tools.json
dotnet tool restore                              # Restore local tools from manifest
dotnet tool list -g                              # List global tools
dotnet tool update -g dotnet-ef                  # Update global tool
dotnet tool uninstall -g dotnet-ef               # Remove global tool
```

---

## SDK Version Selection & global.json

Pin the SDK version for a repo:
```bash
dotnet new globaljson --sdk-version 9.0.100 --roll-forward latestFeature
```

Produces:
```json
{
  "sdk": {
    "version": "9.0.100",
    "rollForward": "latestFeature"
  }
}
```

**rollForward values** (from most restrictive to most permissive):

| Value | Behavior |
|---|---|
| `disable` | Exact match only. No roll forward. |
| `patch` | Exact `x.y.z` or highest patch within `x.y.z__` |
| `feature` | Highest patch within requested `x.y.z__` feature band |
| `latestPatch` | Highest patch within `x.y.__xx` minor |
| `latestFeature` | Highest feature band + patch within `x.y.___` |
| `latestMinor` | Highest minor + feature + patch within `x.___` |
| `latestMajor` | Highest installed SDK (most permissive) |

Use `latestFeature` for most repos — it accepts new SDK features within the same major version.

For detailed configuration reference, read `references/configuration.md`.

---

## Built-in Templates (dotnet new)

Common templates shipped with the SDK:

| Template | Short name | Language |
|---|---|---|
| Console app | `console` | C#, F#, VB |
| Class library | `classlib` | C#, F#, VB |
| Web API | `webapi` | C# |
| Web app (Razor/MVC) | `webapp` | C# |
| Blazor Server | `blazorserver` | C# |
| Blazor WebAssembly | `blazorwasm` | C# |
| Worker service | `worker` | C# |
| gRPC service | `grpc` | C# |
| xUnit test | `xunit` | C# |
| NUnit test | `nunit` | C# |
| MSTest test | `mstest` | C# |
| Solution file | `sln` | — |
| global.json | `globaljson` | — |
| NuGet config | `nugetconfig` | — |
| EditorConfig | `editorconfig` | — |
| Tool manifest | `tool-manifest` | — |

```bash
dotnet new list                              # All installed templates
dotnet new list --tag web                    # Filter by tag
dotnet new search <keyword>                  # Search NuGet for templates
dotnet new install <PACKAGE_ID>              # Install template package
dotnet new uninstall <PACKAGE_ID>            # Remove template package
dotnet new console --help                    # Template-specific options
```

Key template options:
- `--framework net9.0` — target framework
- `--language "F#"` — language
- `-n MyProject` — project name
- `-o ./path` — output directory
- `--no-restore` — skip implicit restore
- `--use-program-main` — use explicit `Main` method instead of top-level statements

---

## Implicit Restore

These commands run `dotnet restore` implicitly: `new`, `build`, `run`, `test`, `publish`, `pack`.

To skip: pass `--no-restore`.

Explicit restore is still useful in CI pipelines where you need to control when authentication/restore occurs.

---

## Common Options (available on most commands)

| Option | Description |
|---|---|
| `-c\|--configuration` | `Debug` (default) or `Release`. Since .NET 8, `publish`/`pack` default to `Release` for `net8.0+` targets. |
| `-f\|--framework` | Target framework moniker (e.g., `net9.0`) |
| `-r\|--runtime` | Runtime Identifier (e.g., `win-x64`, `linux-arm64`) |
| `-o\|--output` | Output directory |
| `-v\|--verbosity` | `q[uiet]`, `m[inimal]`, `n[ormal]`, `d[etailed]`, `diag[nostic]` |
| `--no-restore` | Skip implicit restore |
| `--no-build` | Skip build step (for test/publish when already built) |
| `-p\|--property` | Pass MSBuild property: `-p:Version=1.2.3` |
| `--arch` | Target architecture shorthand (`x64`, `x86`, `arm64`) |
| `--os` | Target OS shorthand (`win`, `linux`, `osx`) |
| `--self-contained` | Include runtime in output |
| `--no-self-contained` | Framework-dependent (default) |
| `--artifacts-path` | Centralized output layout (since .NET 8) |
| `--tl` | Terminal logger: `auto`, `on`, `off` |
| `--disable-build-servers` | Force fresh build, ignore caches |

---

## Runtime Identifiers (RIDs) — Common Values

| RID | Platform |
|---|---|
| `win-x64` | Windows 64-bit |
| `win-x86` | Windows 32-bit |
| `win-arm64` | Windows ARM64 |
| `linux-x64` | Linux 64-bit |
| `linux-arm64` | Linux ARM64 |
| `linux-musl-x64` | Alpine Linux |
| `osx-x64` | macOS Intel |
| `osx-arm64` | macOS Apple Silicon |

---

## Environment Variables

| Variable | Purpose |
|---|---|
| `DOTNET_ROOT` | Custom .NET install location |
| `DOTNET_CLI_TELEMETRY_OPTOUT=1` | Disable telemetry |
| `DOTNET_NOLOGO=1` | Suppress banner |
| `DOTNET_ROLL_FORWARD` | Runtime roll-forward policy |
| `NUGET_PACKAGES` | Custom NuGet cache location |
| `DOTNET_CLI_HOME` | Home directory for CLI state |
| `DOTNET_ENVIRONMENT` | Set environment name (Development, Staging, Production) |
| `ASPNETCORE_URLS` | Bind URLs for ASP.NET Core apps |
| `ASPNETCORE_ENVIRONMENT` | ASP.NET Core environment name |

---

## Guidance for Claude

When helping users with dotnet CLI tasks:

1. **Always use the latest syntax**. Since .NET 10, some commands switched to "noun first" form (e.g., `dotnet package add` instead of `dotnet add package`). Both forms work; prefer the newer form for .NET 10+ projects, but mention backward compatibility.

2. **Check the target SDK version** before suggesting commands. Some options/commands are SDK-version-gated (e.g., `dotnet format` since .NET 6, `workload` since .NET 6, `--artifacts-path` since .NET 8, `package update` since .NET 10).

3. **For CI/CD pipelines**, always suggest explicit `dotnet restore` + `--no-restore` on subsequent commands to control authentication properly.

4. **For production deployment**, always use `dotnet publish` (not `dotnet build` or `dotnet run`). The publish output is the only officially supported way to prepare apps for deployment.

5. **When the dotnet SDK is not available** in the current environment, use bash/Python to generate project files and solution files from scratch (see the `sln` skill for `.sln` file generation).

6. For detailed options on specific command categories, read the appropriate file from `references/`.
