# Vaktija

Vaktija is a native macOS menu bar app and WidgetKit extension for Sarajevo prayer times. It shows the next salah countdown in the menu bar, daily prayer times in a popover, and small/medium/large desktop widgets.

The app is built for personal macOS use and currently targets Sarajevo using AlAdhan calendar data with a 14.6 degree calculation method.

## Features

- Menu bar countdown with three display modes:
  - Full countdown, for example `Ikindija: 00:43:33`
  - Compact countdown
  - Icon only
- Menu popover with:
  - Next salah and live `HH:MM:SS` countdown
  - Daily prayer times: Sabah, Izlazak, Podne/Džuma, Ikindija, Akšam, Jacija
  - Night info: Pola noći and Zadnja trećina
  - Cache status and cache health
  - Notification settings
  - Launch at Login toggle
  - Quit button
- WidgetKit widgets:
  - Small widget: next salah, relative countdown, and exact time
  - Medium widget: next salah row plus daily prayer times
  - Large widget: next salah row, daily prayer times, and night info
- Notifications:
  - Per-prayer enable/disable checkboxes
  - Per-prayer reminder offset
  - Reminder notification before salah
  - Exact-time notification at salah start
- Global keyboard shortcut:
  - `Command + Option + P` toggles the menu popover
- Offline-friendly cache:
  - Loads cached data first
  - Fetches missing or invalid visible months
  - Warms the cache in the background
  - Shares cached data with widgets through the app group
- Friday label:
  - Dhuhr displays as `Džuma` on Fridays

## Data Source

Prayer times come from the AlAdhan calendar API:

- Endpoint: `https://api.aladhan.com/v1/calendar/{year}/{month}`
- Location: Sarajevo
- Coordinates: `43.84864, 18.35644`
- Time zone: `Europe/Sarajevo`
- Method settings: `14.6,null,14.6`

The app includes sunrise in the countdown sequence. Midnight and last third are displayed as extra night information, but they are not included as countdown targets or notification targets.

## Requirements

- macOS 15 or newer
- Xcode with Swift 6 support
- XcodeGen, if regenerating `Vaktija.xcodeproj` from `project.yml`
- Apple signing team configured in Xcode for local builds

## Install From DMG

A packaged build is generated in `dist/`:

```sh
open dist/VaktijaMac-0.1.0.dmg
```

Drag `VaktijaMac.app` onto `Applications`.

This local package is signed with an Apple Development certificate, not Developer ID notarization. On another Mac, Gatekeeper may require right-click `Open`, or, for a trusted personal build:

```sh
xattr -dr com.apple.quarantine /Applications/VaktijaMac.app
```

For public distribution, the app should be signed with a Developer ID certificate and notarized.

## Build And Test

Run tests:

```sh
xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -destination 'platform=macOS' test
```

Build a Release app:

```sh
xcodebuild -project Vaktija.xcodeproj -scheme VaktijaMac -configuration Release -destination 'platform=macOS' -allowProvisioningUpdates build
```

## Package

Create a ZIP and drag-install DMG from the Release build:

```sh
APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Release/VaktijaMac.app" -type d -print -quit)

rm -rf dist
mkdir -p dist/stage
ditto "$APP_PATH" "dist/stage/VaktijaMac.app"
ln -s /Applications "dist/stage/Applications"
ditto -c -k --keepParent "dist/stage/VaktijaMac.app" "dist/VaktijaMac-0.1.0.zip"
hdiutil create -volname "Vaktija" -srcfolder "dist/stage" -ov -format UDZO "dist/VaktijaMac-0.1.0.dmg"
```

If `APP_PATH` is empty, run the Release build first.

## Project Structure

- `Sources/VaktijaCore`: shared data fetching, mapping, cache, countdown, and notification scheduling logic
- `VaktijaMac`: menu bar app, popover UI, settings, login item support, notifications, and hotkey handling
- `VaktijaWidgets`: WidgetKit provider and widget layouts
- `Tests/VaktijaCoreTests`: unit tests for cache, countdown, mapping, labels, and notification scheduling
- `project.yml`: XcodeGen project definition

## Notes

- The app runs as a menu bar accessory app (`LSUIElement`) and does not show a Dock icon.
- Widgets read from the shared cache. Open the app once so it can fetch and cache prayer times before expecting widgets to show live data.
- Widget refresh frequency is controlled by WidgetKit. The displayed timer can count down live, but full timeline reloads are scheduled by the system.
