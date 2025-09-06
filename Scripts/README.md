# Scripts Directory

This directory contains CI/CD and development automation scripts for the AirFit project.

## Scripts Overview

### `ci-guards.sh`
Enforces architectural boundaries and code quality standards in CI/CD pipeline.

**Usage:**
```bash
./Scripts/ci-guards.sh
```

**Guards Implemented:**
1. **No Force Operations** - Prevents `try!`, `as!`, and `!.` in app code (allows in tests/previews)
2. **No Ad-hoc ModelContainer** - Ensures proper SwiftData setup through designated files only
3. **No NotificationCenter in Chat** - Enforces use of `ChatStreamingStore` for streaming
4. **No SwiftData in UI** - Prevents direct SwiftData imports in Views/ViewModels
5. **Require @MainActor on ViewModels** - Ensures proper concurrency annotation
6. **No Direct URLSession** - Enforces use of `NetworkClientProtocol`
7. **No Hardcoded Secrets** - Prevents API keys/tokens in source code

**Exit Codes:**
- `0` - All guards passed
- `1` - One or more guards failed

### `dev-audit.sh`
Development-time code quality auditing tool.

**Usage:**
```bash
./Scripts/dev-audit.sh
```

### `build-summary.sh`
Build process summary and reporting.

**Usage:**
```bash
./Scripts/build-summary.sh
```

## CI Integration

### GitHub Actions
Add to your workflow:

```yaml
- name: Run CI Guards
  run: ./Scripts/ci-guards.sh
```

### Pre-commit Hook
Install as pre-commit hook:

```bash
ln -sf ../../Scripts/ci-guards.sh .git/hooks/pre-commit
```

## SwiftLint Integration

The project uses both bash guards and SwiftLint custom rules for comprehensive boundary enforcement:

- **Bash Guards**: Fast fail-fast checks for CI/CD
- **SwiftLint Rules**: IDE integration and detailed reporting

See `AirFit/.swiftlint.yml` for custom boundary rules that mirror the CI guards.

## Staged Rollout Strategy

### Phase 1: Warnings Only
- Set all custom SwiftLint rules to `severity: warning`
- Run guards in CI but don't fail builds
- Monitor violation patterns

### Phase 2: Critical Boundaries
- Enable `severity: error` for:
  - `no_force_ops`
  - `no_direct_urlsession` 
  - `require_mainactor_viewmodels`

### Phase 3: Full Enforcement
- Enable all guards as CI blockers
- Set all custom rules to `severity: error`

## Troubleshooting

### Common Issues

**Guard fails with "command not found"**
- Ensure `rg` (ripgrep) is installed: `brew install ripgrep`

**False positives in tests**
- Update exclusion patterns in guards
- Add `# swiftlint:disable:next [rule_name]` for legitimate exceptions

**Performance on large codebases**
- Guards use ripgrep for fast searching
- Typical runtime: <5 seconds for medium projects

### Maintenance

**Adding new guards:**
1. Add check to `ci-guards.sh`
2. Add corresponding SwiftLint rule to `.swiftlint.yml`
3. Test locally before committing
4. Update this README

**Modifying patterns:**
- Test regex patterns with `rg` directly first
- Use `--dry-run` equivalents when possible
- Consider false positive/negative rates

## Development

**Testing guards locally:**
```bash
# Run all guards
./Scripts/ci-guards.sh

# Test specific patterns manually
rg -n --no-heading -S 'try!| as!| !\.' AirFit --glob '**/*.swift'
```

**Performance profiling:**
```bash
time ./Scripts/ci-guards.sh
```

Expected runtime: 2-8 seconds depending on codebase size.