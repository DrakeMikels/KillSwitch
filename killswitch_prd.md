# KillSwitch PRD

## Product
KillSwitch

## Version
v1.0 PRD

## One-line product statement
KillSwitch is a lightweight macOS menu bar utility for seeing memory pressure and quickly quitting heavy apps.

---

# 1. Product Intent

KillSwitch exists to solve a very specific moment:

A user feels their Mac getting sluggish and wants to know, within a few seconds:
1. Is memory pressure actually the problem?
2. Which apps are using the most memory right now?
3. Which app can I gracefully quit first?

KillSwitch is not a “Mac optimizer,” not a system cleaner, and not a dashboard product. It is a small native utility.

The product should feel:
- fast
- quiet
- useful
- native to macOS
- open-source worthy
- narrow in scope and well executed

---

# 2. Goals

## Primary goals
- Live in the macOS menu bar
- Surface current memory state at a glance
- Show total unified memory used and available
- Show the top memory-using user apps
- Let the user gracefully quit an app from the popover
- Provide a very small settings window
- Provide standard app utility actions like updates and about
- Stay lightweight in both UX and runtime cost

## Secondary goals
- Feel polished enough to be a strong public GitHub project
- Be easy for others to clone, run, and understand
- Use native Apple frameworks and straightforward architecture

---

# 3. Non-Goals

KillSwitch v1 must not become a full desktop product.

## Out of scope for v1
- notifications
- auto-cleaning
- automatic recovery actions
- AI recommendations
- memory history charts
- trend analytics
- scanning all processes in a noisy advanced view
- force quit as the primary behavior
- startup manager features
- CPU/network monitoring as first-class surfaces
- rich onboarding
- animated backgrounds
- theme system
- system cleaning claims

If a feature makes KillSwitch feel like a product suite instead of a utility, it should be excluded.

---

# 4. Target User

## Primary users
- Mac users on 8 GB / 16 GB machines who occasionally run into memory pressure
- developers, designers, and general users who keep many apps open
- users who want a faster path than opening Activity Monitor

## User behavior assumptions
- They want quick answers, not diagnostics theater
- They already understand what “quit” means
- They do not want the app itself to become visually or technically heavy

---

# 5. Core Product Principles

## 5.1 Utility first
The popover is the product.

## 5.2 Native over flashy
Use standard macOS patterns wherever possible.

## 5.3 Honest behavior
KillSwitch reports memory usage and offers graceful quit. It does not promise fake optimization.

## 5.4 Small and efficient
The app should open fast, refresh sensibly, and avoid unnecessary background work.

## 5.5 Open-source credibility
The codebase should be clear, focused, and practical.

---

# 6. Core User Stories

## Story 1
As a user, I want to click a menu bar utility and instantly see whether memory pressure is high.

## Story 2
As a user, I want to see which apps are using the most memory without opening Activity Monitor.

## Story 3
As a user, I want to gracefully quit a heavy app and still preserve the app’s normal save prompts.

## Story 4
As a user, I want a simple refresh action if I suspect the list is stale.

## Story 5
As a user, I want basic utility commands such as settings, check for updates, about, and quit app.

---

# 7. Information Architecture

KillSwitch has four surfaces only:

1. **Menu bar icon**
2. **Main popover**
3. **Overflow utility menu**
4. **Mini settings window**

There is also a standard **About KillSwitch** panel.

No other primary windows are needed in v1.

---

# 8. Primary UX Flow

1. User clicks the KillSwitch menu bar icon
2. Popover opens
3. User sees memory summary immediately
4. User scans top memory-heavy apps
5. User clicks `Quit` on an app if desired
6. App terminates gracefully through normal macOS behavior
7. Save prompts remain the responsibility of the target app / system

Secondary path:
- User opens overflow menu via `⋯`
- User can choose:
  - Refresh Now
  - Check for Updates…
  - About KillSwitch
  - Settings…
  - Quit KillSwitch

---

# 9. UI Design Direction

This PRD adopts the latest approved v1 design direction:
- compact menu bar popover
- subtle glass/material treatment only where useful
- mostly neutral surfaces
- restrained color only in memory bars and pressure state
- app-level commands moved into an overflow utility menu
- mini settings window rather than a full preferences app

The visual feel should be:
- native macOS
- light material shell
- crisp typography
- quiet hierarchy
- no dashboard bloat

---

# 10. Detailed UI Specification

## 10.1 Menu Bar Icon

### Behavior
- Always available in the macOS menu bar
- Clicking toggles the main popover

### Design
- monochrome icon
- simple enough to read at small size
- should feel like a native utility icon rather than a brand-heavy logo

---

## 10.2 Main Popover

### Purpose
This is the primary product surface.

### Preferred size
- width: ~344 pt
- height: dynamic based on app rows

### Layout structure
1. Header
2. Summary card
3. Top applications list
4. Footer

### 10.2.1 Header
Contains:
- small app icon
- `KillSwitch` title
- subtitle: `Memory utility`
- `Refresh` button
- `⋯` overflow button

### Header design rules
- lightweight, utility-like
- compact vertical spacing
- slight material treatment is acceptable
- no oversized controls

### 10.2.2 Summary Card
Shows:
- label: `Unified Memory`
- primary value: e.g. `11.4 / 16 GB`
- secondary value: e.g. `4.6 GB available`
- pressure badge: e.g. `High Pressure`
- one main memory progress bar
- small footer labels: `Memory in use` and percentage

### Summary card design rules
- this is the strongest visual block in the popover
- should not feel like a big SaaS analytics card
- use restrained color only for the main memory bar and pressure state

### Pressure states
Supported display states:
- Normal
- Elevated
- High
- Critical

Pressure state should be derived primarily from the OS memory pressure signal rather than a naive used-memory percentage alone.

Used / total memory and percent remain useful secondary display values, but the pressure badge should reflect real system pressure when possible.

Exact underlying thresholds may be tuned during implementation.

### 10.2.3 Top Applications List
Shows the top 5–7 user-relevant apps by memory usage.

#### Section header
- left: `Top Applications`
- right: `By memory`

#### Each row contains
- app name
- memory used (e.g. `3.2 GB`)
- percent of total memory (e.g. `20% total`)
- small usage meter
- `Quit` button

#### Row behavior
- pressing `Quit` requests graceful termination for that app
- the list refreshes after termination or next refresh cycle

#### Row styling
- compact rows
- minimal visual separators
- readable typography
- buttons should look like real native controls, not text links

### Per-app meter color behavior
- heavy usage: warm gradient (orange/amber)
- medium usage: cool gradient (blue/cyan)
- light usage: green/teal gradient

This color is purely for scan speed and relative severity.

### 10.2.4 Footer
Contains:
- small status line: `Graceful quit keeps save prompts`
- `Settings` shortcut

Footer should be low emphasis.

---

## 10.3 Overflow Utility Menu

### Trigger
Opened from the `⋯` button in the popover header.

### Purpose
Holds app-level commands that do not belong in the main content area.

### Items
In order:
1. `Refresh Now`
2. `Check for Updates…`
3. `About KillSwitch`
4. `Settings…`
5. `Quit KillSwitch`

### Design
- compact native-style floating utility menu
- anchored visually to the header action area
- not large, not decorative
- should feel like a standard menu bar utility command sheet

### Behavior
- `Refresh Now` triggers an immediate refresh
- `Check for Updates…` checks for a newer build
- `About KillSwitch` opens the standard about panel
- `Settings…` opens the mini settings window
- `Quit KillSwitch` quits the app itself

---

## 10.4 Mini Settings Window

### Purpose
A tiny preferences surface, intentionally limited.

### Preferred size
- width: ~420 pt
- height: based on content, roughly 430–500 pt

### Window structure
1. Title bar / standard macOS chrome
2. General settings group
3. Display settings group
4. Footer actions

### 10.4.1 General group
Includes:
- Launch at login
- Show Dock icon
- Show app icons

### 10.4.2 Display group
Includes:
- Sort apps by
- Refresh interval

### 10.4.3 Footer actions
- `Restore Defaults`
- `Done`

### Settings design rules
- should feel intentionally small
- grouped rows
- standard toggles and value controls
- no sidebar
- no tabs
- no advanced sections in v1

---

## 10.5 About KillSwitch

### Behavior
- opens a standard macOS About panel
- no custom marketing window needed in v1

### Suggested contents
- app name
- app icon
- version
- short one-line description
- copyright / attribution
- source repository link if desired

---

# 11. Visual System

## 11.1 Overall look
- neutral shell
- light material in small doses
- mostly opaque readable surfaces
- clean contrast
- tiny gradients only where they improve signal

## 11.2 Material usage
Allowed:
- header shell
- footer shell
- subtle card background treatment

Avoid:
- heavy glass everywhere
- layered translucent chaos
- decorative visual effects that add no function

## 11.3 Typography
- strong, compact hierarchy
- no oversized marketing type
- prioritize readability and density

## 11.4 Buttons
Button styles in v1:
- small bordered utility button for `Refresh`
- stronger push-button treatment for row-level `Quit`
- standard window actions in settings

## 11.5 Color usage
Use color sparingly:
- pressure badge
- summary memory bar
- per-app mini meters

Everything else should stay mostly neutral.

## 11.6 Background philosophy
The mock preview can use an ambient gradient backdrop, but the actual app should not ship with an expensive or theatrical background treatment.

Real app surfaces should be simple and native.

---

# 12. Functional Requirements

## 12.1 Menu Bar Presence
- app must launch into the menu bar
- app should be usable primarily from the menu bar surface
- app should not require a main document window

## 12.2 Memory Summary
The app must display:
- total unified memory
- used memory
- available memory
- used percentage
- pressure state

## 12.3 Running Applications List
The app must display a user-relevant list of running applications with:
- app name
- icon when enabled in settings
- memory usage in human-readable units
- percent of total memory
- list sorted according to selected sort mode

## 12.4 Quit Action
- each row exposes a `Quit` action
- this action must be a graceful normal quit
- the app should not skip save prompts
- force quit is not part of the primary v1 surface

## 12.5 Refresh
- user can manually trigger refresh
- app also refreshes automatically on a lightweight interval

## 12.6 Settings
Supported settings in v1:
- launchAtLogin: Bool
- showDockIcon: Bool
- showAppIcons: Bool
- sortMode: Enum
- refreshInterval: Enum
- baseloadLimit: Enum

## 12.7 Update Check
The app must expose a `Check for Updates…` command.

Implementation note:
- if Sparkle is integrated, this should call the updater directly
- if update integration is deferred during early local development, the command may be temporarily stubbed or hidden in debug builds

## 12.8 About
The app must expose `About KillSwitch` and open the standard about panel.

## 12.9 App Quit
The app must expose `Quit KillSwitch` to terminate itself.

---

# 13. Technical Architecture

## 13.1 Stack
- Swift
- SwiftUI
- AppKit interop only where needed
- no unnecessary dependencies in core functionality

## 13.2 App structure
Use SwiftUI App lifecycle.

Primary scenes:
- MenuBarExtra scene
- Settings scene

Optional:
- standard about panel through AppKit

## 13.3 Recommended source tree

```text
KillSwitch/
├── KillSwitchApp.swift
├── Models/
│   ├── AppMemoryStat.swift
│   ├── MemorySnapshot.swift
│   ├── PressureLevel.swift
│   └── SettingsModel.swift
├── Services/
│   ├── MemoryMonitorService.swift
│   ├── RunningApplicationsService.swift
│   ├── ProcessMemoryService.swift
│   ├── ApplicationQuitService.swift
│   ├── SettingsStore.swift
│   ├── LoginItemService.swift
│   └── UpdateService.swift
├── ViewModels/
│   ├── MenuBarViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarRootView.swift
│   │   ├── PopoverHeaderView.swift
│   │   ├── MemorySummaryCard.swift
│   │   ├── TopApplicationsSection.swift
│   │   ├── ApplicationRowView.swift
│   │   ├── FooterBarView.swift
│   │   └── OverflowMenuContent.swift
│   └── Settings/
│       └── SettingsView.swift
├── Support/
│   ├── Formatters.swift
│   ├── DesignTokens.swift
│   ├── PreviewData.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

---

# 14. Model Definitions

## 14.1 AppMemoryStat
Suggested fields:
- id
- pid
- name
- bundleIdentifier
- icon
- memoryBytes
- memoryPercentOfTotal
- isFrontmost

## 14.2 MemorySnapshot
Suggested fields:
- totalBytes
- usedBytes
- availableBytes
- usedPercent
- pressureLevel
- capturedAt

## 14.3 PressureLevel
Enum examples:
- normal
- elevated
- high
- critical

## 14.4 SettingsModel
Suggested fields:
- launchAtLogin
- showDockIcon
- showAppIcons
- sortMode
- refreshInterval
- baseloadLimit

---

# 15. Service Responsibilities

## 15.1 MemoryMonitorService
Responsible for:
- total memory snapshot
- available memory snapshot
- used memory calculation
- pressure state evaluation or system pressure mapping

## 15.2 RunningApplicationsService
Responsible for:
- reading running user-facing applications
- app names
- bundle ids
- icons
- frontmost detection if needed

## 15.3 ProcessMemoryService
Responsible for:
- per-process memory reads
- joining memory values back onto running applications
- avoiding UI logic

## 15.4 ApplicationQuitService
Responsible for:
- graceful application termination only
- clean encapsulation of quit behavior

## 15.5 SettingsStore
Responsible for:
- saving and loading preferences
- likely backed by UserDefaults in v1

## 15.6 LoginItemService
Responsible for:
- enabling / disabling launch at login

## 15.7 UpdateService
Responsible for:
- manual update checks
- integration with Sparkle or a future updater path

---

# 16. View Model Responsibilities

## 16.1 MenuBarViewModel
Responsible for:
- combining memory snapshot and application list
- sorting rows
- applying baseload inclusion rules
- exposing top 5–7 apps
- manual refresh
- timed refresh while popover is open
- simple state handling for errors / empty results

## 16.2 SettingsViewModel
Responsible for:
- reading settings
- updating settings
- resetting defaults

---

# 17. Refresh Strategy

KillSwitch must stay lightweight.

## Refresh rules
- refresh immediately when popover opens
- refresh every 3–5 seconds while popover remains open
- pause or significantly reduce work while popover is closed
- manual `Refresh` button forces an immediate reload

This avoids turning the utility into a constant background sampler.

---

# 18. Sorting Rules

## Default sort mode
- memory descending

## Optional v1 secondary sort mode
- name ascending

The app list should remain short and useful. It should not attempt to become a full process explorer.

---

# 19. App Filtering Rules

The displayed list should prefer user-relevant apps.

## Inclusion rule
An app should appear in the utility if it meets one of the following:
- it is within the top 5–7 user-relevant apps by memory usage
- its memory usage exceeds the configured baseload limit
- its percent of total memory is meaningfully large enough to remain useful in the list if additional tuning is needed during implementation

The goal is to avoid clutter from tiny processes while still surfacing meaningful offenders.

## Baseload limit behavior
Baseload limit is a user-configurable filter that determines the minimum memory usage for an app to be eligible for display outside of the top ranked apps.

Recommended default behavior:
- Auto
- 150 MB
- 250 MB
- 500 MB
- 1 GB

### Auto mapping
- 8 GB Macs → 150 MB
- 16 GB Macs → 250 MB
- 24 GB or greater Macs → 500 MB

This keeps the list useful across lower-memory and higher-memory machines.

## Should favor
- visible apps
- normal user applications
- familiar high-level apps like browsers, Slack, Figma, Spotify, Notion

## Should avoid or deprioritize
- low-level helper processes that clutter the list
- system daemons
- internal utility processes unless explicitly needed

Exact filtering can be tuned during implementation, but the final list should feel clean.

---

# 20. Quit Behavior Requirements

## Required behavior
- `Quit` must request normal app termination
- do not bypass the app’s own lifecycle
- preserve normal save prompts

## Failure handling
If an app cannot be quit normally:
- do not crash
- do not hang the UI
- optionally show a small inline failure state later if needed
- force quit remains out of scope for primary v1

---

# 21. Settings Specification

## 21.1 Launch at login
- type: toggle
- default: off or on depending on desired product stance
- recommended default for early builds: off

## 21.2 Show Dock icon
- type: toggle
- default: off

## 21.3 Show app icons
- type: toggle
- default: on

## 21.4 Sort apps by
- type: segmented / menu / picker
- values:
  - Memory
  - Name
- default: Memory

## 21.5 Refresh interval
- type: picker
- values:
  - 3 sec
  - 5 sec
  - 10 sec
- default: 5 sec

## 21.6 Baseload limit
- type: picker
- values:
  - Auto
  - 150 MB
  - 250 MB
  - 500 MB
  - 1 GB
- default: Auto

### Auto mapping
- 8 GB Macs → 150 MB
- 16 GB Macs → 250 MB
- 24 GB or greater Macs → 500 MB

This setting controls the minimum memory usage required for an app to qualify for display outside of the top memory-ranked apps.

## 21.7 Restore defaults
Resets all settings to v1 defaults.

---

# 22. Update Strategy

## Recommendation
If KillSwitch is distributed outside the App Store, use Sparkle for update checks and signed release delivery.

## v1 approach
- UI includes `Check for Updates…`
- if Sparkle is wired, call the updater directly
- if Sparkle is not yet wired in development builds, allow this path to be disabled or stubbed

## Distribution path
- GitHub repository is the source of truth for code
- GitHub Releases can be the release channel
- notarized builds and signed archives can be added as the release path when ready

---

# 23. About Panel Strategy

Use the standard About panel instead of building a custom About window.

This keeps the app native and avoids unnecessary UI surface area.

---

# 24. Native macOS Design Rules for Implementation

## Must do
- prefer standard SwiftUI and AppKit patterns
- keep controls compact
- use material lightly
- use a window-like menu bar popover layout
- make settings intentionally small

## Must avoid
- custom chrome for the sake of custom chrome
- oversized rounded dashboard cards
- decorative motion
- design systems that add weight without function

## Design success test
When opened, KillSwitch should feel like a native utility someone already had on their Mac.

---

# 25. Runtime Performance Requirements

KillSwitch must remain credible as a memory utility.

## Requirements
- low idle overhead
- no constant heavy polling while closed
- no charts or history models in v1
- no image-heavy UI
- no web views
- no heavy dependency graph

## Philosophy
The utility itself should not become the thing the user wants to quit.

---

# 26. Error / Edge Case Handling

## Cases to handle
- no meaningful app list returned
- permissions or API limitations for some processes
- transient memory readings changing between refreshes
- app quit call does nothing
- icon missing for some apps
- updater unavailable in debug builds

## Expected UX response
- stay quiet and stable
- degrade gracefully
- avoid noisy alerts unless absolutely necessary

---

# 27. Codex Build Plan

This PRD should be used as the implementation spec for Codex.

## Milestone 1 — App shell
- create macOS SwiftUI app
- add MenuBarExtra entry point
- add Settings scene
- wire basic icon and popover shell

## Milestone 2 — Data plumbing
- implement memory snapshot service
- implement running applications service
- implement per-app memory service
- expose mockable data models

## Milestone 3 — Popover UI
- build header
- build summary card
- build top applications list
- build Quit row button
- build footer and settings shortcut

## Milestone 4 — Overflow menu
- add `Refresh Now`
- add `Check for Updates…`
- add `About KillSwitch`
- add `Settings…`
- add `Quit KillSwitch`

## Milestone 5 — Settings
- build mini settings window
- persist values with UserDefaults-backed store
- wire launch at login
- wire refresh interval and sort mode

## Milestone 6 — Polish
- filter app list better
- tune spacing and materials
- validate refresh behavior
- verify quit flow and save prompt preservation

## Milestone 7 — Open-source readiness
- add README
- add screenshots / GIF
- add install instructions
- add roadmap and contribution notes

---

# 28. Acceptance Criteria

KillSwitch v1 is done when:
- it launches into the menu bar reliably
- the popover opens fast
- memory summary is understandable at a glance
- top memory-heavy apps are shown clearly
- `Quit` performs graceful termination
- overflow menu contains app-level commands
- settings window is minimal and functional
- update command path is accounted for
- about panel opens correctly
- the app still feels small, calm, and unobtrusive

---

# 29. README Positioning Copy

## One-line README intro
KillSwitch is a lightweight macOS menu bar utility for seeing memory pressure and quickly quitting heavy apps.

## Supporting copy
Built in Swift and SwiftUI, KillSwitch gives you a fast, native way to spot memory-heavy apps and gracefully quit them without opening Activity Monitor.

---

# 30. Future Ideas After v1

These are explicitly post-ship ideas:
- optional force quit secondary action
- improved helper-process filtering
- compact popover mode
- Activity Monitor shortcut
- menu bar pressure-only mode
- basic optional notifications

These should not block v1.

---

# 31. Final Product Test

If a user can install KillSwitch, click it, immediately understand system memory pressure, quit a heavy app, and then forget the utility exists until they need it again, the product is working.

