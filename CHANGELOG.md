# Changelog

All notable changes to the **Tend** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-11-19

### Added
* **Habit Tracker Core:**
  * Clean architecture implementation with `Habit`, `HabitCompletion`, and `DayProgress` models.
  * Abstract `HabitRepository` contract with `LocalHabitRepository` backed by `SharedPreferences`.
  * `HabitController` managing state, real-time validation, and streak calculations.
  * Interactive habit checkpoints with organic completion ring animation.
  * Weekly rhythm overview ribbon (`WeeklyProgressBar`) with Mon–Sun completion indicators.
  * Habit creation and editing modal (`HabitFormSheet`) with title validation and custom weekday selection.
  * Archival management modal (`HabitArchiveSheet`) supporting soft-deletion and restoration.
  * Dedicated unit and widget test suite (`test/habit_tracker_test.dart` and `test/widget_test.dart`).
* **Design & Voice Interaction:**
  * Custom geometric listening mark (`TendVoiceButton`) based on the 4-fold Tend brand knot.
  * Four interaction states: Idle breathing, tactile press contraction, acoustic amplitude listening, and orbital processing.
  * Popping-out floating footer button design (`TendBottomNavBar`) extending above the bottom navigation bar.
* **Documentation & Customizations:**
  * Consolidated `DOCUMENTATION.md` detailing models, algorithms, and proposed REST API contracts.
  * Custom workspace and global skill `tend-docs` enforcing consolidated documentation for future features.

### Changed
* Color palette aligned with exact logo assets (warm caramel, espresso, and creamy linen paper `#F9EFE7`).
* Cropped and converted logo asset to anti-aliased transparent PNG.

---

## [1.0.0] - 2026-11-17

### Added
* Initial project scaffolding with Flutter 3.50.0.
* Editorial typography setup using Google Fonts (Newsreader and Manrope).
* Foundational theme configuration and bottom navigation shell.
