# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - TBD

### Fixed

* Fixed a one-key delay when applying the effect of a held key.

## [0.2.0] - 2026-09-26

### Changed

* Extracted key event handling into `keyevent.nvim`.
* Removed configurable `rush_count` and fixed the acceleration factor at 2×.
* Added acceleration and deceleration using `hold j` and `tap j + hold j`.
* Added acceleration and deceleration using modifier keys.
* Added support for buffer switching caused by mouse clicks.

## [0.1.0] - 2026-09-13

### Added

* Accelerate repeated `h`, `j`, `k`, and `l` motions.
* Detect key timing to distinguish clicks, taps, and holds.
* Configure acceleration behavior with `setup()`.

### Changed

* Preserve normal Neovim motions when acceleration is not triggered.
