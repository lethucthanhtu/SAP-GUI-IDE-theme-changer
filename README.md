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

## 🧰 Requirements

* Windows with SAP GUI for Windows installed (theme file lives in `%APPDATA%\SAP\SAP GUI\ABAP Editorbap_spec.xml`)
* Windows PowerShell 5.1 or PowerShell 7+
* Internet access to `sap.lttt.dev` (or the Vercel backup) for remote themes

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
irm https://cdn.lttt.dev/sap/editor.ps1 | iex
```

Backup Server

```powershell
irm https://letu-sap.vercel.app/editor.ps1 | iex
```

🔒 **Safer: review before you run.** `irm | iex` runs whatever the server returns at that moment.
To check the script first:

```powershell
irm https://cdn.lttt.dev/sap/editor.ps1 -OutFile editor.ps1
notepad .\editor.ps1                 # read it
Get-FileHash .\editor.ps1 -Algorithm SHA256
powershell -ExecutionPolicy Bypass -File .\editor.ps1
```

Or pin to an exact, reviewed commit on GitHub (replace `<commit>` with a full commit SHA):

```powershell
irm https://raw.githubusercontent.com/lethucthanhtu/SAP-GUI-IDE-theme-changer/<commit>/public/editor.ps1 | iex
```

See [SECURITY.md](./SECURITY.md).

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
* The very first time a theme is applied, the original file is also copied to `abap_spec.original.xml`; this copy is never overwritten

### Restore / uninstall

The script installs nothing. To go back to the theme you had before using it, close SAP GUI and run:

```powershell
$dir = "$env:APPDATA\SAP\SAP GUI\ABAP Editor"
Copy-Item "$dirbap_spec.original.xml" "$dirbap_spec.xml" -Force
```

Then delete `abap_spec.previous_theme.xml` and `abap_spec.original.xml` if you no longer need them.

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
