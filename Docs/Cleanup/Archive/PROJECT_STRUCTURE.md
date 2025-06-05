# AirFit Project Structure - Absolute Paths

## Root Directory
```
/Users/Brian/Coding Projects/AirFit/
├── AirFit/                      # Main app directory
├── AirFitWatchApp/              # Watch app
├── Cleanup/                     # Architecture cleanup docs
├── CodeMap/                     # Project mapping docs
├── Scripts/                     # Build and utility scripts
├── node_modules/                # Node dependencies
├── .git/                        # Git repository
├── AirFit.xcodeproj/            # Xcode project
├── project.yml                  # XcodeGen config
├── CLAUDE.md                    # AI assistant guide
├── TESTING_GUIDELINES.md        # Testing standards
└── [other root files]
```

## Main App Directory Structure
```
/Users/Brian/Coding Projects/AirFit/AirFit/
├── Application/                 # App entry point
├── Core/                        # Shared code
├── Data/                        # SwiftData models
├── Modules/                     # Feature modules
├── Services/                    # Business logic
├── Resources/                   # Assets, strings
├── Docs/                        # ⚠️ THIS is where docs go!
├── AirFitTests/                 # Test suite
└── AirFitUITests/               # UI tests
```

## Common Confusion Points

### ❌ WRONG Paths:
- `/Users/Brian/Coding Projects/AirFit/Docs/` - This would be root level
- `Docs/` - Ambiguous, could mean anywhere
- `./Docs/` - Relative to current directory

### ✅ CORRECT Paths:
- `/Users/Brian/Coding Projects/AirFit/AirFit/Docs/` - App documentation
- `/Users/Brian/Coding Projects/AirFit/Cleanup/` - Cleanup documentation
- `/Users/Brian/Coding Projects/AirFit/CodeMap/` - Project mapping

## Quick Reference

| What | Where |
|------|-------|
| App documentation | `/AirFit/Docs/` |
| Module specs | `/AirFit/Docs/ModuleX.md` |
| Cleanup plans | `/Cleanup/` |
| Project mapping | `/CodeMap/` |
| Build scripts | `/Scripts/` |
| Test files | `/AirFit/AirFitTests/` |

## Before Creating Files

Always run:
```bash
# Verify the directory exists
ls -la "/Users/Brian/Coding Projects/AirFit/AirFit/Docs/"

# Or use find to check
find /Users/Brian/Coding\ Projects/AirFit -name "Docs" -type d
```