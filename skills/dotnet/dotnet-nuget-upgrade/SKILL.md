---
name: dotnet-nuget-upgrade
description: >
  Guides safe .NET NuGet package upgrades end-to-end: baseline verification, version edits in csproj or
  central package management, restore and dependency-graph fixes (NU1605, feeds, source mapping), and
  post-upgrade build, test, and run. Use when upgrading, bumping, pinning, or adding NuGet packages;
  changing PackageReference or Directory.Packages.props; fixing NU1107, NU1301, NU1605; aligning
  transitive dependencies; or when the user mentions dotnet add package, package downgrade, or
  CodeArtifact/private feeds for SailPoint.Das.* packages.
---

# .NET NuGet package upgrade

Use this workflow whenever **adding, removing, or changing** NuGet package versions (`PackageReference`, `Directory.Packages.props`, `packages.lock.json`, `nuget.config`).

## 1. Scope and baseline (before touching versions)

1. **Identify scope** — single project, solution, or repo-wide central versions (`Directory.Packages.props`).
2. **Record baseline** — run the repo’s normal pipeline on that scope:
   - **Build** — e.g. `dotnet build <solution-or-project>.sln` or documented CI build.
   - **Tests** — e.g. `dotnet test` with the same filters CI uses, or `./build.sh test`.
   - **Run** — start the primary runnable (e.g. `dotnet run --project path/to/Host.csproj`), or a documented smoke command. Pure libraries: run a sample/test host or integration smoke if one exists; otherwise note “no runnable” and skip.
3. If baseline already fails, **note it**; after the upgrade, ensure you do not introduce **additional** failures.

## 2. Plan the change

- **Direct vs transitive** — Upgrading package A may require bumping **direct** references (e.g. `SailPoint.Das.Core.Client`) when **NU1605** says a dependency needs a higher minimum than your explicit pin.
- **Central package management** — If the repo uses `Directory.Packages.props`, prefer updating **one** `PackageVersion` there rather than scattering versions in many `.csproj` files (unless the repo convention is per-project pins).
- **Lock files** — If `packages.lock.json` is committed, run restore so the lock file updates; commit the lock change with the version bump.
- **Multiple target frameworks** — Ensure the chosen version supports all `TargetFrameworks` in consuming projects.

## 3. Apply the version change

- Edit `PackageReference` `Version="..."` or the matching line in `Directory.Packages.props`.
- For tooling: `dotnet add package <Id> --version <ver> -p <Project.csproj>` (aligns with project style).

## 4. Restore

- From the repo root or solution directory: `dotnet restore` (or restore the specific solution).
- **Private feeds** — If restore fails on missing `SailPoint.*` packages, ensure `nuget.config` includes CodeArtifact (or org feed) and credentials/token as documented for that repo.
- **Broken local offline path** — If `NU1301`/`NU1801` references a missing `das-offline` path, fix `%DAS_OFFLINE_NUGETS%` or use `dotnet restore --ignore-failed-sources` only as a temporary workaround while fixing the config.
- **`packageSourceMapping`** — If NU1100/NU1301 suggests a package cannot be found on the mapped source, align the package pattern with the feed that hosts it.

## 5. Verify after upgrade (required)

Repeat **in order**:

1. **Build** — same command as baseline.
2. **Tests** — same command as baseline.
3. **Run** — same runnable as baseline.

If any step fails, **do not** merge or stop at the first line of output: read the full error, classify it (below), fix, then re-run build → test → run.

## 6. Common failures and fixes

| Symptom | Typical cause | Action |
|--------|----------------|--------|
| **NU1605** Warning as Error: package downgrade | Direct reference lower than a dependency’s minimum (e.g. `ServiceBase` needs `Client` ≥ 3.2.0 but project pins 3.1.1) | Bump the **direct** `PackageReference` to satisfy the **minimum** (or add an explicit reference to the higher version on the project that restores). |
| **NU1107** Version conflict | Two packages need incompatible versions of the same dependency | Use `dotnet nuget why <Project> <PackageId>` (SDK 9+) or inspect dependency chain; upgrade/downgrade to a single compatible set; consider aligning related SailPoint.* packages together. |
| **NU1301** / missing source | Invalid or unreachable feed path | Fix `nuget.config`, env vars, or network; ensure CI has the same feeds. |
| **Compile errors after bump** | API breaking change in the package | Update call sites, or adjust target version / add compatibility package per release notes. |
| **Test failures only** | Behavior change, flaky test, or test dependency version | Diff test output; update assertions or test packages (e.g. test SDK adapters). |

Optional inspection:

```bash
dotnet list package --outdated --include-transitive
dotnet list package --vulnerable  # if security matters for this bump
```

## 7. CI and PR checklist

- [ ] Local **build, test, run** match what CI runs (or document gaps).
- [ ] No unintended `PackageReference` edits in unrelated projects (unless central management requires it).
- [ ] Lock files and `Directory.Packages.props` committed if the repo uses them.
- [ ] PR description states **what** was upgraded and **why** (e.g. security, NU1605 fix, feature).

## 8. UTF-8 BOM (repo-specific)

Some C# repos require **BOM on `.cs` files** after editing line 1. NuGet edits often touch `.csproj`/`.props` only (usually no BOM requirement). If a version bump forces `.cs` edits, follow the workspace rule for BOM on those files.

## Summary

**Baseline → change version → restore → build → test → run → fix regressions.** Treat downgrade (NU1605) and feed mapping as first-class parts of “upgrading a package,” not optional extras.
