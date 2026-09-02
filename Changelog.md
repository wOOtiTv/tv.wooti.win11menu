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
- hardened pinned-group limits so oversized or otherwise malformed saved groups are automatically normalized to a maximum of 16 unique applications
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

### Fixed
- improved closing behavior for pinned group popups and their context menus when clicking outside or closing the launcher
- removing one application from a multi-app group now keeps the group popup open, while removing the last application closes the popup and removes the empty group
- pinned group preview icons now follow the same alphabetical ordering as the launcher

## [1.0.7] – Stability & KDE Integration

### Fixed
- restored reliable loading of the alphabetically grouped All Applications view after Plasma model refreshes
- added pin/unpin support for application search results
- fixed KDE launcher context actions by using the correct plasmoid interface
- fixed Pin to Task Manager behavior
- improved KDE favorites initialization for the launcher instance

### Changed
- removed Add to Desktop from the context menu because the corresponding KDE/Plasma action can fail independently of this launcher

## [1.0.6] – Customization & Pinned Groups

### Added
- configurable launcher menu icon in General settings
- display of the currently selected menu icon name
- Lock Screen session action
- individual visibility settings for Lock Screen, Log Out, Restart and Shut Down buttons
- optional groups for pinned applications
- create a new group or add pinned applications to an existing group via the right-click context menu
- rename or dissolve pinned application groups
- remove applications from a group without unpinning them
- compact group preview directly in the pinned apps grid
- group popup with up to 12 applications in a 4 × 3 layout
- native KDE context actions for regular pinned applications:
  - Add to Desktop
  - Pin to Task Manager
  - Edit Application

### Changed
- pinned applications and groups are kept in alphabetical order
- applications inside pinned groups are kept in alphabetical order
- pinned groups can be enabled or disabled in General settings without deleting existing group assignments
- expanded General settings with launcher icon, pinned group and session button options

## [1.0.5] – Internationalization & Language Support

### Added
- translation support for English, German, French, Italian and Dutch
- system language as the default launcher language
- manual language override in General settings
- English fallback for missing translations
- per-widget runtime translation handling without changing the global Plasma language

### Changed
- updated bug report target to GitHub Issues

## [1.0.4] – Polish & Localization Preparation

### Changed
- prepared the launcher UI strings for the upcoming translation system
- improved the runtime translation handling for widgets

## [1.0.3] – Search & UX Polish

### Changed
- improved integrated search for apps, files (Baloo) and system settings
- improved the helpful hint when the Baloo file search returns no results
- refined dark design, hover effects and smooth animations

## [1.0.2] – Layout Refinements

### Changed
- refined pinned apps grid and pin/unpin context menu behavior
- refined alphabetically grouped "All Applications" view with scrollbar
- refined adaptive popup size based on screen dimensions

## [1.0.1] – Post-Release Hotfixes

### Fixed
- small stability, packaging and metadata fixes after the initial release

## [1.0.0] – Initial Release

### Added
- Windows 11 style application launcher for KDE Plasma 6
- Pinned apps grid with pin/unpin context menu
- Alphabetically grouped "All Applications" view with scrollbar
- Integrated search for apps, files (Baloo) and system settings
- User avatar and full name display
- Session actions: logout, restart and shutdown
- Adaptive popup size based on screen dimensions
- Dark design with hover effects and smooth animations
- Helpful hint when the Baloo file search returns no results
