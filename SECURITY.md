# Security policy

## Supported versions

Only the latest `main` is supported.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem. Report it privately through
GitHub: _Security_ tab -> _Report a vulnerability_
(<https://github.com/lethucthanhtu/SAP-GUI-IDE-theme-changer/security/advisories/new>).
Include what is affected, how to reproduce it, and the impact.

In scope, for example: the hosted script or theme files being served with content that does
not match this repository, the script writing outside
`%APPDATA%\SAP\SAP GUI\ABAP Editor\`, or losing the user's theme without a backup.

Out of scope: SAP GUI itself, and attacks that need someone who already controls your machine.

## Running the one-liner safely

`irm <url> | iex` runs whatever the server returns at that moment, with your user's rights.
The script only reads theme lists and XML files and writes the ABAP Editor theme file plus its
backups; it needs no administrator rights, so never run it elevated.

If you want to be sure what runs:

1. Download it instead of piping it: `irm https://cdn.lttt.dev/sap/editor.ps1 -OutFile editor.ps1`.
2. Read it, and compare `Get-FileHash .\editor.ps1 -Algorithm SHA256` with the hash of
   `public/editor.ps1` at the commit you reviewed on GitHub.
3. Or pin the URL to a commit: `https://raw.githubusercontent.com/lethucthanhtu/SAP-GUI-IDE-theme-changer/<commit>/public/editor.ps1`.

Theme XML files are still downloaded at run time from `sap.lttt.dev` (or the Vercel backup).
The script checks that a download is a well-formed ABAP Editor spec before replacing your theme,
and keeps `abap_spec.previous_theme.xml` and `abap_spec.original.xml` so you can always restore.
