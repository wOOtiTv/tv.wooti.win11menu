# 🪟 Win11-Style Application Launcher for KDE Plasma

A modern, Windows 11 inspired application launcher menu for KDE Plasma 6.
Clean dark design, fast search and full KDE integration – built with pure QML.

### ✨ Features

- 📌 **Pinned apps** – pin/unpin applications via right-click context menu
- 🗂️ **Pinned groups** – organize pinned apps into optional named groups with up to 12 apps per group
- 🧩 **KDE context actions** – add regular pinned apps to the desktop, pin them to the Task Manager or edit their application entry
- 🔤 **All applications** – alphabetically grouped applications
- 📐 **Grid / List view** – switch between a compact grid and a clean list layout
- 🔍 **Integrated search** – applications, files (via Baloo) and system settings
- ⌨️ **Quick search** – press `Ctrl+F` to instantly focus the search field
- 🎨 **Custom menu icon** – choose the launcher icon directly in General settings
- 🌍 **Multi-language support** – English, German, French, Italian and Dutch
- ⚙️ **Language selection** – follow the system language or choose a language manually
- 🇬🇧 **English fallback** – missing translations fall back to English
- 👤 **User info** – avatar and full name of the current user
- 🔐 **Session actions** – Lock Screen, Log Out, Restart and Shut Down
- 👁️ **Session button visibility** – show or hide each session button individually
- 🔒 **Fixed popup size** – additional pinned apps do not resize the launcher

### ⚙️ Customization

Open:

**Configure Windows 11 Start Menu → General**

Available options include:

- **Language** – use the system language or choose a supported language manually
- **Menu icon** – choose a different KDE/system icon for the launcher
- **Pinned apps → Enable groups** – enable or disable pinned application groups
- **Session buttons** – individually show or hide Lock Screen, Log Out, Restart and Shut Down

Disabling pinned groups does **not** delete existing group assignments. Re-enabling the option restores them.

### 🗂️ Pinned application groups

Pinned groups make it possible to organize related applications without changing the normal KDE favorites list.

To create or use a group:

1. Right-click a regular pinned application.
2. Choose **Add to group…**.
3. Select an existing group or create a new one.

Group behavior:

- groups and regular pinned applications stay alphabetically sorted
- applications inside a group stay alphabetically sorted
- a group shows a compact preview of the applications it contains
- clicking a group opens its applications in a compact popup
- each group can contain up to **12 applications**
- the popup displays up to **4 columns × 3 rows** without scrolling
- right-click a group to rename or dissolve it
- right-click an application inside a group to remove it from the group or unpin it completely

Regular pinned applications also expose selected native KDE actions in their context menu:

- **Add to Desktop**
- **Pin to Task Manager**
- **Edit Application**

### 🌍 Languages

The launcher follows the system language by default.

You can override it in:

**Configure Windows 11 Start Menu → General → Language**

Supported languages:

- Deutsch
- English
- Français
- Italiano
- Nederlands

If a translation is missing, the launcher falls back to English.

### 📦 Requirements

- KDE Plasma 6 (Qt 6 / QML)
- Optional: **Baloo** file indexer for file search

### 🛠️ Installation

**Via KDE Store (recommended):**

1. Right-click your desktop → *Add Widgets* → *Get New Widgets*
2. Search for this plasmoid and click *Install*
3. Right-click your panel → *Add Widgets* → drag the launcher onto the panel

**Manual:**

1. Copy the folder to:

   `~/.local/share/plasma/plasmoids/tv.wooti.win11menu`

2. Restart Plasma or log out and back in.

### 📁 Setting up file search (Baloo)

The file search uses KDE's native Baloo index.
Only **indexed folders** are searched. If your files are not found, enable
indexing and add the folders you want:

1. Open **System Settings**
2. Go to *Search → File Search*
3. Enable indexing and add the folders you want (Documents, Downloads, …)
4. Click *Apply*

**Or via terminal:**

```bash
balooctl6 enable
balooctl6 check
balooctl6 status
```

> 💡 **Note:** If Baloo is disabled or folders are excluded in your setup,
> file search will return no results. Application and system settings search
> work regardless.

---

## 📄 License

GPL-2.0-or-later

---

Made with 🦊 and lots of QML
