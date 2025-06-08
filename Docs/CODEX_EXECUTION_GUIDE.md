# Codex Agent Execution Guide

## Overview
This guide helps you execute the 15 Codex agent analysis tasks to comprehensively understand the AirFit codebase.

## Execution Steps

### 1. Prepare Each Agent
For each agent task:
1. First send the contents of `AGENTS.md` as the system prompt
2. Then send the specific analysis prompt from the wave files
3. Direct output to the specified markdown file in `Docs/Research Reports/`

### 2. Wave Execution Order

#### Wave 1: Architecture & Structure (Agents 1-5)
**Files**: `AGENT_PROMPTS_WAVE1.md`
- Agent 1: High-Level Architecture → `Architecture_Overview_Analysis.md`
- Agent 2: App Lifecycle → `App_Lifecycle_Analysis.md`
- Agent 3: DI System → `DI_System_Complete_Analysis.md`
- Agent 4: Concurrency Model → `Concurrency_Model_Analysis.md`
- Agent 5: Service Catalog → `Service_Layer_Complete_Catalog.md`

**Focus**: Understanding the foundation and identifying the black screen issue

#### Wave 2: Feature Modules & Business Logic (Agents 6-10)
**Files**: `AGENT_PROMPTS_WAVE2.md`
- Agent 6: Onboarding Module → `Onboarding_Module_Analysis.md`
- Agent 7: AI System → `AI_System_Complete_Analysis.md`
- Agent 8: Data Layer → `Data_Layer_Analysis.md`
- Agent 9: UI Implementation → `UI_Implementation_Analysis.md`
- Agent 10: Testing Architecture → `Testing_Architecture_Analysis.md`

**Focus**: Deep dive into features and business logic

#### Wave 3: Integration & Advanced Features (Agents 11-15)
**Files**: `AGENT_PROMPTS_WAVE3.md`
- Agent 11: Network Integration → `Network_Integration_Analysis.md`
- Agent 12: Voice Integration → `Voice_Integration_Analysis.md`
- Agent 13: HealthKit Integration → `HealthKit_Integration_Analysis.md`
- Agent 14: Performance Analysis → `Performance_Analysis.md`
- Agent 15: Build Configuration → `Build_Configuration_Analysis.md`

**Focus**: External integrations and system optimization

## Expected Outputs

Each agent should produce:
- A 2-4 page markdown report
- Code snippets with file paths and line numbers
- Identified issues with severity ratings
- Specific recommendations
- Questions that need clarification

## Synthesis Process

After all agents complete:

1. **Review All Reports**: Read through all 15 analysis documents
2. **Create Master Document**: `Docs/MASTER_ARCHITECTURE_ANALYSIS.md`
3. **Prioritize Issues**: Create `Docs/ISSUE_PRIORITY_LIST.md`
4. **Design Solutions**: Create `Docs/SOLUTION_ARCHITECTURE.md`
5. **Migration Plan**: Create `Docs/MIGRATION_ROADMAP.md`

## Key Areas to Focus On

Based on current issues:
1. **Black Screen Issue**: Agents 2, 3, 4 should provide insights
2. **Actor Isolation**: Agent 4 will map the concurrency issues
3. **Demo Mode Complexity**: Agents 5 and 7 will analyze AI service complexity
4. **Initialization Flow**: Agents 2 and 3 will trace the startup sequence

## Running in Parallel

You can run multiple agents in parallel since they analyze different aspects:
- Wave 1 agents can all run simultaneously
- Wave 2 can start once you have Wave 1 results
- Wave 3 can run independently

## Important Notes

1. **Codex Limitations**: Agents can only analyze code, not run/build
2. **File References**: Ensure agents include specific file paths
3. **Version Context**: All analysis is for the current state (January 2025)
4. **Focus on Facts**: Agents should document what EXISTS, not speculate

---

## Quick Start Commands

```bash
# Create Research Reports directory if it doesn't exist
mkdir -p "Docs/Research Reports"

# After agents complete, check all reports exist
ls -la "Docs/Research Reports/"

# Count completed reports
find "Docs/Research Reports" -name "*.md" | wc -l
# Should show 15 when all complete
```

## Next Steps After Analysis

1. Review the black screen issue findings first
2. Understand the actor isolation complexity
3. Plan the architectural improvements
4. Execute fixes with confidence based on comprehensive understanding