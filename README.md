# Fitness Tracker iOS

🏋️‍♂️ A native iOS app that syncs your workouts from Apple Health to your fitness tracker web app.

## Overview

This iOS app automatically syncs your workouts from Apple Health to your fitness tracker web app, giving you seamless cross-device access to your workout data.

## Features

- 🎨 **Apple Health Integration** - Automatically reads workout data from HealthKit
- 🚀 **Automatic Sync** - Push workouts to your web app with one tap
- 📊 **Comprehensive Data** - Tracks duration, distance, calories, and weight lifted
- 🔄 **Smart Sync** - Only syncs new workouts since last sync
- 🌐 **Web App Integration** - Seamlessly works with your Vercel-deployed fitness tracker

## Supported Sources

- 🚴‍♂️ **Peloton** - Cycling, running, strength, yoga, walking
- 💪 **Tonal** - Strength training with weight tracking
- 🚵 **Cannondale** - Outdoor cycling
- 🏋️ **Gym** - Weight lifting, running, swimming
- ✨ **Other** - Any other fitness app that syncs to Apple Health

## Supported Activities

- 🚴‍♂️ **Cycling** (Indoor)
- 🚵 **Outdoor Cycling**
- 🏃‍♂️ **Running**
- 🚶‍♂️ **Walking**
- 💪 **Weight Lifting** (with weight tracking)
- 🧘‍♀️ **Yoga**
- 🏊‍♂️ **Swimming**
- ✨ **Other** (General workouts)

## Data Tracked

- **Duration** - Workout time in minutes
- **Distance** - Automatically converted to miles
- **Weight Lifted** - Total weight for strength workouts (lbs)
- **Calories** - Energy burned
- **Source App** - Automatically detected (Peloton, Tonal, Cannondale, Gym, etc.)
- **Activity Type** - Mapped to match web app categories

## How It Works

```
Workout App → Apple Health → iOS App → Web App Database → Web App
```

1. **Complete a workout** on any supported app
2. **Workout syncs** to Apple Health automatically
3. **Open this iOS app** and tap "Sync Now"
4. **View your data** on the web app with charts and insights

## Setup

### Prerequisites

- iOS 14.0 or later
- Xcode 13.0 or later
- Apple Health app with workout data
- Fitness apps syncing to Apple Health

### Installation

1. Clone this repository
2. Open `FitnessTracker.xcodeproj` in Xcode
3. Update the API URL in `WorkoutService.swift` if needed:
   ```swift
   private let baseURL = "https://fitness-tracker-carryologist.vercel.app/api"
   ```
4. Build and run on your device (simulator won't have HealthKit data)

### HealthKit Permissions

The app will request permission to read:
- Workouts
- Active Energy Burned
- Distance (Walking/Running/Cycling)
- Heart Rate
- Body Mass (for weight tracking context)

## Usage

1. **Grant HealthKit Access** - Allow the app to read your workout data
2. **View Recent Workouts** - See your last 30 days of workouts
3. **Tap "Sync Now"** - Send new workouts to your web app
4. **Check Sync Status** - See when you last synced

## Smart Features

### Intelligent Source Detection
The app automatically identifies workout sources:
- Peloton workouts → "Peloton"
- Tonal workouts → "Tonal"
- Cannondale rides → "Cannondale"
- Gym apps → "Gym"
- Everything else → "Other"

### Activity Mapping
HealthKit workout types are intelligently mapped to web app activities:
- Functional/Traditional Strength Training → "Weight lifting"
- Mixed Cardio from Cannondale → "Outdoor cycling"
- All activities filtered based on source for accuracy

### Weight Lifted Estimation
For strength workouts:
- Checks for direct weight data in workout metadata
- Tonal workouts: Enhanced calculation based on workout patterns
- General gym workouts: Estimates based on calories and duration

### Unit Conversion
- Distance automatically converted from meters to miles
- Weight displayed in pounds (lbs)
- Smart formatting for large numbers (e.g., "10k lbs")

## API Integration

The app syncs with your web app's API endpoints:

- `POST /api/workouts` - Batch sync multiple workouts
- Sends data in the format:
  ```json
  {
    "workouts": [
      {
        "date": "2024-01-20T10:30:00Z",
        "source": "Peloton",
        "activity": "Cycling",
        "minutes": 30,
        "miles": 8.5,
        "weight": null,
        "calories": 250
      }
    ]
  }
  ```

## Troubleshooting

### No workouts showing?
- Ensure your fitness apps are syncing to Apple Health
- Check HealthKit permissions in Settings > Privacy > Health
- Complete a workout and wait for it to sync to Health

### Sync failing?
- Verify your web app is deployed and accessible
- Check the API URL in `WorkoutService.swift`
- Ensure you have internet connectivity

### Weight data missing?
- Not all apps provide weight data to HealthKit
- Tonal should include weight data automatically
- Manual gym workouts may need weight entered in the source app

## Privacy

- All data stays between your device and your personal web app
- No third-party services involved
- HealthKit data is only read, never modified
- Sync history stored locally on device

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT

---

**Ready to sync your workouts? Build and run the app, then complete a workout to see the magic happen!** ✨