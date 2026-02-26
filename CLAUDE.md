# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Meridian is a native iOS SwiftUI app that combines habit-building with journaling. It uses iOS FamilyControls/ScreenTime APIs to block selected apps during scheduled morning and night sessions, encouraging users to journal before accessing blocked apps.

## Build Commands

```bash
# Open in Xcode
open Meridian.xcodeproj

# Command line build
xcodebuild -scheme Meridian -destination generic/platform=iOS

# Build for simulator
xcodebuild -scheme Meridian -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Requirements:** Xcode 16.0+, iOS 16.0+ target. Device recommended for Screen Time testing (simulator has limited FamilyControls support).

## Architecture

**Pattern:** MVVM + Services Layer with singleton services

```
Views (SwiftUI) → ViewModels (ObservableObject) → Services (Singletons) → Models/CoreData
```

### Key Services

- **LockStateManager** - Central state machine managing app lock states (`unlocked`, `morningLocked`, `nightSoftLocked`, `nightGracePeriod`, `nightHardLocked`). Coordinates with ScreenTimeService to apply/remove app shields.
- **SettingsService** - UserDefaults wrapper with @Published properties for all app settings and onboarding state.
- **ScreenTimeService** - Wraps FamilyControls API for app selection and applying/removing shields via ManagedSettings.
- **SchedulingService** - Schedules BGAppRefreshTask for morning/night locks and local notifications.
- **CoreDataService** - CRUD operations for JournalEntry entity.
- **CoreDataStack** - NSPersistentContainer setup with background context support.

### Navigation Flow

1. **Not onboarded** → OnboardingContainerView (6-step wizard: Welcome → Permission → App Selection → Morning Config → Night Config → Ready)
2. **Currently locked** → JournalEntryView (forced entry before unlock)
3. **Unlocked** → NightSkyView (home screen showing entries as stars)

### Core Data Model

Single entity `JournalEntry` with fields: id, type (morning/night/anytime), content, timestamp, entryMode (digital/physical), photoLocalPath, starPositionX/Y, morningReferenceID.

## Lock State Machine

```
unlocked ←→ morningLocked (entry unlocks)
         ←→ nightSoftLocked → nightGracePeriod (15 min) → nightHardLocked
```

- Morning lock: soft lock, submit entry to unlock
- Night lock: soft lock → grace period after entry → hard lock (sanctuary mode)
- State persists across app termination via UserDefaults

## Directory Structure

- `Meridian/App/` - App entry point, notification delegate
- `Meridian/Models/` - Enums (LockState, SessionType, DayOfWeek, MorningEntryMode)
- `Meridian/Services/` - Singleton services (all use `static let shared`)
- `Meridian/ViewModels/` - ObservableObject view models
- `Meridian/Views/` - SwiftUI views organized by feature (Journal, NightSky, Onboarding, Search, Settings)
- `Meridian/Utilities/` - Theme constants, extensions, validators

## Design System

Use `Theme` enum for consistent spacing, fonts, colors, and animations. Color palette defined in `Color+Theme.swift` extension.
