# Cleanup Folder Reorganization Plan

## Current State (15 files, confusing structure)

The folder is overwhelming with:
- 2 competing "start here" docs (README.md, PRESERVATION_GUIDE.md)
- Duplicate phase docs (original + revised)
- Scattered analysis files
- No clear execution path

## Proposed New Structure

```
Cleanup/
├── START_HERE.md                    # 30-second to 5-minute orientation
├── CLEANUP_TRACKER.md               # Visual progress dashboard
│
├── 00_CRITICAL/
│   └── PRESERVATION_GUIDE.md        # What NOT to break
│
├── 01_ACTIVE_PHASES/
│   ├── PHASE_1_CRITICAL_FIXES.md   # Current work
│   ├── PHASE_2_SERVICE_MIGRATION.md 
│   ├── PHASE_3_STANDARDIZATION.md   # (Revised version only)
│   └── PHASE_4_DI_IMPROVEMENTS.md   # (Revised version only)
│
└── 02_REFERENCE/
    ├── ANALYSIS_SUMMARY.md          # Consolidated findings
    └── ARCHIVE/
        ├── (All original analysis docs)
        ├── (Original phase 3 & 4)
        └── (Old READMEs)
```

## Files to Consolidate/Archive

**Archive these** (keep for reference but out of main flow):
- DEEP_ARCHITECTURE_ANALYSIS.md
- IMPORT_DEPENDENCY_ANALYSIS.md  
- AI_SERVICE_CATEGORIZATION.md
- ARCHITECTURE_CLEANUP_PLAN.md
- IMMEDIATE_ACTION_PLAN.md
- ARCHITECTURE_CLEANUP_EXECUTIVE_SUMMARY.md
- PHASE_3_ANALYSIS_REPORT.md
- Original README.md
- Original CLEANUP_PHASE_3_STANDARDIZATION.md
- Original CLEANUP_PHASE_4_DI_OVERHAUL.md

**Keep Active** (renamed/reorganized):
- START_HERE.md (new)
- CLEANUP_TRACKER.md (new)
- PRESERVATION_GUIDE.md → 00_CRITICAL/
- CLEANUP_PHASE_1_CRITICAL_FIXES.md → 01_ACTIVE_PHASES/PHASE_1_*
- CLEANUP_PHASE_2_SERVICE_MIGRATION.md → 01_ACTIVE_PHASES/PHASE_2_*
- CLEANUP_PHASE_3_STANDARDIZATION_REVISED.md → 01_ACTIVE_PHASES/PHASE_3_*
- CLEANUP_PHASE_4_DI_OVERHAUL_REVISED.md → 01_ACTIVE_PHASES/PHASE_4_*

## Benefits of New Structure

1. **Clear Entry Point**: START_HERE.md gives immediate context
2. **Visual Progress**: CLEANUP_TRACKER.md shows status at a glance
3. **Execution Focus**: 01_ACTIVE_PHASES has only what you need to do
4. **Preservation First**: 00_CRITICAL ensures you see warnings first
5. **Clean Workspace**: Archives provide history without clutter

## Migration Commands

```bash
# Create new structure
mkdir -p Cleanup/00_CRITICAL
mkdir -p Cleanup/01_ACTIVE_PHASES  
mkdir -p Cleanup/02_REFERENCE/ARCHIVE

# Move files (examples)
mv Cleanup/PRESERVATION_GUIDE.md Cleanup/00_CRITICAL/
mv Cleanup/CLEANUP_PHASE_1_CRITICAL_FIXES.md Cleanup/01_ACTIVE_PHASES/PHASE_1_CRITICAL_FIXES.md
# ... etc

# Archive old files
mv Cleanup/DEEP_ARCHITECTURE_ANALYSIS.md Cleanup/02_REFERENCE/ARCHIVE/
# ... etc
```

This structure makes it impossible to get lost - you start at START_HERE, check progress in TRACKER, and execute from ACTIVE_PHASES.