# Tend — Mindful Habits & Rhythms

Tend is a daily habit and rhythm application rooted in Japanese *wabi-sabi* aesthetics and Scandinavian functionalism. Built with Flutter, it emphasizes calm, deliberate attention and gentle consistency over aggressive gamification and vanity metrics.

* **GitHub Repository:** [https://github.com/saad-ibra/Tend](https://github.com/saad-ibra/Tend)
* **Tested AI Provider:** Groq Cloud (`llama-3.3-70b-versatile` / `llama-3.1-8b-instant`) — verified end-to-end with structured JSON outputs.
* **Fallback AI Providers:** Google Gemini (`gemini-1.5-flash` / `gemini-2.0-flash`) and an on-device deterministic heuristics engine.

---

## Key Features

### 1. Daily Rhythms & Habit Tracker (Home)
* **Custom Recurrence Schedules:** Flexible daily or specific weekday intervals (e.g. Mon–Fri vs. weekend rituals).
* **Weekly Progress Ribbon:** 7-day rhythmic visualizer tracking scheduled versus tended habits.
* **Non-Punitive Streaks:** Grace-aware streak calculations that respect non-scheduled days and biological rhythm recovery.
* **Archival Vault:** Soft-deletion preserves complete completion history while keeping active views focused.

### 2. Daily Mood & Energy Check-in
* **Wabi-Sabi Scales:** Evaluates affective valence (Heavy $\rightarrow$ Radiant) and vitality (Depleted $\rightarrow$ Vibrant) on 1–5 scales.
* **Voice-Dictated Reflections:** Real-time speech dictation for mindful journaling with customizable mood and energy tags.
* **Contextual Tags:** Mindful tagging (`#Stillness`, `#Nature`, `#Sleep`, `#DeepWork`).
* **Responsive Layout:** Adaptive tag wrapping prevents viewport overflow across all screen densities.

### 3. Multi-Provider AI Habit Coach (Center Footer Action)
* **Pristine Wabi-Sabi Center Button:** The central elevated floral acoustic button opens the AI Habit Coach with tactile breathing animations and no distracting overlay icons.
* **Navigation & Stability:** Includes debounced navigation safety, preloaded conversations, and complete back navigation controls to seamlessly return to Home.
* **Multi-Session Management:** Save conversations, start new chats, switch between active sessions, pin important threads to top, archive completed reflections, rename, and delete sessions.
* **Context-Aware Coaching:** Synthesizes actual completion rates, streaks, and mood data into empathetic, actionable guidance.
* **Actionable Proposals:** Generates structured habit mutations (`create_habit` or `modify_habit`) requiring human confirmation before execution.
* **Bottom Model Indicator:** Active AI model badge (`Groq Llama 3.3 70B`, `Gemini 1.5 Flash`, or `Local Intelligence`) sits directly above the message text field with one-tap configuration access.
* **Three-Tier Inference Engine:**
  1. *Groq Cloud (Tested & Recommended):* Ultra-fast Llama 3.3 70B inference with high throughput and instant free keys.
  2. *Google Gemini Cloud:* Direct client support for Gemini 1.5/2.0 Flash and Pro keys with auto model sequencing.
  3. *On-Device Deterministic Engine:* Offline heuristic providing instant guidance without connectivity or credentials.
* **Clean JSON Parser:** Automatically removes markdown backticks and prefaces returned by LLMs to prevent parsing crashes.

### 4. Custom App Icon
* **Custom Brand Emblem:** Extracted and cropped from Tend's brand emblem (removing the 'tend' text) on a serene `#FBF9F5` surface.
* **Adaptive Android Icons:** Full adaptive icon support (`mipmap-anydpi-v26`) with separate foreground emblem and background layers across all densities (mdpi to xxxhdpi), plus legacy and round icon support.
* **iOS App Icons:** Generated complete iOS icon set matching App Store marketing specifications.

### 5. Mindful Readings (Feed — Coming Soon)
* Serene placeholder reserved for curated contemplative essays and seasonal literature without social media clutter.

### 6. Rhythm Circles (Network — Coming Soon)
* Quiet peer accountability and shared rhythm spaces currently being crafted for gentle companion presence without toxic leaderboards.

### 7. Mindful Calendar & Ledger (Days)
* **Monthly Visual Grid:** Interactive calendar grid showing color-coded completion dots and mood indicators.
* **Day Inspector:** Inspect completed rhythms and inner weather check-ins for any historical date.
* **Reflections Journal:** Chronological journal stream displaying 7-day affective trends.

---

## AI Provider Configuration

You can configure your preferred AI provider in **Profile $\rightarrow$ AI Habit Coach Engine**:

### Option 1: Groq API (Recommended — 100% Free & Fast)
1. Get a free API key at [console.groq.com/keys](https://console.groq.com/keys) (takes 30 seconds, no credit card required).
2. Paste the key (`gsk_...`) into **Groq API Key** and tap **Save Groq Key**.
3. Tend uses `llama-3.3-70b-versatile` with sub-second response times.

### Option 2: Google Gemini API (Free or Paid)
1. Get a free or paid API key at [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Paste the key (`AIzaSy...`) into **Gemini API Key** and tap **Save Gemini Key**.
3. Tend automatically uses `gemini-1.5-flash` with automatic fallback to `gemini-2.0-flash` or `gemini-1.5-pro`.

### Option 3: On-Device Engine (No Key Required)
* If no key is entered, Tend automatically runs its on-device deterministic engine, providing instant advice based on your actual habit data.

---

## Test & Build Verification

### Static Analysis
```bash
flutter analyze
# Result: No issues found! (0 warnings, 0 errors)
```

### Automated Test Suite
```bash
flutter test
# Result: 49 unit and widget tests passing across all domains (100% pass rate)
```

### Android Release APK Build
```bash
flutter build apk --release --no-tree-shake-icons
# Output binary: build/app/outputs/flutter-apk/app-release.apk
```

---

## Documentation

Full architectural decisions, domain models, algorithms, and proposed REST API contracts are documented in:
* `DOCUMENTATION.md`
