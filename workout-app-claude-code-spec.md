# Keel — Claude Code Spec

## What This Is
A personal iOS app to replace my Jeff Nippard Full Body 5x/week spreadsheet. Just for me — not shipping to the App Store. Built with SwiftUI + SwiftData. Will sideload via Xcode (free Apple ID for now, $99/yr developer account later if I stick with it).

The app is **program-flexible** — Jeff's 5x program ships as a pre-loaded template, but the user can fully customize it or create entirely new programs from scratch. Programs can be saved as reusable templates.

## My Workflow
- I currently train 5 days/week: Mon, Tue, Wed, Fri, Sat. Thu and Sun are rest days. But the schedule is configurable — any days, any number of workouts per week.
- The program runs 10 weeks in 3 blocks:
  - **Block 1 (Weeks 1–4):** Foundation phase. Linear RPE progression, percentage-based loads on the big 4 lifts.
  - **Block 2 (Weeks 5–8):** Intensification. Introduces topset/backoff structure for squat and deadlift. New exercises swap in (chin-ups replace pulldowns, pendlay rows replace humble rows, etc.)
  - **Block 3 (Weeks 9–10):** Week 9 is deload (everything at RPE6), Week 10 is AMRAP testing at 90% 1RM on squat, bench, deadlift. OHP gets a percentage range (75-80%).
- After Week 10, I use an online 1RM calculator from my AMRAP results, manually update my 1RMs, and restart the cycle.

## Current 1RMs (lbs)
- Squat: 337
- Bench: 254
- Deadlift: 424
- OHP: 160

## The 5 Workout Types (per week)
Each week has 5 workouts, always in this order:
1. **Lower Focused Full Body** — Squat is the primary %RM lift
2. **Chest Focused Full Body** — Bench is the primary %RM lift
3. **Back Focused Full Body** — Weighted pull-ups + rows (RPE-based, no %RM)
4. **Lower Focused Full Body 2** — Deadlift is the primary %RM lift
5. **Deltoid Focused Full Body** — OHP is the primary %RM lift

## Per-Exercise Data (what the spreadsheet tracks)
Each exercise row has:
- **Exercise name** (e.g., "BACK SQUAT", "[TOPSET] BACK SQUAT", "[BACK OFF] BACK SQUAT")
- **Warmup sets** (integer, 0–3)
- **Working sets** (integer, 1–5)
- **Reps / Duration** — Can be: an integer (4), a range ("3-5"), a fraction ("15/15" for dropsets), a compound ("10+2" for cheat reps), "AMRAP", "RPE only", or a split ("7/7/7" for 21s)
- **Load** — Either:
  - A formula: `MROUND(1RM * percentage, 5)` for the big 4 lifts (rounds to nearest 5 lbs)
  - `None` for accessories (user picks weight based on RPE)
- **RPE / %** — Either:
  - A decimal (0.775 = 77.5% of 1RM) for percentage-based exercises
  - A string ("RPE7", "RPE8", "RPE9", "RPE10") for RPE-based exercises
  - A range string ("75-80%") in week 10 for OHP
- **Rest** — String like "2-4 min", "1-2 min", "3-5 min"
- **Notes** — Coaching cue string (e.g., "Sit back and down, 15° toe flare, drive your knees out laterally")

## Percentage Progression Across Weeks
The big 4 lifts follow specific percentage progressions. Here's the full map:

### Back Squat (% of squat 1RM)
- W1: 77.5% ×4r ×4s | W2: 77.5% ×6r ×3s | W3: 80% ×4r ×4s | W4: 80% ×5r ×3s
- W5: Topset 87.5% ×3-5r ×1s + Backoff 75% ×5r ×2s
- W6: Topset 90% ×2r ×1s + Backoff 85% ×3r ×2s
- W7: Topset 80% ×6-8r ×1s + Backoff 70% ×8r ×2s
- W8: Topset 92.5% ×2r ×1s + Backoff 85% ×2r ×2s
- W9 (deload): 75% ×4r ×4s
- W10 (AMRAP): Topset 90% AMRAP ×1s + Backoff 75% ×6r ×2s

### Bench Press (% of bench 1RM)
- W1: 85% ×3r ×3s | W2: 80% ×5r ×3s | W3: 85% ×3r ×3s | W4: 80% ×5r ×3s
- W5: 87.5% ×3r ×3s | W6: 85% ×5r ×3s | W7: 75% ×10r ×3s | W8: 90% ×2r ×4s
- W9 (deload): Day1 70% ×4r ×3s, Day5 80% ×3r ×3s, plus 85% ×2r ×3s on deltoid day
- W10 (AMRAP): 90% AMRAP ×1s + Backoff 75% ×5r ×2s

### Deadlift (% of deadlift 1RM)
- W1: 85% ×2r ×4s | W2: 80% ×5r ×3s | W3: 87.5% ×2r ×4s | W4: 80% ×5r ×3s
- W5: Topset 90% ×2r ×1s + Backoff 80% ×2r ×3s
- W6: Topset 85% ×4r ×1s + Backoff 75% ×4r ×3s
- W7: Topset 80% ×6r ×1s + Backoff 70% ×6r ×3s
- W8: Topset 95% ×2r ×1s + Backoff 85% ×3r ×1s
- W9 (deload): Day2 75% ×3r ×3s, Day4 80% ×2r ×3s
- W10 (AMRAP): 90% AMRAP ×1s + Backoff 75% ×5r ×2s

### OHP (% of OHP 1RM)
- W1: 75% ×6r ×4s | W2: 65% ×10r ×4s | W3: 77.5% ×6r ×4s | W4: 67.5% ×10r ×4s
- W5: 80% ×6r ×4s | W6: 75% ×8r ×4s | W7: 65% ×10r ×4s | W8: 80% ×5r ×4s
- W9 (deload): 75% ×6r ×4s
- W10: 75-80% ×10r ×4s

## Data Model

### Program (an active running instance of a training program)
- id: UUID
- name: String (e.g. "Jeff Nippard Full Body 5x")
- unit: enum (lbs | kg)
- createdAt: Date
- currentWeek: Int
- totalWeeks: Int (e.g. 10 — configurable per program)
- currentCycleNumber: Int (tracks how many times through the program)
- trainingDays: [DayOfWeek] (e.g. [.mon, .tue, .wed, .fri, .sat] — fully configurable)
- blocks: [Block]
- templateId: UUID? (reference to the template this was created from, if any)
- isActive: Bool (only one program active at a time)

### Block (a phase within a program)
- id: UUID
- name: String (e.g. "Foundation", "Intensification", "Deload/AMRAP")
- weekRange: ClosedRange<Int> (e.g. 1...4)
- description: String? (optional notes about the block's purpose)

### ProgramTemplate (a saved, reusable program blueprint)
- id: UUID
- name: String
- description: String?
- totalWeeks: Int
- defaultTrainingDays: [DayOfWeek]
- blocks: [Block]
- weeks: [Week] (the full exercise/set/rep structure)
- isBuiltIn: Bool (true for Jeff's pre-loaded template, false for user-created)
- createdAt: Date

### OneRepMax
- id: UUID
- exercise: enum (squat | bench | deadlift | ohp)
- weight: Double
- date: Date
- cycleNumber: Int (which cycle this was measured in)
- note: String? (e.g., "AMRAP: 5 reps at 305")

### Week
- weekNumber: Int
- blockId: UUID (references which Block this week belongs to)
- workouts: [Workout]

### Workout
- id: UUID
- name: String (e.g., "Lower Focused Full Body", "Chest Focused Full Body")
- weekNumber: Int
- dayIndex: Int (0-based index into the program's trainingDays array, e.g. 0 = first training day, 1 = second, etc.)
- exercises: [Exercise]
- isCompleted: Bool
- completedAt: Date?

### Exercise
- id: UUID
- name: String
- tag: enum? (topset | backoff | none) — for the [TOPSET]/[BACK OFF] prefix
- warmupSets: Int
- workingSets: Int
- targetReps: String (flexible: "4", "3-5", "15/15", "10+2", "AMRAP", "RPE only", "7/7/7")
- loadType: enum (percentage | rpe)
- percentage: Double? (0.775 = 77.5%, only for big 4)
- percentageOf: enum? (squat | bench | deadlift | ohp)
- rpeTarget: String? ("RPE7", "RPE8", etc.)
- restPeriod: String ("2-4 min")
- notes: String (coaching cue)
- substitutions: [String] — list of alternative exercises the user can swap in (from Jeff's PDF)
- activeSubstitution: String? — if the user has swapped this exercise for an alternative, store the name here. When set, the UI shows this name instead of the default. Loads/reps/RPE stay the same.

### SetLog (actual performance — what I log during the workout)
- id: UUID
- exerciseId: UUID
- setNumber: Int
- setType: enum (warmup | working)
- weight: Double?
- reps: Int?
- rpe: Double? (actual RPE felt)
- isCompleted: Bool
- completedAt: Date?
- note: String? (e.g., "felt heavy", "grip slipped")

### BodyComposition (optional — for body fat tracking data)
- id: UUID
- date: Date
- bodyFat: Double? (percentage)
- bodyWeight: Double? (lbs)
- method: String? (e.g., "DEXA", "calipers", "scale")
- note: String?

## Core Features

### 1. Today's Workout View (Main Screen)
- Shows today's workout based on current week + day of week mapping
- Displays each exercise with: name, warmup/working sets, target reps, calculated load (for %RM exercises), RPE target, rest period, coaching notes
- For %RM exercises, auto-calculate: `round(1RM × percentage / 5) × 5` (round to nearest 5 lbs)
- Tap an exercise to expand into set-by-set logging view
- Check off individual sets as completed
- Rest timer starts automatically when a set is checked off (countdown based on the exercise's rest period)
- When all exercises are checked off, mark workout as complete

### 2. Set Logging
- When tapping into an exercise, show each set (warmup + working) as a row
- Pre-fill weight with calculated load (for %RM) or last session's weight (for RPE-based)
- Pre-fill reps with target reps
- User can adjust weight/reps/RPE as actually performed
- Swipe or tap to mark set complete
- Show previous session's performance for this exercise inline (what you lifted last time)

### 3. Program Overview
- Grid/calendar view showing all 10 weeks × 5 workouts
- Color coding: completed (green), today (blue), upcoming (gray)
- Tap any workout to view its exercises (read-only for future, editable for current)
- Shows current block label (Block 1/2/3)

### 4. 1RM Management
- Screen to view/edit current 1RMs for squat, bench, deadlift, OHP
- History view showing all past 1RMs with dates (for backfilling historical data)
- After each Week 10 AMRAP, prompt user to enter the new 1RM for that lift
- Built-in 1RM calculator using the same formula as strengthlevel.com (Epley: `weight × (1 + reps / 30)`). User inputs the AMRAP weight + reps completed, app shows estimated 1RM, user confirms or adjusts before saving.
- **Important Week 10 flow:** Everything in Week 10 uses the *old* 1RM — both the AMRAP topsets and the backoff sets. After completing an AMRAP, the user opens the built-in calculator, enters weight + reps, and saves the new estimated 1RM. But this new 1RM does NOT affect any remaining Week 10 loads. The rationale: you need another full 10-week cycle to adjust to and grow into the new weight. New 1RMs only take effect when the next cycle starts.
- When all Week 10 AMRAPs are done and new 1RMs saved, prompt user to start a new cycle. All percentage-based loads recalculate for the new cycle using the new 1RMs.

### 5. Progress Charts
- Per-exercise: line chart of estimated 1RM over time (across cycles)
- Per-exercise: volume over time (sets × reps × weight per session)
- Body composition chart (if body fat/weight data exists)
- Support backfilling historical 1RM data with dates

### 6. Apple Health Integration (minimal)
- Write workout summary to HealthKit after completing a workout:
  - Workout type: `.traditionalStrengthTraining`
  - Duration: time from first set checked to last set checked
  - Estimated calories (basic formula or skip)
- Read body weight from HealthKit if available
- DO NOT try to store sets/reps/weight in HealthKit — it doesn't support that

### 7. Program Builder & Templates
- **Start from template:** User can create a new program from a saved template (Jeff's 5x ships as a built-in template)
- **Start from scratch:** User can create a blank program — set name, number of weeks, define blocks, choose training days, then build out each week's workouts and exercises
- **Edit active program:** User can modify an in-progress program — add/remove/reorder exercises, change sets/reps/percentages/RPE, adjust rest periods, rename workouts
- **Per-exercise editing:** For each exercise, user can set: name, warmup sets, working sets, target reps (supports all formats: integer, range, dropset, cheat reps, 21s, AMRAP, RPE only), load type (percentage or RPE), percentage value + which 1RM it references, RPE target, rest period, coaching notes, and substitution list
- **Block management:** User can define training blocks within a program (e.g. "Foundation" weeks 1-4, "Intensification" weeks 5-8), name them, assign week ranges
- **Schedule configuration:** Pick which days of the week to train — any combination, any number of days. The workout order maps to training days by index (workout 1 = first training day, etc.)
- **Save as template:** User can save any program (active or completed) as a reusable template for future cycles
- **Template management:** View, rename, duplicate, or delete saved templates. Built-in templates (Jeff's 5x) cannot be deleted but can be duplicated and modified
- **Duplicate week:** When building a program, user can duplicate a week's structure to another week and then tweak it (saves time since many weeks are similar)

### 8. Exercise Substitutions
- Long-press any exercise in the workout view to see available substitutions
- Show a bottom sheet with the list of alternatives from Jeff's PDF
- Tapping a substitute swaps that exercise for the current workout (and future weeks)
- A small icon/badge indicates when a substitution is active
- User can revert to the original exercise anytime via the same long-press menu
- Substitution only changes the exercise name — sets, reps, RPE, rest all stay the same
- For %RM exercises (big 4), substitutions should carry a warning that percentage-based loading may not apply to the substitute movement

## Design Language
Vibe: **consistency, stoicism, masculine.** Modern and sleek — no playful colors, no rounded bubbly shapes, no gamification badges. This app should feel like a precision instrument, not a toy.

### Color Palette
- **Background:** Near-black (#0A0A0A) with very subtle dark gray surface cards (#141414, #1A1A1A)
- **Primary accent:** Cool white (#F5F5F5) for text and key data
- **Secondary accent:** Muted steel/slate (#8A8A8A) for labels, secondary text, borders
- **Highlight:** Single sharp accent color — cold blue (#4A90D9) or amber (#D4A843) — used sparingly for active states, current set, timers. Pick one, use it everywhere consistently.
- **Success/completion:** Muted green (#2D6A4F) — not bright, just enough to register
- **Warning/PR:** Muted gold (#B8860B) for personal records
- **No reds** unless something is actually wrong (failed set, error state)

### Typography
- **SF Pro Display** (bold/heavy) for numbers, weights, percentages — the data should hit hard
- **SF Pro Text** (regular/medium) for labels and notes
- Monospaced or tabular figures for weight/rep columns so numbers align cleanly
- Large type for the weight you're about to lift — this is the most important number on screen
- Minimal use of ALL CAPS — only for section headers or block labels

### Layout & Components
- **Cards with sharp corners** (0-2pt radius max) — no pill shapes, no heavy rounding
- Thin 1px borders or subtle elevation, not thick outlines
- Generous negative space — let the data breathe
- Grid-aligned, structured layouts — everything on a strict vertical rhythm
- Progress bars over checkboxes where possible (feels more serious)
- Rest timer: large centered countdown, minimal chrome, maybe a thin circular progress ring
- Bottom sheet for exercise details/substitutions — not modals that take over the screen
- Haptic feedback on set completion (UIImpactFeedbackGenerator, medium weight)

### Iconography
- SF Symbols only, weight: medium or semibold
- Minimal icon use — prefer text labels. Icons only where universally understood (play/pause for timer, chevrons for navigation)
- No emoji anywhere in the UI

### Motion
- Subtle, fast transitions (0.2s ease-out)
- No bouncy spring animations
- Sets sliding to "completed" state with a clean fade/shift, not a flashy animation
- Number changes (weight recalculations) should animate with a brief counter roll

### Overall Feel
Think: dark Bloomberg terminal meets a high-end fitness watch. The kind of app where the data is the design. No decoration, no illustration, no onboarding carousel. You open it and your workout is right there.

## UX Priorities (since this is for gym use)
- Large tap targets — usable with one hand, sweaty fingers
- Dark mode default (gym lighting)
- Minimal navigation — today's workout should be 0 taps from launch
- Rest timer should be visible/audible even when phone is locked
- Show coaching notes inline but collapsible (I know most of these by now)
- Offline-first — works without internet at the gym

## What NOT to Build
- No social features
- No AI programming suggestions
- No nutrition tracking
- No App Store submission
- No backend/server — everything is local on-device with SwiftData
- No login/auth

## Tech Stack
- SwiftUI (views)
- SwiftData (persistence)
- HealthKit (workout summary write, body weight read)
- Swift Charts (progress visualization)
- Local notifications (rest timer)
- No third-party dependencies

## Historical Data to Backfill
I have past 1RM data with dates that I want to import. The app should have a way to manually add historical 1RM entries (date + exercise + weight). This lets me see my strength progression even from before the app existed.

I also have granular body fat tracking data that I may want to import — include the BodyComposition model but the UI for this can be minimal (just a list view + add entry + simple chart).

## Exercise Substitutions (from Jeff's PDF)
If a user can't do an exercise due to injury, pain, or equipment, they can swap it for one of these alternatives. The app should let the user long-press an exercise to see available subs and pick one. The swap persists until changed back.

See the substitution map in the section below.

## Exercise Substitution Map

### A–B
- Ab Wheel Rollout → Long-lever plank, Plank, Hollow body hold
- Arnold Press → DB seated shoulder press, Machine shoulder press
- Back Squat → Hack squat, Smith machine squat, Leg press + 15 reps back extensions
- Banded Chest-Supported T-Bar Row → Cable seated row w/ band, Eccentric-accentuated chest-supported T-bar row
- Barbell Bench Press → DB press, Machine chest press, Smith machine bench press
- Barbell Hip Thrust → Glute bridge, DB 45° hyperextension
- Bicycle Crunch → Cable crunch, Bodyweight crunch, V sit-up

### C
- Cable Crunch → Bodyweight crunch, V sit-up, Bicycle crunch
- Cable Pull-Over → Lying DB pullover
- Cable Rope Upright Row → Machine lateral raise, Face pull
- Cable Seated Row → DB row
- Cable Single-Arm Curl → Single arm DB curl
- Chest-Supported T-Bar Row → Chest-supported row, Cable single-arm row

### D
- Deadlift → Sumo deadlift
- Decline Bench Press → Weighted Dip
- Dip → Assisted dip, Machine dip, Close-grip bench press
- DB Incline Press → Barbell incline press, Deficit push-up
- DB Lateral Raise → Machine lateral raise, Egyptian lateral raise
- DB Row → Cable single-arm row, DB chest-supported row

### E–G
- Eccentric-Accentuated Standing Calf Raise → Slow-eccentric leg press toe press
- Egyptian Lateral Raise → DB lateral raise, Machine lateral raise
- EZ Bar Curl 21s → DB curl 21s, Cable curl 21s
- EZ Bar Skull Crusher → Floor press, Pin press, JM press
- Glute Ham Raise → Glute bridge, Reverse hyper, Cable pull-through

### H–L
- Hammer Curl → EZ bar pronated curl, Rope hammer curl
- Hanging Leg Raise → Captain's chair crunch, Reverse crunch
- Humble Row → Chest-supported T-bar row (pronated grip), Seal row / Helms row
- Incline DB Curl → Behind the back cable curl
- Leg Extension → Sissy squat, Goblet squat
- Leg Press → Goblet squat, Walking lunge
- Low Incline DB Press → Low incline machine press, Low incline barbell press
- Low to High Cable Flye → Pec deck, DB flye
- Lying Leg Curl → Seated leg curl, Sliding leg curl

### O–R
- Overhead Press → Seated barbell overhead press
- Overhead Tricep Pressdown → DB overhead triceps extension
- Pronated Pulldown → Pull-up, Supinated pulldown
- Push Up → DB floor press, Machine chest press
- RDL → Stiff leg deadlift, Block pull (4")
- Reverse Pec Deck → Reverse cable flye
- Rope Face Pull → Reverse DB flye, Reverse cable crossover

### S–W
- Seated Hip Abduction → Lateral band walk
- Single-Leg Leg Press → Assisted pistol squat, DB step-up
- Standing Calf Raise → Seated calf raise, Leg press calf press
- Supinated EZ Bar Curl → DB curl, Cable curl
- Swiss Ball Leg Curl → Sliding leg curl, Seated leg curl, Lying leg curl
- T-Bar or Smith Machine Shrug → DB shrug
- Tricep Pressdown → Rope overhead triceps extension, DB kickback
- Weighted Pullup → Lat pulldown, Neutral-grip pull-up

## Future Possibilities (do NOT build yet)
- Personal dashboard that includes other life metrics (finance, etc.)
- Apple Watch companion for rest timer + set logging
- CloudKit sync across devices
- Export data to CSV
- Import program from spreadsheet (parse .xlsx into a template automatically)
