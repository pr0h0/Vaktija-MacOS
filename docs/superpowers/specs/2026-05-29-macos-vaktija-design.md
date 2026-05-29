# macOS Vaktija Design

## Goal

Build a native macOS app for Sarajevo prayer times using the 14.6 degree calculation method. The app provides an always-visible menu bar countdown, a click-to-open daily-times popover, and WidgetKit widgets for glanceable prayer time status.

## Scope

The first version targets macOS only and uses Swift and SwiftUI. It includes:

- A menu bar app.
- A popover with daily times.
- Small, medium, and large widgets.
- Local caching shared by the app and widget extension.
- Sarajevo as the default and initial location.

The first version does not include Windows, Linux, Electron, Tauri, adhan audio, notifications, or automatic location detection.

## Data Source

Prayer times come from AlAdhan's monthly calendar endpoint with a custom calculation method:

```text
https://api.aladhan.com/v1/calendar/{year}/{month}?latitude=43.84864&longitude=18.35644&method=99&methodSettings=14.6,null,14.6&school=0&timezonestring=Europe/Sarajevo
```

The custom method uses:

- Fajr angle: `14.6`
- Maghrib setting: `null`
- Isha angle: `14.6`
- Asr school: `school=0`
- Time zone: `Europe/Sarajevo`

The app stores the source label as `AlAdhan 14.6°`.

## Cached Data

The app caches monthly API responses in an App Group container so the menu bar app and widgets can read the same data. On first launch, the app fetches the current month first, then fetches the rest of the current year in the background. When the current date is in December, it also prefetches the next year.

The cache is keyed by location, year, and month. Missing or invalid months are fetched again. Valid cached months are reused so the app does not need daily network access. Widgets must be able to render from cache without starting the main app.

Each cached day stores:

- Gregorian date.
- Location name.
- Time zone.
- Fajr from `Fajr`.
- Sunrise from `Sunrise`.
- Dhuhr from `Dhuhr`.
- Asr from `Asr`.
- Maghrib from `Maghrib`.
- Isha from `Isha`.
- Pola noći from `Midnight`.
- Zadnja trećina from `Lastthird`.

The canonical countdown labels are `Fajr`, `Sunrise`, `Dhuhr`, `Asr`, `Maghrib`, and `Isha`. The UI can later add Bosnian display names, but the first version uses these canonical labels for the menu bar and widgets.

## Countdown Rules

Countdown targets include:

- Fajr
- Sunrise
- Dhuhr
- Asr
- Maghrib
- Isha

Countdown targets exclude:

- Pola noći
- Zadnja trećina

After Isha passes, the next target is tomorrow's Fajr. If tomorrow's cache entry is missing, the app should fetch the needed month if possible and otherwise show the latest known data with an unavailable countdown state.

## Menu Bar App

The app uses `MenuBarExtra` for the menu bar item. The menu bar display mode is user-configurable:

- Icon only.
- Full countdown, for example `Asr: 00:43:33`.
- Compact countdown, for example `Asr 43m`.

Clicking the menu bar item opens a compact SwiftUI popover. The popover shows:

- Current next target.
- Live countdown.
- Today's main time list.
- A secondary section for Pola noći and Zadnja trećina.
- Location.
- Source label.
- Last updated/cache status.
- Settings button.

The app should stay lightweight and launch as a menu bar utility rather than a full desktop window by default.

## Widgets

The app includes a WidgetKit extension with three supported layouts:

- Small widget: next target name, countdown, and exact time.
- Medium widget: next target countdown plus today's main time list.
- Large widget: full daily list plus Pola noći, Zadnja trećina, location, and source/cache status.

Widgets read from the shared App Group cache. Widget timelines should update around each countdown target and after midnight. Because WidgetKit does not support per-second live updates in the same way as the menu bar app, widget countdown text may use compact relative formatting such as `in 45m`.

## Settings

The first settings screen includes:

- Menu bar display mode.
- Location display, initially fixed to Sarajevo.
- Refresh cache action.
- Source/cache status.

Future versions can add location search and saved locations.

## Error Handling

If the network request fails and cached data exists, the app uses the cached data and displays a stale/offline cache state. If no cached data exists, the menu bar item falls back to icon-only and the popover/widget show a clear unavailable state with a refresh option where available.

Parsing errors invalidate only the affected month. They should not delete unrelated cached months.

## Testing

Core logic should be tested independently from SwiftUI views:

- Parse AlAdhan monthly responses.
- Map API timings to canonical countdown labels.
- Compute the next countdown target, including Sunrise and next-day Fajr rollover.
- Exclude Pola noći and Zadnja trećina from countdown targets.
- Format full and compact countdown strings.
- Read and write monthly cache entries.

Manual verification should cover:

- Menu bar icon-only, full countdown, and compact countdown modes.
- Popover layout.
- Widget small, medium, and large layouts.
- Offline behavior using cached data.
