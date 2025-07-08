# SAP GUI Theme Changer

## 📄 Overview

**SAP GUI IDE Theme Changer** is a script-based utility to switch between custom SAP GUI IDE theme

---

## 🛠️ Features

✅ Fetches available themes dynamically
✅ Allows user selection from a clean interactive menu
✅ Backs up the current theme before changing
✅ Supports rollback to the previous theme
✅ Designed for **PowerShell (SAP GUI for Windows)**

---

## 🚀 Usage

### **Run Locally**

```powershell
# Clone repository
git clone https://github.com/lethucthanhtu/SAP-GUI-IDE-theme-changer.git
cd sap-gui-theme-changer
````

---

### **Run Remotely via IWR**

If hosted on a public server with HTTPS:

```powershell
iwr -useb https://sap.lttt.dev/editor.ps1 | iex
```

---

## 🔄 Rollback Feature

When a theme is applied:

* The existing `abap_spec.xml` is backed up as `abap_spec.previous_theme.xml`.
* Rollback restores this backup, enabling seamless reversion to your previous setup.

---

## 📂 Themes Management

* Place all `*_theme.xml` files under the `themes/` directory.
* Add the theme to `themes.json` for listing
* **Note**: Not support on remote use

---
