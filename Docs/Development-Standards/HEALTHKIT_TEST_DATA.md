# HealthKit Test Data Generator

## Overview
The HealthKit Test Data Generator is a DEBUG-only tool for populating the iOS Simulator with realistic health data. This helps with development and testing without needing actual device data.

## Features
- **Activity Data**: Steps, calories, distance, stand hours, exercise minutes
- **Nutrition Data**: Meals with macros, water intake
- **Body Metrics**: Weight, body fat percentage, BMI
- **Workouts**: Various workout types with heart rate data
- **Sleep Data**: Sleep stages (REM, Core, Deep) with realistic patterns
- **Heart Health**: Heart rate, HRV, resting heart rate, VO2 Max

## Accessing the Generator

### From Settings (DEBUG builds only)
1. Navigate to Settings → Debug Tools
2. Find the "HealthKit Test Data" section
3. Choose from:
   - **Generate Today's Data**: Creates comprehensive data for today
   - **Generate 7 Days History**: Creates a week of historical data
   - **Generate 30 Days History**: Creates a month of historical data
   - **Custom Data Generator**: Fine-grained control over data types and dates

### Programmatic Usage
```swift
#if DEBUG
let generator = HealthKitTestDataGenerator(healthStore: healthStore)

// Generate today's data
try await generator.generateTestDataForToday()

// Generate historical data
try await generator.generateHistoricalData(days: 7)

// Generate specific data types
try await generator.generateActivityData(for: Date())
try await generator.generateNutritionData(for: Date())
try await generator.generateBodyMetrics(for: Date())
try await generator.generateWorkoutData(for: Date())
try await generator.generateSleepData(for: Date())
try await generator.generateHeartHealthData(for: Date())
#endif
```

## Data Characteristics

### Activity Data
- Steps vary by time of day (higher during commute/lunch)
- Stand hours from 7 AM to 9 PM with 80% probability
- Exercise minutes in morning or evening sessions

### Nutrition Data
- Breakfast: 300-500 calories
- Lunch: 500-700 calories
- Dinner: 600-800 calories
- Snacks: 70% probability, 100-200 calories
- Water intake throughout the day

### Body Metrics
- Weight variations of ±0.5kg from base
- Body fat percentage: 15-25%
- BMI: 20-27
- Generated every 3 days in historical data

### Workouts
- Types: Running, cycling, walking, strength training, yoga, swimming
- Duration: 30-90 minutes
- Calories based on activity type
- Heart rate data during workouts
- Generated on specific days (not daily)

### Sleep Data
- Bedtime: ~10 PM
- Wake time: ~7 AM
- Includes sleep stages (Core, REM, Deep)
- Brief awakening periods for realism

### Heart Health
- Resting heart rate: 55-75 bpm
- Heart rate varies by time of day
- HRV: 30-60 ms
- VO2 Max: 35-55 ml/kg/min (weekly)

## Important Notes

1. **Simulator Only**: This feature is designed for the iOS Simulator
2. **DEBUG Builds**: Only available in DEBUG configuration
3. **Authorization Required**: HealthKit authorization must be granted
4. **Metadata Tagging**: All generated data includes `"AirFitTestData": true` metadata
5. **Realistic Patterns**: Data follows realistic patterns for testing

## Custom Data Generator

The custom generator provides:
- Select specific data types to generate
- Choose date ranges (Today, Yesterday, Last 7/30 days, Custom)
- Progress tracking during generation
- Batch operations for efficiency

## Best Practices

1. **Clear Previous Data**: Use Health app to clear old test data before generating new sets
2. **Test Edge Cases**: Generate data for different scenarios (no workouts, missing meals, etc.)
3. **Verify in Health App**: Check that generated data appears correctly in Apple Health
4. **Use Appropriate Ranges**: Don't generate excessive historical data (impacts performance)

## Troubleshooting

### Authorization Issues
- Ensure HealthKit is enabled in app capabilities
- Grant all requested permissions when prompted
- Check Settings → Privacy → Health → AirFit

### Data Not Appearing
- Verify HealthKit authorization status
- Check for errors in console/status messages
- Ensure you're running on iOS Simulator
- Try clearing Health app data and regenerating

### Performance Issues
- Limit historical data generation to necessary ranges
- Use custom generator for specific data types only
- Consider generating data in smaller batches