# 🪟 Win11-Style Application Launcher for KDE Plasma

A modern, Windows 11 inspired application launcher menu for KDE Plasma 6.
Clean dark design, fast search and full KDE integration – built with pure QML.

### ✨ Features

- 📌 **Pinned apps** – pin/unpin applications via right-click context menu
- 🔤 **All applications** – alphabetically grouped applications
- 📐 **Grid / List view** – switch between a compact grid and a clean list layout
- 🔍 **Integrated search** – applications, files (via Baloo) and system settings
- ⌨️ **Quick search** – press `Ctrl+F` to instantly focus the search field
- 👤 **User info** – avatar and full name of the current user
- ⚡ **Session actions** – logout, restart and shutdown
- 🔒 **Fixed popup size** – additional pinned apps do not resize the launcher

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

2. Restart Plasma:

   ```bash
   killall plasmashell && kstart plasmashell
   ```

   or log out and back in.

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

## 📄 License / Lizenz

GPL-2.0-or-later

---

Made with 🦊 and lots of QML
