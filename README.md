# SAP GUI Theme Changer

## 📄 Overview

**SAP GUI IDE Theme Changer** is a script-based utility to switch between custom SAP GUI IDE themes.

---

## 🛠️ Features

* ✅ Fetches available themes dynamically
* ✅ Merges **local and remote themes** when run locally
* ✅ Tags duplicates with **(local)** and **(remote)** for clarity
* ✅ Uses **hexadecimal (base-16) option numbering**
* ✅ Clean, interactive menu with aligned output
* ✅ Backs up the current theme before changing
* ✅ Supports rollback to the previous theme
* ✅ Designed for **PowerShell (SAP GUI for Windows)**

---

## 🚀 Usage

### **Run Locally**

```powershell
git clone https://github.com/lethucthanhtu/SAP-GUI-IDE-theme-changer.git
```

```powershell
cd SAP-GUI-IDE-theme-changer
```

```powershell
.\public\editor.ps1
```

✅ **Local execution features:**

* Uses `./themes` folder for local themes
* Fetches remote themes for merging
* Tags duplicate theme names with `(local)` or `(remote)`
* Shows options using **base-16 (hex)** numbering

---

### **Run Remotely via IWR**

Call it via public server with HTTPS:

```powershell
iwr -useb https://sap.lttt.dev/editor.ps1 | iex
```

Backup Server

```powershell
iwr -useb https://letu-sap.vercel.app/editor.ps1 | iex
```

⚠️ Note on path input:

* If `Ctrl+V` does not paste your path in the prompt:

* Use `Ctrl+Shift+V`

* Use `Right Click` or `Shift+Insert` to paste

* Alternatively, press `Windows+V` to access your clipboard history and select the copied path

---

## 🔄 Rollback Feature

When a theme is applied:

* The existing `abap_spec.xml` is backed up as `abap_spec.previous_theme.xml`
* Rollback restores this backup, enabling seamless reversion to your previous setup

---

## 📂 Themes Management

✅ **For local usage:**

* Place all `*_theme.xml` files under the `themes/` directory
* They will be auto-detected when running the script locally

✅ **For remote usage:**

* Ensure `themes.json` lists all available themes:

```json
{
  "themes": [
    "A_theme.xml",
    "B_theme.xml"
  ]
}
```

* Files must be accessible via URLs matching the entries in `themes.json`

---

## ⚠️ Disclaimer

While this script provides a **backup feature** before applying new themes,
you must ensure that your selected XML files are **valid SAP GUI theme files**.

* ✅ Applying an invalid or malformed XML may cause unexpected behavior in your SAP GUI.
* ✅ Always verify the integrity of your theme files before use.
* ✅ Always backup your files.

---

## 📝 License

[GPL-3.0 license](./LICENSE)

---

### 🙏 **Credits**

This project includes themes adapted from [lucattelli/ab4-themes](https://github.com/lucattelli/ab4-themes),
which is licensed under **GPL v3.0**.

---
