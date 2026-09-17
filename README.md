# UnknownSquad Rayfield

This is a personal fork of Rayfield that I reworked and cleaned up for actual day-to-day use. The original library had way too many console logs, stale comments, and awkward layout bugs that became annoying when scaling the window, so I stripped the bloat and added the controls I actually wanted.

## What I changed

- Replaced the stock intro with a clean UnknownSquad splash screen that fades out smoothly without leaving a solid black box behind.
- Added an in-game UI editor directly inside the settings tab:
  - Live window resizing from 380x250 up to 850x750 with instant preview.
  - A quick reset button to snap back to the default size if you mess it up.
  - A font picker with over fifty fonts to choose from.
  - Theme switching that properly clears and overwrites previous colors instead of stacking them weirdly.
  - Granular RGB pickers for each layer of the interface.
  - Config saving and loading so your visual setup persists between sessions.
- Fixed the bottom drag handle so it follows the window height cleanly instead of overlapping buttons or breaking mouse movement.
- Fixed z-indexing so long slider numbers no longer clip right through the tab sidebar.
- Simplified all asset filenames down to numbers from 1 to 18 so they are easy to host, manage, and load locally or remotely without giant URL strings.

## Asset list

All images live in the assets folder under numeric names:

- 1.png: UnknownSquad loading screen logo
- 2.png: Window and search drop shadows
- 3.png: Hide window button
- 4.png: Maximize size button
- 5.png: Settings gear button
- 6.png: Topbar hub icon
- 7.png: Search magnifying glass
- 8.png: Switch and slider track shadows
- 9.png: Dropdown arrow
- 10.png: Label icon
- 11.png: Color picker saturation canvas
- 12.png: Color picker reticle pointer
- 13.png: Default tab button icon
- 14.png: Search input background
- 15.png: Notification alert icon
- 16.png: Notification drop shadow
- 17.png: Restore window size button
- 18.png: Extra UI asset

## Setup

Just make sure your environment supports the usual file system and asset functions so it can cache the images to your workspace folder and fetch the library.
