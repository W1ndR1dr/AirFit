# Documentation Checklist

## Before Creating New Documentation

### 1. Check if it already exists
- [ ] Search for similar docs using grep/find
- [ ] Check the archive folder
- [ ] Look in CodeMap for references

### 2. If updating existing docs
- [ ] Update the original file
- [ ] Move old version to Archive/ with date folder
- [ ] Update any references to the doc

### 3. If creating new docs
- [ ] Follow naming standards (UPPER_CASE_WITH_UNDERSCORES.md)
- [ ] Use appropriate prefix:
  - `TEST_` for test-related docs
  - `API_` for API documentation
  - `GUIDE_` for how-to guides
  - `PLAN_` for planning documents
  - `ANALYSIS_` for analysis/research
- [ ] Place in correct folder (root Docs/ for active, Archive/ for old)
- [ ] Add to relevant index/README
- [ ] Include "Last Updated" date at top

## After Documentation Changes

### 1. Update references
- [ ] Update CLAUDE.md if it references the doc
- [ ] Update TEST_README.md if test-related
- [ ] Update any parent README files
- [ ] Check for broken links
- [ ] Update progress tracking if applicable

### 2. Clean up
- [ ] Remove any temporary files
- [ ] Archive superseded versions
- [ ] Delete "NEW" or "REVISED" variants

### 3. Validate
- [ ] File names follow standards
- [ ] No duplicate information
- [ ] Clear ownership (which doc is authoritative)

## Red Flags 🚩

If you find yourself:
- Adding version numbers to filenames
- Creating "NEW" or "OLD" variants
- Making multiple similar documents
- Unsure which doc is current

**STOP** and reorganize first!

## Documentation Structure

```
Correct:
├── Docs/
│   ├── TEST_STANDARDS.md (current)
│   ├── TEST_EXECUTION_PLAN.md (with progress tracking)
│   └── Archive/
│       └── 2025-01/
│           └── OLD_TEST_GUIDELINES.md

Incorrect:
├── TEST_STANDARDS.md
├── TEST_STANDARDS_NEW.md
├── TEST_STANDARDS_v2.md
└── TEST_STANDARDS_FINAL.md
```

## Current Active Documentation

### Test Suite Refactoring
- `TEST_README.md` - Start here
- `TEST_REFACTORING_PLAN.md` - Strategy
- `TEST_STANDARDS.md` - Standards to follow
- `TEST_MIGRATION_GUIDE.md` - How to migrate
- `TEST_EXECUTION_PLAN.md` - Task tracking

### Project Standards
- `NAMING_STANDARDS.md` - File naming rules
- `PROJECT_FILE_MANAGEMENT.md` - XcodeGen guide
- `TESTING_GUIDELINES.md` - Reference (see TEST_* for current work)

## Quick Rules

1. **One authoritative source** per topic
2. **Archive, don't duplicate** 
3. **Date in folders (YYYY-MM), not filenames**
4. **Clear prefixes** indicate document type
5. **Update in place** rather than creating variants
6. **Progress tracking** in execution plans, not separate docs
7. **Link related docs** rather than duplicating content

## Common Documentation Patterns

### For Planning Documents
```markdown
# [TITLE]

**Purpose**: One-line description  
**Last Updated**: YYYY-MM-DD  
**Status**: Active/Complete/Archived
```

### For Guides
```markdown
# [TITLE]

**Purpose**: What this guide helps with  
**Audience**: Who should read this  
**Prerequisites**: What to know/read first
```

### For Task Tracking
```markdown
- [ ] Task description
- [🚧] In progress (only one at a time)
- [✅] Completed
- [❌] Blocked (reason)
```