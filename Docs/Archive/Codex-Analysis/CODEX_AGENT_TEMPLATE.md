# Codex Agent Execution Template

## For Each Agent Task

### Step 1: Send System Prompt
Copy the entire contents of `AGENTS.md` and send as the system/behavior prompt.

### Step 2: Send Analysis Task
Copy the specific agent prompt from the wave files.

### Step 3: Output Instructions
Add this to each agent prompt:
```
Please output your analysis as a markdown document that would be saved to:
Docs/Research Reports/[SpecifiedFileName].md

Include in your analysis:
- Executive summary of findings
- Detailed analysis with code references (file:line format)
- Identified issues with severity (Critical/High/Medium/Low)
- Specific recommendations
- Questions that need clarification
```

## Example: Agent 1 Execution

**System Prompt**: [Contents of AGENTS.md]

**Task Prompt**:
```
Analyze the overall architecture of the AirFit iOS application. Start with the directory structure and work your way through understanding the architectural patterns. Document:

1. Project Structure Analysis:
   - Map the complete directory structure and explain the purpose of each major folder
   - Identify the architectural pattern (MVVM, MVVM-C, etc.) and how it's implemented
   - Document the module organization and boundaries

[... rest of Agent 1 prompt ...]

Please output your analysis as a markdown document that would be saved to:
Docs/Research Reports/Architecture_Overview_Analysis.md
```

## Quick Copy Commands

### Wave 1 Agents (Run these first for black screen diagnosis)
```
Agent 1 → Architecture_Overview_Analysis.md
Agent 2 → App_Lifecycle_Analysis.md (CRITICAL for black screen)
Agent 3 → DI_System_Complete_Analysis.md (CRITICAL for black screen)
Agent 4 → Concurrency_Model_Analysis.md (CRITICAL for black screen)
Agent 5 → Service_Layer_Complete_Catalog.md
```

### Wave 2 Agents
```
Agent 6 → Onboarding_Module_Analysis.md
Agent 7 → AI_System_Complete_Analysis.md
Agent 8 → Data_Layer_Analysis.md
Agent 9 → UI_Implementation_Analysis.md
Agent 10 → Testing_Architecture_Analysis.md
```

### Wave 3 Agents
```
Agent 11 → Network_Integration_Analysis.md
Agent 12 → Voice_Integration_Analysis.md
Agent 13 → HealthKit_Integration_Analysis.md
Agent 14 → Performance_Analysis.md
Agent 15 → Build_Configuration_Analysis.md
```

## Priority Execution for Black Screen Issue

If you want to quickly diagnose the black screen issue, prioritize:
1. Agent 2 (App Lifecycle) - Will trace the exact initialization flow
2. Agent 3 (DI System) - Will analyze async resolution issues
3. Agent 4 (Concurrency) - Will map actor isolation conflicts

These three should provide enough information to understand and fix the black screen issue definitively.