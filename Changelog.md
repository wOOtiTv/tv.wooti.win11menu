# Changelog
All notable changes to this project will be documented in this file.

## [1.0.7] – Stability & KDE Integration

### Fixed
- restored reliable loading of the alphabetically grouped All Applications view after launcher and Plasma model refreshes
- fixed pin/unpin support for application search results
- fixed KDE launcher actions by passing the correct plasmoid interface to Kicker models
- fixed Pin to Task Manager behavior
- initialized KDE favorites per launcher instance, matching the native Kicker/Kickoff behavior

### Changed
- removed Add to Desktop from the launcher context menu because the corresponding Plasma action can fail with desktop-link permission errors independently of this launcher

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
