# macOS Vaktija Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native macOS Vaktija menu bar app, WidgetKit widgets, shared cache, AlAdhan 14.6° data source, and optional local notifications.

**Architecture:** Keep prayer-time logic in a testable Swift package first, then wire it into a SwiftUI macOS app and WidgetKit extension. The app owns fetching, cache refresh, menu bar UI, settings, and notification scheduling; widgets read shared cached data from the App Group container.

**Tech Stack:** Swift 6.2, SwiftUI, WidgetKit, UserNotifications, XCTest, URLSession, Codable, Xcode 26.2.

---

## File Structure

- `Package.swift`: Swift package for `VaktijaCore` and core tests.
- `Sources/VaktijaCore/PrayerEvent.swift`: canonical prayer event names and countdown inclusion rules.
- `Sources/VaktijaCore/AlAdhanModels.swift`: Codable response models for AlAdhan monthly calendar API.
- `Sources/VaktijaCore/PrayerDay.swift`: normalized daily prayer data.
- `Sources/VaktijaCore/PrayerScheduleMapper.swift`: maps AlAdhan responses into `PrayerDay`.
- `Sources/VaktijaCore/CountdownEngine.swift`: computes next countdown target.
- `Sources/VaktijaCore/CountdownFormatter.swift`: formats full and compact countdowns.
- `Sources/VaktijaCore/PrayerCache.swift`: reads/writes monthly cache JSON.
- `Sources/VaktijaCore/AlAdhanClient.swift`: fetches monthly calendar data.
- `Sources/VaktijaCore/CacheWarmer.swift`: fetches current month first, then warms current year and next December year.
- `Sources/VaktijaCore/NotificationScheduleBuilder.swift`: produces reminder and exact-time notification requests for a 14-day window.
- `Tests/VaktijaCoreTests/*Tests.swift`: core unit tests.
- `VaktijaMac/VaktijaMacApp.swift`: SwiftUI app entry and `MenuBarExtra`.
- `VaktijaMac/MenuBarContentView.swift`: popover content.
- `VaktijaMac/SettingsView.swift`: menu bar display and notification settings.
- `VaktijaMac/AppState.swift`: app state, timer updates, cache refresh, settings persistence.
- `VaktijaMac/NotificationScheduler.swift`: `UserNotifications` integration.
- `VaktijaWidgets/VaktijaWidgetBundle.swift`: WidgetKit bundle.
- `VaktijaWidgets/VaktijaWidgetProvider.swift`: widget timeline provider.
- `VaktijaWidgets/VaktijaWidgetViews.swift`: small, medium, and large widget views.
- `Vaktija.xcodeproj`: Xcode project containing the macOS app target, widget extension target, and the local `VaktijaCore` package.

## Task 1: Create Core Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/VaktijaCore/PrayerEvent.swift`
- Test: `Tests/VaktijaCoreTests/PrayerEventTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import VaktijaCore

final class PrayerEventTests: XCTestCase {
    func testCountdownEventsIncludeSunriseAndExcludeNightInfo() {
        XCTAssertEqual(
            PrayerEvent.countdownEvents,
            [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        )
        XCTAssertFalse(PrayerEvent.countdownEvents.contains(.midnight))
        XCTAssertFalse(PrayerEvent.countdownEvents.contains(.lastThird))
    }
}
```

- [ ] **Step 2: Add package and minimal implementation**

```swift
// Package.swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Vaktija",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "VaktijaCore", targets: ["VaktijaCore"])
    ],
    targets: [
        .target(name: "VaktijaCore"),
        .testTarget(name: "VaktijaCoreTests", dependencies: ["VaktijaCore"])
    ]
)
```

```swift
// Sources/VaktijaCore/PrayerEvent.swift
import Foundation

public enum PrayerEvent: String, Codable, CaseIterable, Sendable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"
    case midnight = "Pola noći"
    case lastThird = "Zadnja trećina"

    public static let countdownEvents: [PrayerEvent] = [
        .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha
    ]
}
```

- [ ] **Step 3: Run test**

Run: `swift test --filter PrayerEventTests`

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "feat: add vaktija core package"
```

## Task 2: Parse and Normalize AlAdhan Monthly Data

**Files:**
- Create: `Sources/VaktijaCore/AlAdhanModels.swift`
- Create: `Sources/VaktijaCore/PrayerDay.swift`
- Create: `Sources/VaktijaCore/PrayerScheduleMapper.swift`
- Test: `Tests/VaktijaCoreTests/PrayerScheduleMapperTests.swift`

- [ ] **Step 1: Write tests using a fixture with May 29, 2026 Sarajevo data**

The test must assert that `Fajr=03:27`, `Sunrise=05:09`, `Dhuhr=12:44`, `Asr=16:48`, `Maghrib=20:19`, `Isha=22:01`, `Midnight=00:44`, and `Lastthird=02:12` map into one `PrayerDay`.

- [ ] **Step 2: Implement Codable models**

Create models for `AlAdhanCalendarResponse`, `AlAdhanDay`, `AlAdhanTimings`, `AlAdhanDate`, and `AlAdhanGregorianDate`. Strip timezone suffixes such as ` (CEST)` while mapping.

- [ ] **Step 3: Implement normalized model**

`PrayerDay` should store `date`, `locationName`, `timeZoneIdentifier`, and `[PrayerTime]`, where `PrayerTime` contains `event: PrayerEvent` and `time: DateComponents`.

- [ ] **Step 4: Run mapper tests**

Run: `swift test --filter PrayerScheduleMapperTests`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/VaktijaCore Tests/VaktijaCoreTests
git commit -m "feat: map aladhan calendar data"
```

## Task 3: Countdown and Formatting

**Files:**
- Create: `Sources/VaktijaCore/CountdownEngine.swift`
- Create: `Sources/VaktijaCore/CountdownFormatter.swift`
- Test: `Tests/VaktijaCoreTests/CountdownEngineTests.swift`
- Test: `Tests/VaktijaCoreTests/CountdownFormatterTests.swift`

- [ ] **Step 1: Test next target before Sunrise**

Use a `PrayerDay` for May 29, 2026 and `now=2026-05-29 04:00 Europe/Sarajevo`. Assert next target is `Sunrise` at `05:09`.

- [ ] **Step 2: Test next-day rollover after Isha**

Use May 29 and May 30 cached days and `now=2026-05-29 22:30 Europe/Sarajevo`. Assert next target is May 30 `Fajr`.

- [ ] **Step 3: Test exclusion of Midnight and Last Third**

Use `now=2026-05-29 23:00 Europe/Sarajevo`. Assert the next target is not `Midnight` or `Last Third`.

- [ ] **Step 4: Implement countdown engine**

Expose `CountdownEngine.nextTarget(now:days:calendar:) -> CountdownTarget?`.

- [ ] **Step 5: Implement formatter**

Expose `CountdownFormatter.full(duration:) -> "HH:mm:ss"` and `CountdownFormatter.compact(event:duration:) -> "Asr 43m"` style strings.

- [ ] **Step 6: Run tests**

Run: `swift test --filter Countdown`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/VaktijaCore Tests/VaktijaCoreTests
git commit -m "feat: add countdown logic"
```

## Task 4: Cache, Fetching, and Year Warming

**Files:**
- Create: `Sources/VaktijaCore/PrayerCache.swift`
- Create: `Sources/VaktijaCore/AlAdhanClient.swift`
- Create: `Sources/VaktijaCore/CacheWarmer.swift`
- Test: `Tests/VaktijaCoreTests/PrayerCacheTests.swift`
- Test: `Tests/VaktijaCoreTests/CacheWarmerTests.swift`

- [ ] **Step 1: Test cache round trip**

Write a test that saves a month for Sarajevo `2026-05`, reads it back, and asserts all days and events are preserved.

- [ ] **Step 2: Implement file cache**

Store JSON files under a caller-provided base directory using path shape `locations/sarajevo/2026/05.json`.

- [ ] **Step 3: Test cache warmer order**

Use a fake `AlAdhanClient` and assert the warmer fetches current month first, then remaining months for the year. For a December date, assert it also requests the next year.

- [ ] **Step 4: Implement client and warmer**

Use URLSession for live client. Keep `CacheWarmer` dependent on a protocol so tests use a fake.

- [ ] **Step 5: Run tests**

Run: `swift test --filter Cache`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/VaktijaCore Tests/VaktijaCoreTests
git commit -m "feat: add prayer cache and fetcher"
```

## Task 5: Notification Schedule Builder

**Files:**
- Create: `Sources/VaktijaCore/NotificationScheduleBuilder.swift`
- Test: `Tests/VaktijaCoreTests/NotificationScheduleBuilderTests.swift`

- [ ] **Step 1: Test reminder and exact-time schedule**

For Asr at `16:45` and offset `45 minutes`, assert generated fire dates include `16:00` and `16:45`.

- [ ] **Step 2: Test past dates are skipped**

Use `now=16:30`, Asr at `16:45`, offset `45 minutes`. Assert `16:00` reminder is skipped and `16:45` exact-time remains.

- [ ] **Step 3: Test Midnight and Last Third are excluded**

Assert no schedule entries are generated for `.midnight` or `.lastThird`.

- [ ] **Step 4: Implement builder**

Expose `NotificationScheduleBuilder.entries(now:days:reminderOffset:windowDays:) -> [NotificationScheduleEntry]`, defaulting `windowDays` to `14`.

- [ ] **Step 5: Run tests**

Run: `swift test --filter NotificationScheduleBuilderTests`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/VaktijaCore Tests/VaktijaCoreTests
git commit -m "feat: build notification schedules"
```

## Task 6: Create macOS App and Widget Targets

**Files:**
- Create: `Vaktija.xcodeproj`
- Create: `VaktijaMac/VaktijaMacApp.swift`
- Create: `VaktijaMac/AppState.swift`
- Create: `VaktijaMac/MenuBarContentView.swift`
- Create: `VaktijaMac/SettingsView.swift`
- Create: `VaktijaWidgets/VaktijaWidgetBundle.swift`
- Create: `VaktijaWidgets/VaktijaWidgetProvider.swift`
- Create: `VaktijaWidgets/VaktijaWidgetViews.swift`

- [ ] **Step 1: Create Xcode project**

Create a macOS SwiftUI app target named `VaktijaMac` and a Widget Extension target named `VaktijaWidgets`. Add the local package product `VaktijaCore` to both targets.

- [ ] **Step 2: Configure capabilities**

Enable App Groups for both targets using a local development group such as `group.com.abdulahproho.vaktija`. Enable outgoing network access for the app target if sandboxing is enabled.

- [ ] **Step 3: Add minimal `MenuBarExtra` app**

Implement `VaktijaMacApp` with a `MenuBarExtra` that initially shows an icon-only fallback and opens `MenuBarContentView`.

- [ ] **Step 4: Add widget skeletons**

Implement small, medium, and large widget families with a fixed preview entry for `Asr 16:45`, then wire provider reads to cached data in later steps.

- [ ] **Step 5: Build**

Run: `xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add Vaktija.xcodeproj VaktijaMac VaktijaWidgets
git commit -m "feat: add macos app and widgets"
```

## Task 7: Wire App State, Menu Bar UI, and Settings

**Files:**
- Modify: `VaktijaMac/AppState.swift`
- Modify: `VaktijaMac/MenuBarContentView.swift`
- Modify: `VaktijaMac/SettingsView.swift`

- [ ] **Step 1: Add app settings model**

Store menu bar display mode, notifications enabled, reminder offset, and permission status in `UserDefaults`.

- [ ] **Step 2: Wire cache loading**

On launch, load cached current day if present, fetch current month if missing, and start year warming in the background.

- [ ] **Step 3: Wire live countdown**

Use a one-second timer in the app target to update full menu bar countdown text.

- [ ] **Step 4: Build popover**

Show next target, live countdown, daily list, Midnight, Last Third, source, cache status, and settings controls.

- [ ] **Step 5: Build**

Run: `xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add VaktijaMac
git commit -m "feat: wire menu bar prayer UI"
```

## Task 8: Wire Local Notifications

**Files:**
- Create: `VaktijaMac/NotificationScheduler.swift`
- Modify: `VaktijaMac/AppState.swift`
- Modify: `VaktijaMac/SettingsView.swift`

- [ ] **Step 1: Implement permission request**

When the user enables notifications, call `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])`.

- [ ] **Step 2: Implement scheduler**

Use `NotificationScheduleBuilder` to schedule the next 14 days. Remove existing app-created pending requests before re-scheduling.

- [ ] **Step 3: Trigger re-scheduling**

Re-schedule on app launch, settings change, cache change, and date rollover.

- [ ] **Step 4: Manual test with short offset**

Temporarily set offset to one minute, use a nearby fixture or current schedule, and verify reminder plus exact-time notifications appear.

- [ ] **Step 5: Build**

Run: `xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add VaktijaMac
git commit -m "feat: add prayer notifications"
```

## Task 9: Wire Widget Timeline to Shared Cache

**Files:**
- Modify: `VaktijaWidgets/VaktijaWidgetProvider.swift`
- Modify: `VaktijaWidgets/VaktijaWidgetViews.swift`
- Modify: `Sources/VaktijaCore/PrayerCache.swift`

- [ ] **Step 1: Read cache from App Group**

Expose a cache initializer that accepts an App Group identifier and resolves the shared container URL.

- [ ] **Step 2: Build timeline entries**

Widget provider reads today's and tomorrow's cached days, computes the next target, and sets timeline reload around the next target and after midnight.

- [ ] **Step 3: Render family-specific views**

Small renders next target and relative countdown. Medium renders next target and daily list. Large renders daily list plus Midnight and Last Third.

- [ ] **Step 4: Build**

Run: `xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add VaktijaWidgets Sources/VaktijaCore
git commit -m "feat: wire widgets to prayer cache"
```

## Task 10: Final Verification

**Files:**
- Modify: files identified by failed tests, failed builds, or manual verification defects.

- [ ] **Step 1: Run package tests**

Run: `swift test`

Expected: all tests PASS.

- [ ] **Step 2: Build app**

Run: `xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual app checks**

Launch from Xcode and verify icon-only, full countdown, compact countdown, popover daily list, Midnight/Last Third display, cache refresh, and notification settings.

- [ ] **Step 4: Manual widget checks**

Add small, medium, and large widgets in macOS and verify all render from cached data.

- [ ] **Step 5: Commit final fixes**

```bash
git add .
git commit -m "chore: finalize macos vaktija verification"
```

## Self-Review

- Spec coverage: the plan covers AlAdhan 14.6° monthly fetch, shared cache, menu bar countdown, popover, widgets, notification settings, 14-day rolling schedules, and tests.
- Red-flag scan: no `TODO` or `TBD` entries are present.
- Type consistency: core names use `PrayerEvent`, `PrayerDay`, `PrayerTime`, `CountdownEngine`, and `NotificationScheduleBuilder` consistently across tasks.
