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
- [ ] Follow naming standards (ALL_CAPS_WITH_UNDERSCORES)
- [ ] Use appropriate prefix (GUIDE_, PLAN_, ANALYSIS_, etc.)
- [ ] Place in correct folder
- [ ] Add to relevant index/README

## After Documentation Changes

### 1. Update references
- [ ] Update CLAUDE.md if needed
- [ ] Update module README if applicable
- [ ] Check for broken links

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
├── PLAN_CLEANUP.md (current)
└── Archive/
    └── 2025_01/
        └── PLAN_CLEANUP_INITIAL.md

Incorrect:
├── PLAN_CLEANUP.md
├── PLAN_CLEANUP_NEW.md
├── PLAN_CLEANUP_REVISED.md
└── PLAN_CLEANUP_FINAL_FINAL.md
```

## Quick Rules

1. **One authoritative source** per topic
2. **Archive, don't duplicate** 
3. **Date in folders, not filenames**
4. **Clear prefixes** indicate document type
5. **Update in place** rather than creating variants