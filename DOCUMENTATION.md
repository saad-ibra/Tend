# Tend — Project Architecture & Feature Documentation

> **Tend** is a mindful daily rhythm, focus, and productivity application rooted in Japanese wabi-sabi principles and Scandinavian functionalism. It prioritizes deliberate attention over metric exploitation.

---

## 1. Architectural Overview

The application follows a modular, layered Clean Architecture to enforce separation of concerns, testability, and future extensibility:

```
lib/
├── models/         # Immutable domain models, serialization, and business rules
├── repositories/   # Abstract data contracts and concrete persistence implementations
├── controllers/    # ChangeNotifier-based state management and business logic
├── theme/          # Design tokens, color palette, and typography configurations
├── widgets/        # Reusable presentation components
└── screens/        # Scaffolded top-level page views
```

### Layer Responsibilities
* **Domain Models (`lib/models/`):** Pure Dart classes defining data contracts. Decouples habit specifications (`Habit`) from execution history (`HabitCompletion`).
* **Repository Pattern (`lib/repositories/`):** Defines `HabitRepository` as an abstract interface. The application currently utilizes `LocalHabitRepository` (backed by `SharedPreferences`), which can be swapped with a remote `ApiHabitRepository` without touching UI or business logic.
* **Controller Layer (`lib/controllers/`):** Encapsulates state mutations, validation, streak algorithms, and temporal calculations. Inherits from `ChangeNotifier`.
* **Presentation Layer (`lib/screens/`, `lib/widgets/`):** Stateless and reactive stateful widgets observing controllers. Strictly decoupled from database/storage operations.

---

## 2. Data Models

### 2.1 `Habit`
Defines a rhythm's configuration, recurrence rules, and visual properties.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique identifier (e.g., `h_1710928347120`) |
| `title` | `String` | Title of the habit (e.g., "Morning stillness") |
| `description` | `String?` | Optional intention or contextual note |
| `frequencyType` | `HabitFrequencyType` | Recurrence type (`daily` or `weekdays`) |
| `targetWeekdays` | `List<int>` | Active weekdays (1 = Monday, ..., 7 = Sunday) |
| `colorHex` | `String` | Accent color hex (default: `#744127`) |
| `isArchived` | `bool` | Soft-deletion flag preserving historical logs |
| `createdAt` | `DateTime` | Timestamp of habit creation |
| `archivedAt` | `DateTime?` | Timestamp when habit was archived |

#### Recurrence Evaluation Rule
```dart
bool isScheduledFor(DateTime date) {
  if (isArchived) return false;
  if (frequencyType == HabitFrequencyType.daily) return true;
  return targetWeekdays.contains(date.weekday);
}
```

---

### 2.2 `HabitCompletion`
Tracks a discrete completion event on a calendar day.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique completion ID (`{habitId}_{dateKey}`) |
| `habitId` | `String` | Foreign key referencing `Habit.id` |
| `dateKey` | `String` | ISO calendar date string (`YYYY-MM-DD`) |
| `completedAt` | `DateTime` | Exact timestamp when marked complete |

*Design Decision:* Using a normalized `dateKey` (`YYYY-MM-DD`) prevents timezone offsets from shifting completion records across midnight boundaries when querying daily history.

---

### 2.3 `DayProgress`
Lightweight presentation model representing day status in the weekly rhythm ribbon.

| Field | Type | Description |
| :--- | :--- | :--- |
| `date` | `DateTime` | Day anchor |
| `dateKey` | `String` | Normalized date string (`YYYY-MM-DD`) |
| `dayLabel` | `String` | Mon–Sun initial ("M", "T", "W", "T", "F", "S", "S") |
| `completedCount` | `int` | Number of scheduled habits completed |
| `totalDueCount` | `int` | Total habits scheduled for this day |
| `isToday` | `bool` | Whether this is the current device date |
| `isFuture` | `bool` | Whether this day lies in the future |

---

## 3. Business Logic & Algorithms

### 3.1 Unbroken Streak Calculation Algorithm
Calculates continuous adherence without penalizing non-scheduled days:

1. **Today Evaluation:**
   * If the habit is scheduled today and completed, streak starts at 1; check walks backward starting from yesterday.
   * If scheduled today but not yet completed, the streak remains unbroken if yesterday was completed; check walks backward starting from yesterday.
   * If not scheduled today (e.g., weekend for a Mon–Fri habit), check walks backward starting from yesterday.
2. **Backward Walk (up to 365 days):**
   * If the habit was **not scheduled** on the day being checked, skip the day without resetting or incrementing the streak.
   * If the habit was **scheduled and completed**, increment streak counter by 1.
   * If the habit was **scheduled and missed**, terminate the loop.

### 3.2 Weekly Rhythm Overview
* Resolves the Monday anchor of the week containing the currently selected date:
  $$\text{Monday} = \text{SelectedDate} - (\text{Weekday} - 1)\text{ days}$$
* Generates a 7-day projection evaluating active scheduled habits and matches against recorded completions.

---

## 4. Proposed JSON REST API Contracts

### Base URL: `/api/v1`

### 4.1 `GET /habits`
Retrieve all habits.
* **Query Parameters:**
  * `include_archived` (optional, bool, default `false`)
* **Response (200 OK):**
```json
[
  {
    "id": "h_1710928347120",
    "title": "Morning stillness",
    "description": "10 minutes of quiet observation and breathing",
    "frequency_type": "daily",
    "target_weekdays": [1, 2, 3, 4, 5, 6, 7],
    "color_hex": "#55614E",
    "is_archived": false,
    "created_at": "2026-11-12T07:00:00.000Z",
    "archived_at": null
  }
]
```

### 4.2 `POST /habits`
Create a new habit.
* **Request Body:**
```json
{
  "title": "Deep focus block",
  "description": "90 minutes uninterrupted craft",
  "frequency_type": "weekdays",
  "target_weekdays": [1, 2, 3, 4, 5],
  "color_hex": "#744127"
}
```
* **Response (201 Created):** Full `Habit` JSON object with server-assigned `id`.

### 4.3 `PUT /habits/:id`
Update an existing habit definition.
* **Request Body:** Full `Habit` JSON object.
* **Response (200 OK):** Updated `Habit` object.

### 4.4 `PATCH /habits/:id/archive`
Archive a habit (soft delete).
* **Response (200 OK):** `{"id": "h_...", "is_archived": true, "archived_at": "..."}`

### 4.5 `PATCH /habits/:id/unarchive`
Restore an archived habit.
* **Response (200 OK):** `{"id": "h_...", "is_archived": false, "archived_at": null}`

### 4.6 `DELETE /habits/:id`
Permanently remove a habit and its completions.
* **Response (204 No Content)**

### 4.7 `GET /completions`
Retrieve completion records for a date range.
* **Query Parameters:**
  * `start_date` (optional, `YYYY-MM-DD`)
  * `end_date` (optional, `YYYY-MM-DD`)
  * `habit_id` (optional, string)
* **Response (200 OK):**
```json
[
  {
    "id": "h_1710928347120_2026-11-19",
    "habit_id": "h_1710928347120",
    "date_key": "2026-11-19",
    "completed_at": "2026-11-19T08:14:22.000Z"
  }
]
```

### 4.8 `POST /habits/:id/completions`
Mark habit complete on a specific calendar date.
* **Request Body:**
```json
{
  "date_key": "2026-11-19"
}
```
* **Response (201 Created):** Created `HabitCompletion` record.

### 4.9 `DELETE /habits/:id/completions/:date_key`
Undo habit completion for a specific calendar date.
* **Response (204 No Content)**

---

## 5. Local Persistence Specification

* **Storage Engine:** `SharedPreferences`
* **Storage Keys:**
  * `tend_habits_v1`: JSON string list containing serialized `Habit` records.
  * `tend_completions_v1`: JSON string list containing serialized `HabitCompletion` records.
* **Migration Strategy:** The `_v1` suffix isolates data structures. Future schema migrations bump the version key, migrating legacy records seamlessly on startup.

---

## 6. Design System Tokens (Warm Caramel & Espresso)

Matched to the Tend brand identity:

* **Surface:** `#F9EFE7` (Creamy linen paper tint)
* **Wordmark / Ink:** `#3B2317` (Deep roasted espresso)
* **Caramel Primary:** `#744127` (Dark fold), `#835136` (Core), `#B97B54` (Midtone), `#D39368` (Highlight)
* **Sage Secondary:** `#55614E` (Muted olive sage)
* **Hairline Borders:** `#E2D6CB` / `#DACDC0`
* **Typography:** Newsreader (Editorial serif headlines) and Manrope (Geometric sans-serif body and labels)
