# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - TBD

### Added

* Added shared counts across paired motion keys.
* Added CI tests.
* Added `luacov` for code coverage.

### Changed

* Changed deceleration to holding the opposite motion key. For example, holding `k` while holding `j` reduces the motion amount.
* Consecutive taps now increase the motion amount up to 4×; a third consecutive tap resets the acceleration.

### Fixed

* Prevented acceleration when an event is detected as an invalid repeat (`ng_repeat`).
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
