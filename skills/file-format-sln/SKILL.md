---
name: sln
description: >
  Use this skill whenever the user wants to create, read, edit, parse, fix, merge, or manipulate
  Visual Studio Solution (.sln) files. Triggers include: any mention of '.sln', 'solution file',
  'Visual Studio solution', requests to add/remove projects from a solution, reorder solution folders,
  fix broken project references or GUIDs, generate a solution from a directory of .csproj/.fsproj/.vbproj files,
  merge two solutions, scaffold a new multi-project solution, change solution configurations/platforms,
  or diagnose why a solution won't open. Also trigger when the user mentions 'dotnet sln', 'solution structure',
  'solution explorer layout', or wants to understand/visualize the project dependency tree inside a .sln.
  Even if the user just says "create a C# solution" or "set up a .NET project structure", use this skill.
---

# Visual Studio Solution (.sln) File Skill

## What This Skill Covers

Everything related to `.sln` files: creating, reading, editing, parsing, fixing, merging,
scaffolding, and diagnosing Visual Studio Solution files using Python or bash.

---

## .sln File Format Reference

### Structure Overview

A `.sln` file is a **plain-text** file with this structure:

```
[Header]
[Project blocks]
[Global section]
```

### 1. Header (required)

```
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
```

- **Format Version**: `12.00` is standard for VS2012+. Use this for all modern solutions.
- **Visual Studio Version 17** = VS 2022. Version 16 = VS 2019. Version 15 = VS 2017.
- The `VisualStudioVersion` and `MinimumVisualStudioVersion` lines are optional but recommended.

### 2. Project Blocks (one per project)

```
Project("{TYPE-GUID}") = "ProjectName", "relative\path\to\Project.csproj", "{PROJECT-GUID}"
EndProject
```

**Common Project Type GUIDs:**

| Type                        | GUID                                     |
|-----------------------------|------------------------------------------|
| C# (.csproj)                | `{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}` |
| C# (SDK-style)              | `{9A19103F-16F7-4668-BE54-9A1E7A4F7556}` |
| VB.NET                      | `{F184B08F-C81C-45F6-A57F-5ABD9991F28F}` |
| F#                          | `{F2A71F9B-5D33-465A-A702-920D77279786}` |
| C++                         | `{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}` |
| Solution Folder (virtual)   | `{2150E333-8FDC-42A3-9474-1A3956D46DE8}` |
| Shared Project (.shproj)    | `{D954291E-2A0B-460D-934E-DC6B0785DB48}` |
| Docker Compose              | `{E53339B2-1760-4266-BCC7-CA923CBCF16C}` |
| Web Site                    | `{E24C65DC-7377-472B-9ABA-BC803B73C61A}` |
| Test Project                | Same as C# — tests use the C# GUID      |

**Solution Folder** blocks can contain nested `ProjectSection(SolutionItems)`:
```
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "docs", "docs", "{GUID}"
	ProjectSection(SolutionItems) = preProject
		README.md = README.md
		docs\architecture.md = docs\architecture.md
	EndProjectSection
EndProject
```

### 3. Global Section (required wrapper)

```
Global
	GlobalSection(...) = preSolution | postSolution
		...
	EndGlobalSection
Global
```

**Key GlobalSections:**

#### SolutionConfigurationPlatforms (preSolution)
Defines the available build configurations for the entire solution.
```
GlobalSection(SolutionConfigurationPlatforms) = preSolution
	Debug|Any CPU = Debug|Any CPU
	Release|Any CPU = Release|Any CPU
EndGlobalSection
```

#### ProjectConfigurationPlatforms (postSolution)
Maps each project to solution configurations — controls which projects build/deploy in each config.
```
GlobalSection(ProjectConfigurationPlatforms) = postSolution
	{PROJ-GUID}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
	{PROJ-GUID}.Debug|Any CPU.Build.0 = Debug|Any CPU
	{PROJ-GUID}.Release|Any CPU.ActiveCfg = Release|Any CPU
	{PROJ-GUID}.Release|Any CPU.Build.0 = Release|Any CPU
EndGlobalSection
```
- `.ActiveCfg` = which configuration is active
- `.Build.0` = include in build
- `.Deploy.0` = include in deploy (optional, used for web/cloud projects)

#### NestedProjects (preSolution)
Defines the virtual folder hierarchy in Solution Explorer.
```
GlobalSection(NestedProjects) = preSolution
	{CHILD-PROJECT-GUID} = {PARENT-FOLDER-GUID}
EndGlobalSection
```

#### SolutionProperties (preSolution)
```
GlobalSection(SolutionProperties) = preSolution
	HideSolutionNode = FALSE
EndGlobalSection
```

#### ExtensibilityGlobals (postSolution)
```
GlobalSection(ExtensibilityGlobals) = postSolution
	SolutionGuid = {UNIQUE-GUID}
EndGlobalSection
```

#### SharedMSBuildProjectFiles (preSolution)
For shared projects (`.projitems`):
```
GlobalSection(SharedMSBuildProjectFiles) = preSolution
	Shared\Shared.projitems*{owner-guid}*SharedItemsImports = 13
EndGlobalSection
```

---

## Workflows

### Creating a .sln from scratch

Use Python to generate the file. Always:
1. Generate fresh GUIDs with `uuid.uuid4()` for each project and the solution itself.
2. Use the correct project type GUID based on language/type.
3. Use **relative paths** with backslashes (`\`) for project paths (Windows convention, even on Linux).
4. Include all standard GlobalSections.
5. Use UTF-8 encoding with a BOM (`\ufeff` prefix) — Visual Studio expects this.
6. Use `\r\n` line endings.

```python
import uuid

def new_guid():
    return "{" + str(uuid.uuid4()).upper() + "}"
```

### Parsing an existing .sln

Use **regex-based parsing** since the format is simple and well-defined:

```python
import re

PROJECT_PATTERN = re.compile(
    r'Project\("\{([^}]+)\}"\)\s*=\s*"([^"]+)",\s*"([^"]+)",\s*"\{([^}]+)\}"'
)
# Groups: 1=type_guid, 2=name, 3=path, 4=project_guid

GLOBAL_SECTION_PATTERN = re.compile(
    r'GlobalSection\((\w+)\)\s*=\s*(preSolution|postSolution)(.*?)EndGlobalSection',
    re.DOTALL
)
```

### Adding a project to an existing .sln

1. Parse the file.
2. Insert a new `Project`/`EndProject` block before the `Global` line.
3. Add config mappings to `ProjectConfigurationPlatforms` for every existing solution config.
4. If nesting in a folder, add a `NestedProjects` entry.
5. Write back with BOM + `\r\n`.

### Removing a project

1. Remove the `Project`/`EndProject` block.
2. Remove all lines referencing that project's GUID from every `GlobalSection`.
3. Remove any `NestedProjects` entries.

### Fixing common issues

| Problem                          | Fix                                                        |
|----------------------------------|------------------------------------------------------------|
| Missing BOM                      | Prepend `\ufeff` to file content                           |
| Wrong line endings               | Replace `\n` with `\r\n` (avoid doubling `\r\r\n`)        |
| Duplicate GUIDs                  | Regenerate conflicting GUIDs and update all references     |
| Broken project path              | Update path in Project block, verify file exists           |
| Missing config mapping           | Add `ActiveCfg` + `Build.0` lines for the project          |
| Project not building             | Check that `Build.0` line exists for the desired config    |
| Folder nesting broken            | Verify `NestedProjects` GUIDs match actual project GUIDs   |

### Merging two .sln files

1. Parse both files.
2. Detect GUID collisions — regenerate if needed.
3. Merge project blocks.
4. Union the solution configurations (or keep the superset).
5. Merge `ProjectConfigurationPlatforms` — add mappings for new projects.
6. Merge `NestedProjects` — reparent under a new solution folder if desired.

### Using `dotnet sln` CLI (when available)

```bash
dotnet new sln -n MySolution                       # Create empty solution
dotnet sln MySolution.sln add src/MyApp/MyApp.csproj  # Add project
dotnet sln MySolution.sln remove src/Old/Old.csproj   # Remove project
dotnet sln MySolution.sln list                        # List projects
```

> Prefer `dotnet sln` for simple add/remove operations when dotnet SDK is available.
> Use Python for complex operations (merging, bulk restructuring, GUID fixing, analysis).

---

## Output Rules

- Always use **UTF-8 with BOM** (`\ufeff`).
- Always use **`\r\n`** line endings.
- Always use **tabs** for indentation inside `Global`/`GlobalSection` blocks.
- Project paths use **backslashes** (`\`).
- GUIDs are **uppercase** and wrapped in `{}`.
- Save the final `.sln` to `/mnt/user-data/outputs/` and present it to the user.

---

## Validation Checklist

Before delivering a `.sln` file, verify:

1. Header has format version line
2. Every project block has matching `EndProject`
3. Every project GUID is unique
4. Project type GUIDs are correct for the language
5. All project paths are relative and use backslashes
6. `Global`/`EndGlobal` wrapper exists
7. `SolutionConfigurationPlatforms` lists all desired configs
8. `ProjectConfigurationPlatforms` has entries for **every** project × **every** config
9. `NestedProjects` GUIDs reference existing projects and folders
10. `ExtensibilityGlobals` has a `SolutionGuid`
11. File starts with BOM
12. File uses `\r\n` line endings
