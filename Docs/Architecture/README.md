# AirFit Architecture Documentation

This directory contains comprehensive documentation about the AirFit iOS application architecture, dependency structure, and layering rules.

## Documents Overview

### 📊 [DEPENDENCY_MAP.md](./DEPENDENCY_MAP.md)
Complete visual representation of module dependencies, layer boundaries, and architectural patterns. Includes:
- Layer hierarchy diagrams
- Module responsibility matrix
- Dependency flow rules
- Key abstraction points

### 📋 [LAYERING_RULES.md](./LAYERING_RULES.md)
Strict architectural rules governing dependencies between layers. Includes:
- Layer definitions and responsibilities
- Allowed vs forbidden dependency patterns
- Code examples (good vs bad patterns)
- Enforcement strategies

### 📈 [ARCHITECTURAL_ANALYSIS.md](./ARCHITECTURAL_ANALYSIS.md)
Comprehensive analysis of architectural health, hotspots, and improvement areas. Includes:
- Dependency analysis and compliance scores
- Hotspot identification
- Violation detection results
- Performance analysis and remediation plan

### 🔗 [dependency-graph.dot](./dependency-graph.dot)
DOT graph representation of the complete dependency structure for visualization.

## Visualizing the Dependency Graph

### Option 1: Command Line (with Graphviz installed)
```bash
# Install Graphviz (macOS)
brew install graphviz

# Generate PNG image
dot -Tpng dependency-graph.dot -o dependency-graph.png

# Generate SVG (scalable)
dot -Tsvg dependency-graph.dot -o dependency-graph.svg

# Generate PDF
dot -Tpdf dependency-graph.dot -o dependency-graph.pdf
```

### Option 2: Online Visualization
1. Copy the contents of `dependency-graph.dot`
2. Visit [Graphviz Visual Editor](http://magjac.com/graphviz-visual-editor/)
3. Paste the DOT content and click "Show graph"
4. Export as desired format (PNG, SVG, PDF)

### Option 3: VS Code Extension
1. Install the "Graphviz (dot) language support" extension
2. Open `dependency-graph.dot` in VS Code
3. Use Command Palette: "Graphviz: Preview to the Side"

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                 Application Layer                    │  
│              (AirFitApp, ContentView)               │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Module Layer                       │
│        (Dashboard, Chat, Settings, FoodTracking)    │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                  Service Layer                       │
│    (AI, Health, Analytics, Security, Nutrition)     │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Data Layer                         │
│       (Repositories, Models, Managers)              │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Core Layer                         │
│       (DI, Protocols, Utilities, Components)        │
└─────────────────────────────────────────────────────┘
```

## Key Architectural Principles

1. **Layered Architecture**: Clear separation between Application, Module, Service, Data, and Core layers
2. **Dependency Injection**: Protocol-based dependencies resolved through DIContainer
3. **Repository Pattern**: Data access abstracted through repository protocols
4. **Protocol-Driven Design**: Service boundaries defined by protocols, not implementations
5. **Single Responsibility**: Each layer and module has a focused, well-defined purpose

## Architecture Health

### Current Metrics (as of 2025-09-06)
- **Layer Compliance**: 92% ✅
- **Protocol Usage**: 95% ✅ 
- **Test Coverage**: 85% ✅
- **Circular Dependencies**: 0 ✅
- **Technical Debt Score**: 15/100 (Low) ✅

### Quality Gates
- No layer violations allowed in production
- All service dependencies must use protocols
- ViewModels may not directly access SwiftData
- Core layer must remain foundational (no upward dependencies)

## Development Guidelines

### Adding New Features
1. Identify appropriate layer for new functionality
2. Define protocols before implementations
3. Use dependency injection for all service dependencies
4. Follow repository pattern for data access
5. Create corresponding test doubles

### Refactoring Guidelines
1. Check dependency graph impact before changes
2. Maintain layer boundaries during refactoring
3. Update architecture documentation when needed
4. Run layer compliance checks after changes

## Tools and Scripts

### Architecture Validation
```bash
# Check for layer violations (example)
find AirFit/Modules -name "*.swift" -exec grep -l "@Environment(\.modelContext)" {} \;

# Count service dependencies per ViewModel
rg -n "private let.*Protocol" AirFit/Modules --type swift
```

### Dependency Analysis
```bash
# Find high-complexity modules
rg -c "import " AirFit/Modules --type swift | sort -t: -k2 -nr

# Identify concrete service usage (should be rare)
rg -n "= .*Service\(\)" AirFit/Modules --type swift
```

## Maintenance Schedule

### Weekly
- [ ] Review dependency changes in PRs
- [ ] Check for new layer violations
- [ ] Monitor service complexity growth

### Monthly  
- [ ] Generate updated dependency graph
- [ ] Review architecture metrics
- [ ] Update documentation if needed

### Quarterly
- [ ] Comprehensive architectural review
- [ ] Technical debt assessment
- [ ] Performance analysis update

## Contact

For architecture questions or concerns:
- Create an issue with the `architecture` label
- Reference this documentation in architecture discussions
- Include dependency impact analysis in significant changes

---

*Last updated: 2025-09-06*  
*Documentation version: 1.0*