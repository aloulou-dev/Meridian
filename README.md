# Meridian

Meridian is a native iOS app that combines habit-building with reflective journaling, inspired by the Jesuit tradition of the Daily Examen. It uses Apple's Screen Time APIs to block distracting apps during scheduled morning and night sessions, guiding users to journal before regaining access.

## How It Works

### Morning Flow

1. At a user-configured wake-up time, selected apps are blocked and a notification is sent.
2. The user opens Meridian and is presented with an AI-generated examen-inspired prompt focused on gratitude, intention, and readiness for the day.
3. They choose to write digitally or photograph a handwritten entry (OCR via GPT-4o extracts the text).
4. After submitting, the entry becomes a star in the night-sky visualization and apps are unlocked.

### Night Flow

1. At a user-set wind-down time, distracting apps enter a "Soft Lock."
2. The user opens Meridian and answers an AI-generated reflective prompt following the classic examen arc (presence, gratitude, replay, consolation/desolation, forgiveness, resolution).
3. After submitting, the entry grants a 15-minute Grace Period.
4. When the grace period expires, apps enter "Hard Lock" (Sanctuary Mode) for the night.

### Anytime Journaling

Users can write additional reflections from the home screen at any time without triggering locks.

## Architecture

**Pattern:** MVVM + Services Layer

```
Views (SwiftUI) --> ViewModels (ObservableObject) --> Services (Singletons) --> CoreData / UserDefaults
```

### Directory Structure

```
Meridian/
├── App/                    # App entry point, notification delegate
├── Models/                 # LockState, SessionType, DayOfWeek, MorningEntryMode
├── Services/
│   ├── LockStateManager    # Central state machine for lock phases
│   ├── ScreenTimeService   # FamilyControls / ManagedSettings shields
│   ├── SchedulingService   # BGAppRefreshTask + local notifications
│   ├── SettingsService     # UserDefaults wrapper (@Published)
│   ├── CoreDataService     # JournalEntry CRUD
│   ├── AIQuestionService   # OpenAI chat completions + vision OCR
│   ├── QuestionGenerationService  # AI vs fallback orchestrator
│   ├── PromptCoachService  # Deterministic fallback prompts
│   └── AppSecrets          # Dev-only API key loading
├── ViewModels/             # ObservableObject VMs per screen
├── Views/
│   ├── Journal/            # Entry screen + camera capture
│   ├── NightSky/
│   │   ├── Scene/          # SceneKit 3D: NightSkySceneView, NightSkySceneBuilder, CelestialSpriteGenerator
│   │   └── Canvas/         # Legacy 2D renderer (not active)
│   ├── Onboarding/         # 6-step setup wizard
│   ├── Settings/           # App configuration
│   ├── Search/             # Entry search
│   └── Components/         # Reusable UI (CyclePhaseIndicator)
└── Utilities/              # Theme, Color extensions, View modifiers

MeridianShieldAction/       # DeviceActivityMonitor extension (background app blocking)
MeridianShieldConfig/       # ShieldConfiguration extension (blocked-app UI)
```

### Lock State Machine

```
unlocked <--> morningLocked (journal entry unlocks)
         <--> nightSoftLocked --> nightGracePeriod (15 min) --> nightHardLocked
```

A cycle phase indicator pill is shown on every screen so the user always knows where they are in the daily rhythm.

### Night Sky Visualization

The home screen renders journal entries as a 3D star field using SceneKit:

- Each day's entries become a single glowing star; star size and color temperature reflect the session type and content
- A background star sphere (150 procedural stars) surrounds the scene
- Two procedural galaxy sprites (a 2-arm logarithmic spiral and an edge-on disk) float as faint distant objects on billboard planes
- Constellation lines connect stars written in the same calendar week
- The camera auto-drifts forward; pan gesture orbits, pinch gesture dollies (clamped to prevent pixelation)
- A compass tape overlay shows the current camera heading

## Requirements

- Xcode 16.0+
- iOS 16.0+ deployment target
- Physical device recommended (FamilyControls / Screen Time APIs have limited simulator support)

## Setup

1. Clone the repository and open `Meridian.xcodeproj`.
2. Create `Meridian/Secrets.plist` with your OpenAI API key:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OPENAI_API_KEY</key>
    <string>sk-your-key-here</string>
</dict>
</plist>
```

This file is git-ignored and will not be committed. If the key is missing, the app falls back to local deterministic prompts automatically.

3. Build and run on a device (or simulator for non-Screen-Time features).

```bash
# Command-line build for simulator
xcodebuild -scheme Meridian -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Design System

All spacing, typography, colors, and animations are defined in the `Theme` enum. The color palette lives in `Color+Theme.swift`. The app uses a dark night-sky aesthetic throughout.

## Development

Debug builds automatically seed ~30 sample journal entries across 20 unique days on first launch when the Core Data store is empty. These entries span the last 30 days with a mix of morning, night, and anytime sessions, so the NightSky home screen is populated with 20 stars (one per day) for visual testing. The seed data is gated behind `#if DEBUG` and will not run in release builds. To re-seed, delete the app from the simulator to clear Core Data.

## Key Technologies

- **SwiftUI** -- All UI
- **FamilyControls / ManagedSettings** -- App blocking via Screen Time
- **DeviceActivity** -- Background scheduled shield application (works even when app is closed)
- **SceneKit** -- 3D night-sky scene with emissive star geometry, procedural galaxy billboard sprites, pan/pinch camera control, and atmospheric auto-drift
- **AVFoundation** -- Camera capture for photographing handwritten journal entries
- **OpenAI API** -- AI-generated examen prompts (GPT-4.1-mini) and handwriting OCR (GPT-4o vision)
- **Core Data** -- Journal entry persistence
- **BackgroundTasks** -- BGAppRefreshTask for lock scheduling
- **UserNotifications** -- Morning/night session reminders
