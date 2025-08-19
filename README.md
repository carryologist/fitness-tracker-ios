# Fitness Tracker iOS App

🏋️‍♂️ **Native iOS companion app for the Fitness Tracker web application**

This iOS app automatically syncs your Peloton and Tonal workouts from Apple Health to your fitness tracker web app, giving you seamless cross-device access to your workout data.

## ✨ Features

- 📱 **Native iOS app** with SwiftUI interface
- 🍎 **Apple Health integration** - reads workout data from HealthKit
- 🔄 **Automatic sync** with your web app database
- 🚴‍♂️ **Peloton support** - cycling, running, strength, yoga, etc.
- 💪 **Tonal support** - strength training workouts
- 📊 **Rich workout data** - heart rate, calories, distance, duration
- 🎯 **Cross-device editing** - create goals on web, view on mobile

## 🚀 Quick Start

### Prerequisites

- **Mac computer** (required for iOS development)
- **Xcode 15.0+** (free from Mac App Store)
- **iPhone** running iOS 17.0+ (for testing with real HealthKit data)
- **Apple ID** (free developer account)
- **Peloton and/or Tonal** workouts syncing to Apple Health

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/carryologist/fitness-tracker-ios.git
   cd fitness-tracker-ios
   ```

2. **Open in Xcode:**
   ```bash
   open FitnessTracker.xcodeproj
   ```

3. **Configure your Apple ID:**
   - In Xcode, go to **Preferences** → **Accounts**
   - Add your Apple ID if not already added
   - Select your development team

4. **Update Bundle Identifier:**
   - Select the **FitnessTracker** project in Xcode
   - Go to **Signing & Capabilities**
   - Change the Bundle Identifier to something unique (e.g., `com.yourname.FitnessTracker`)

5. **Connect your iPhone:**
   - Connect your iPhone to your Mac via USB
   - Trust the computer on your iPhone if prompted
   - Select your iPhone as the build destination in Xcode

6. **Build and Run:**
   - Press **⌘+R** or click the **Play** button in Xcode
   - The app will install and launch on your iPhone

7. **Trust the Developer:**
   - On your iPhone, go to **Settings** → **General** → **VPN & Device Management**
   - Find your Apple ID under "Developer App"
   - Tap **Trust** and confirm

8. **Grant HealthKit Permissions:**
   - Open the app on your iPhone
   - Tap **Allow** when prompted for Apple Health access
   - Enable the workout data types you want to sync

## 📱 How It Works

### Data Flow
```
Peloton/Tonal Workout → Apple Health → iOS App → Web App Database → Web App
```

### Sync Process
1. **Complete a workout** on Peloton or Tonal
2. **Workout automatically syncs** to Apple Health
3. **Open the iOS app** and tap "Sync Workouts"
4. **App reads workout data** from HealthKit
5. **Data syncs to your web app** database
6. **View and edit** on any device (web, mobile)

## 🛠️ Configuration

### API Endpoint
The app is configured to sync with your deployed web app. Update the API endpoint in `WorkoutService.swift`:

```swift
private let baseURL = "https://your-fitness-tracker-url.vercel.app"
```

### Supported Workout Types
- 🚴‍♂️ **Cycling** (Peloton Bike/Bike+)
- 🏃‍♂️ **Running** (Peloton Tread)
- 💪 **Strength Training** (Tonal, Peloton)
- 🧘‍♀️ **Yoga** (Peloton)
- 🚣‍♂️ **Rowing** (Peloton Row)
- 🏊‍♂️ **Swimming** (Apple Watch)
- 🥾 **Hiking** (Apple Watch)
- And more...

## 📊 Data Synced

### From Apple Health:
- **Workout Type** (cycling, running, strength, etc.)
- **Duration** (minutes)
- **Calories Burned**
- **Distance** (for cardio workouts)
- **Heart Rate** (average/max)
- **Source App** (Peloton, Tonal, etc.)
- **Date & Time**

### To Web App:
- All workout data formatted for your existing database
- Automatic deduplication (won't create duplicates)
- Seamless integration with your web app's goal tracking

## 🔧 Development

### Project Structure
```
FitnessTracker/
├── FitnessTrackerApp.swift    # Main app entry point
├── ContentView.swift          # Main UI with workout list
├── Models/
│   └── Workout.swift          # Workout data model
├── Services/
│   ├── HealthKitManager.swift # HealthKit integration
│   └── WorkoutService.swift   # API sync service
└── Assets.xcassets           # App icons and colors
```

### Key Components

- **HealthKitManager**: Handles Apple Health permissions and data reading
- **WorkoutService**: Syncs workout data with your web app API
- **Workout Model**: Converts between HealthKit and your web app format
- **ContentView**: Main UI with workout list and sync functionality

## 🐛 Troubleshooting

### Common Issues

**"No workouts found"**
- Ensure Peloton/Tonal apps are syncing to Apple Health
- Check Apple Health permissions in iOS Settings
- Complete a test workout and wait a few minutes

**"Apple Health Access Needed"**
- Tap the message and grant permissions
- Go to iOS Settings → Privacy & Security → Health → FitnessTracker
- Enable all workout-related permissions

**Sync failures**
- Check your internet connection
- Verify the API endpoint URL in `WorkoutService.swift`
- Ensure your web app is deployed and accessible

**Build errors in Xcode**
- Update to latest Xcode version
- Clean build folder (Product → Clean Build Folder)
- Check Bundle Identifier is unique
- Verify Apple ID is signed in

## 🔮 Future Features

- 📱 **Apple Watch companion app**
- 🔔 **Push notifications** for workout sync
- 📈 **Native charts** and analytics
- ⚡ **Background sync** (automatic)
- 🎯 **Quick goal creation** on mobile
- 📱 **Today widget** with stats

## 🤝 Contributing

This is a companion app for the main fitness tracker web application. For issues or feature requests, please coordinate with the web app development.

## 📄 License

Same license as the main fitness tracker project.

---

**Ready to sync your workouts? Build and run the app, then complete a Peloton or Tonal workout to see the magic happen!** ✨