# UnknownSquad Rayfield

This is a personal fork of Rayfield that I reworked and cleaned up for actual day-to-day use. The original library had way too many console logs, stale comments, and awkward layout bugs that became annoying when scaling the window, so I stripped the bloat, cleaned the source to pure ASCII with zero dead comments, and added the features I actually wanted.

## What I changed

- **UnknownSquad Splash Screen**: Replaced the stock intro with a clean UnknownSquad splash screen that fades out smoothly without leaving a solid black box behind.
- **In-Game UI Editor (Settings Tab)**:
  - Live window resizing from 380x250 up to 850x750 with instant preview.
  - A quick reset button to snap back to the default dimensions.
  - UI Font Family dropdown with over 50 fonts (Gotham, Arcade, RobotoMono, BuilderSans, etc.) that dynamically propagates across all text labels, buttons, and file listings in real time.
  - Theme switching that properly clears and overwrites previous colors instead of stacking them awkwardly.
  - Granular RGB color pickers for each layer of the interface.
  - Visual setup persistence with automatic config saving and loading.
- **Built-in Workspace File Manager**:
  - Direct filesystem explorer opened via the folder icon on the topbar.
  - Sequential index numbering for all items (`1. AutoLoot`, `2. dex`, etc.).
  - Real-time instant search bar and folder navigation with back navigation.
  - Right-click / three-dot context menu with unroll and scale animations: Run Script, Copy File Content, Copy Path, and Copy Name.
  - Automatic context menu closure on mouse wheel scroll or canvas drag.
- **Mobile Floating Toggle Button**:
  - Draggable 4-blade star emblem button with zero-lag 1:1 touch/cursor tracking.
  - Touch-exclusive platform gate: automatically visible on mobile phones and tablets, completely hidden on PC desktop to keep the display clean (overrideable via `MobileToggle = true` in config).
  - Dynamic theme tinting: the star emblem and hover stroke automatically adapt to the current interface accent color.
- **Layout & Interaction Fixes**:
  - Bottom drag handle follows window height cleanly without overlapping buttons.
  - Z-indexing fixed so long slider values and elements never clip through the tab sidebar.
  - Ultra-smooth Quart and Exponential easing curves applied across all menus, toggles, and modals.
- **Pure Numeric Asset Pipeline**:
  - Eliminated all text-named image files. All 23 assets are strictly numbered from `1.png` to `23.png` for clean, lightweight local caching and fast remote delivery.
  - Codebase stripped of all comments and non-ASCII characters.

## Asset list

All images live in the assets folder under numeric names:

- `1.png`: UnknownSquad loading screen banner / logo
- `2.png`: Window and search drop shadows
- `3.png`: Topbar hide window button
- `4.png`: Topbar maximize size button
- `5.png`: Topbar settings gear button
- `6.png`: Topbar hub icon
- `7.png`: Topbar search magnifying glass
- `8.png`: Switch and slider track shadows
- `9.png`: Dropdown arrow
- `10.png`: Label icon
- `11.png`: Color picker saturation canvas
- `12.png`: Color picker reticle pointer
- `13.png`: Default tab button icon
- `14.png`: Search input background
- `15.png`: Notification alert icon
- `16.png`: Notification drop shadow
- `17.png`: Window restore size button
- `18.png`: Extra UI asset / warning
- `19.png`: File manager folder icon
- `20.png`: File manager file icon
- `21.png`: Context menu run script icon
- `22.png`: Context menu copy icon
- `23.png`: Mobile floating toggle star emblem

## Setup

Just make sure your environment supports the standard executor file system and asset functions (`readfile`, `writefile`, `listfiles`, `isfolder`, `getcustomasset`) so it can cache the images to your workspace folder and load the library.
