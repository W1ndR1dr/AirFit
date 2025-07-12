# Phase 3 Manual Test Checklist

## Pre-Change Baseline
Run these tests BEFORE making any changes to verify current functionality.

### 1. AI Service Basic Operations
- [ ] Launch app
- [ ] Navigate to Settings > AI Configuration
- [ ] Verify AI service status shows "Connected" or appropriate state
- [ ] Send a basic message in coach chat
- [ ] Verify response streams in character by character

### 2. Persona Generation
- [ ] Start new onboarding flow
- [ ] Complete conversation
- [ ] Verify persona is generated
- [ ] Check persona maintains consistent voice

### 3. Function Calling
- [ ] In coach chat, type "Set a goal to gain 10 pounds of muscle"
- [ ] Verify goal is created in database
- [ ] Type "I ate a chicken salad with ranch dressing"
- [ ] Verify nutrition is parsed and logged

### 4. Demo Mode
- [ ] Enable demo mode in settings
- [ ] Verify coach still responds (with canned responses)
- [ ] Disable demo mode
- [ ] Verify real AI responses return

### 5. Error Handling
- [ ] Remove API key temporarily
- [ ] Try to send message
- [ ] Verify user-friendly error appears
- [ ] Re-add API key

## Critical Metrics
- App launch time: _____ seconds
- Time to first AI response: _____ seconds
- Streaming smoothness: Smooth / Choppy
- Memory usage baseline: _____ MB

## Post-Change Validation
After EACH change:
1. Run `xcodebuild build`
2. Check for warnings/errors
3. Re-run affected tests above
4. Compare metrics

## Red Flags - STOP if any occur:
- [ ] Persona voice changes
- [ ] Function calls stop working
- [ ] Streaming becomes choppy
- [ ] Error messages become technical
- [ ] Demo mode breaks
- [ ] Build warnings increase