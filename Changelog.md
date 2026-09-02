# Changelog
All notable changes to this project will be documented in this file.

## [1.2.4] – Privacy Option

### Added
- added a privacy setting to hide the user name and avatar from the launcher footer, useful for screen sharing and video conferencing
- user information remains visible by default to preserve the existing launcher appearance

### Changed
- updated package metadata for version 1.2.4

## [1.2.3] – Pinned Groups & Scrolling Improvements

### Changed
- pinned-group application hover areas now match the compact hover style used by regular pinned applications
- pinned groups can now contain up to 16 applications and display them in up to 4 columns × 4 rows
- group popups now adapt their width to smaller groups instead of always using the full four-column layout
- Pinned and All Applications now share one continuous scroll area while the search field and footer remain fixed
- pinned rows expand and collapse with a short smooth animation instead of moving the All Applications section abruptly
- updated package metadata for version 1.2.3

### Fixed
- hardened pinned-group limits so oversized or malformed saved groups are automatically normalized to a maximum of 16 unique applications
- prevented applications beyond the supported group limit from being stored invisibly outside the visible group popup
- the **Pin** action in All Applications is now hidden when an application is already pinned, including applications currently placed inside a pinned group
- large pinned sections can no longer push All Applications out of reach because both sections now scroll together

## [1.2.2] – Footer Alignment Improvements

### Changed
- centered each session-action icon and label as a single visual unit inside its button for more balanced hover highlighting
- session-action buttons now adapt their width to longer translated labels while keeping the previous button sizes as minimum widths
- the user-info area now yields space when needed so longer session labels remain fully visible, with the user name elided cleanly if space becomes tight
- updated package metadata for version 1.2.2

### Credits
- footer alignment improvement inspired by PR #12 from Batman123n

## [1.2.1] – View State & Scroll Fixes

### Fixed
- the All Applications Grid/List selection now persists across Plasma sessions and system restarts
- the All Applications scroll position now resets to the top whenever the launcher is closed, so reopening always starts at the beginning

### Changed
- updated package metadata for version 1.2.1

## [1.2.0] – Flexible Layout & Customization

### Added
- configurable menu height from 600 px to 1200 px with a default of 800 px
- configurable menu width from 800 px to 1600 px with a default of 1000 px
- configurable application icon size from 24 px to 48 px with a default of 36 px
- min/max/default hints directly below the new layout settings

### Changed
- the launcher now defaults to a more compact 1000 × 800 px layout
- wider launcher widths automatically add more pinned-app columns while keeping at least 8 columns
- application icon sizing now applies consistently to pinned apps, All Applications, search results and pinned-group popups
- hover areas now adapt more closely to the configured icon size and content layout
- updated package metadata for version 1.2.0

## [1.1.1] – Launcher Icon Improvements

### Added
- added a bundled product icon for the Plasma widget and launcher alternatives view
- added a bundled `start-here.svg` as the default menu icon to avoid relying on the user's installed icon theme

### Changed
- the default menu icon now always uses the bundled `start-here.svg`
- custom icons selected in the launcher settings continue to use the KDE icon theme
- resetting the menu icon restores the bundled default icon
- updated package metadata for version 1.1.1

## [1.1.0] – Modularization & Context Menu Improvements

### Added
- split the launcher UI into dedicated QML components for Search Bar, Pinned Section, Pinned Group Dialogs, Pinned Group Popup, All Applications, Search Results and Launcher Footer
- added native KDE context actions to applications in the All Applications view:
  - Pin to Task Manager
  - Edit Application
- added the same native KDE context actions to application search results

### Changed
- refactored `main.qml` into a smaller central launcher/controller while keeping KDE models and shared launcher logic centralized
- simplified the context menu for applications inside pinned groups to **Remove from group** only
- file and system-settings search results now explicitly accept left-click only; right-click remains reserved for application results
- cleaned up obsolete Pinned Group Popup properties and bindings
