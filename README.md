# SAP GUI code editor theme changer

A simple theme changer for SAP GUI's code editor

## Usage

### IWR use

```txt
iwr -useb https://sap.lttt.dev/editor.ps1 | iex
```

The powershell script is made specific for invoke web request only, therefore, it won't have save and format feature

### Local use

Run `SAP_theme_changer.sh` or `SAP_theme_changer.bat` to change theme

To add more theme:

- Navigate to **./themes**
- Add theme XML file, rename file to `*_theme.xml`
