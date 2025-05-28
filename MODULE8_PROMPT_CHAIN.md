# **MODULE 8: FOOD TRACKING IMPLEMENTATION**

**Prerequisites**: Modules 0-7 complete, all tests passing.

---

## **CRITICAL DEPENDENCY RESOLUTION**

**BLOCKER**: Module 8 requires VoiceInputManager, but it's in Module 13.  
**SOLUTION**: Extract VoiceInputManager to shared services first.

---

## **TASK SEQUENCE**

### **Task 8.0: Extract VoiceInputManager** ⚠️ **MUST BE FIRST**

**Create Files:**
1. `AirFit/Services/Speech/VoiceInputManagerProtocol.swift`
2. `AirFit/Services/Speech/VoiceInputManager.swift` 
3. `AirFit/Services/Speech/WhisperModelManager.swift`

**Add to project.yml:**
```yaml
# AirFit target sources:
- AirFit/Services/Speech/VoiceInputManagerProtocol.swift
- AirFit/Services/Speech/VoiceInputManager.swift
- AirFit/Services/Speech/WhisperModelManager.swift
```

**Key Implementation:**
- WhisperKit integration with device-specific model selection
- Real-time transcription with waveform visualization
- Memory management for large models
- Swift 6 concurrency compliance

---

### **Task 8.1: Food Tracking Infrastructure** ⚠️ **SEQUENTIAL**

**Create Files:**
1. `AirFit/Modules/FoodTracking/FoodTrackingCoordinator.swift`
2. `AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift`
3. `AirFit/Modules/FoodTracking/Services/NutritionService.swift`
4. `AirFit/Modules/FoodTracking/Services/NutritionServiceProtocol.swift`

---

### **Task 8.2: Voice Input UI** 🔄 **PARALLEL**

**Create Files:**
1. `AirFit/Modules/FoodTracking/Views/VoiceInputView.swift`
2. `AirFit/Modules/FoodTracking/Views/Components/WaveformView.swift`
3. `AirFit/Modules/FoodTracking/Views/Components/VoiceRecordingButton.swift`

---

### **Task 8.3: Food Database** 🔄 **PARALLEL**

**Create Files:**
1. `AirFit/Modules/FoodTracking/Services/FoodDatabaseService.swift`
2. `AirFit/Modules/FoodTracking/Services/FoodDatabaseServiceProtocol.swift`
3. `AirFit/Modules/FoodTracking/Views/FoodSearchView.swift`
4. `AirFit/Modules/FoodTracking/Views/BarcodeScannerView.swift`

---

### **Task 8.4: Nutrition Visualization** 🔄 **PARALLEL**

**Create Files:**
1. `AirFit/Modules/FoodTracking/Views/Components/MacroRingsView.swift`
2. `AirFit/Modules/FoodTracking/Views/NutritionSummaryView.swift`
3. `AirFit/Modules/FoodTracking/Views/FoodTrackingFlowView.swift`

---

### **Task 8.5: Integration & Testing** ⚠️ **MUST BE LAST**

**Create Files:**
1. `AirFit/AirFitTests/FoodTracking/VoiceInputManagerTests.swift`
2. `AirFit/AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift`
3. `AirFit/AirFitTests/FoodTracking/NutritionServiceTests.swift`

**Update Files:**
- Add food tracking cards to existing Dashboard views
- Update project.yml with all new files

---

## **PARALLELIZATION STRATEGY**

**Sequential (Must be done in order):**
- Task 8.0 → Task 8.1 → Task 8.5

**Parallel (Can be done simultaneously after 8.1):**
- Task 8.2: Voice Input UI
- Task 8.3: Food Database  
- Task 8.4: Nutrition Visualization

**Agent Assignment:**
- **Agent 1**: Tasks 8.0 → 8.1 → 8.5 (Sequential path)
- **Agent 2**: Task 8.2 (Voice UI)
- **Agent 3**: Task 8.3 (Food Database)
- **Agent 4**: Task 8.4 (Nutrition Visualization)

---

## **AUDIT CHECKPOINTS**

### **Checkpoint 1: Core Services** (After Task 8.0)
- [ ] VoiceInputManager functional
- [ ] WhisperKit integration working
- [ ] Device-specific model selection
- [ ] Memory management implemented

### **Checkpoint 2: Voice Infrastructure** (After Tasks 8.1-8.2)
- [ ] Voice transcription end-to-end
- [ ] Waveform visualization functional
- [ ] Error handling robust
- [ ] UI responsive during transcription

### **Checkpoint 3: Complete System** (After All Tasks)
- [ ] Food logging via voice functional
- [ ] Nutrition tracking accurate
- [ ] Dashboard integration seamless
- [ ] All tests passing

---

## **CRITICAL IMPLEMENTATION NOTES**

### **WhisperKit Configuration**
```yaml
# Add to project.yml dependencies:
dependencies:
  - package: https://github.com/argmaxinc/WhisperKit.git
    from: "0.9.0"
```

### **Model Selection Logic**
```swift
func selectOptimalModel() -> String {
    let deviceMemory = ProcessInfo.processInfo.physicalMemory
    if deviceMemory >= 8_000_000_000 { return "large-v3" }
    else if deviceMemory >= 6_000_000_000 { return "medium" }
    else { return "base" }
}
```

### **Performance Targets**
- Voice transcription: <2s latency
- Model cold start: <5s (first use only)
- UI responsiveness: 60fps during transcription
- Memory usage: <1.8GB peak (with large model)

---

## **ESTIMATED TIME: 16 HOURS**

- Task 8.0: 4 hours (VoiceInputManager)
- Task 8.1: 3 hours (Infrastructure)
- Task 8.2: 3 hours (Voice UI)
- Task 8.3: 2 hours (Food Database)
- Task 8.4: 2 hours (Nutrition Visualization)
- Task 8.5: 2 hours (Integration & Testing) 