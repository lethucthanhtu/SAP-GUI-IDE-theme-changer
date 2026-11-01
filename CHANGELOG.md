# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- A failed theme change no longer prints "applied successfully"; the real error is shown.
- Remote themes are downloaded to a temporary file and checked before `abap_spec.xml` is
  replaced, so a failed or wrong download can no longer leave a broken theme file.
- The `(local)` / `(remote)` tag for themes that exist in both places is shown again.

### Added

- `abap_spec.original.xml`: a one-time backup of your theme from before the first change,
  never overwritten (the rollback backup is replaced on every change).
- README: requirements, a review-before-run / pinned-commit way to run the script, and
  restore steps. `SECURITY.md`.
- CI: PSScriptAnalyzer on every push and pull request.

## [1.0.0]

- Interactive theme switcher with local and remote themes, hex option numbering and rollback.
