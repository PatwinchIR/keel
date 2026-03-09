import Foundation

// MARK: - Jeff Nippard Full Body 5x/Week Program Template

struct JeffNippardTemplate {
    static let blueprint: TemplateBlueprint = {
        let blocks = [
            BlockBlueprint(name: "Foundation", weekStart: 1, weekEnd: 4, description: "Build a base with moderate intensity and volume"),
            BlockBlueprint(name: "Intensification", weekStart: 5, weekEnd: 8, description: "Push intensity with topset/backoff structures"),
            BlockBlueprint(name: "Deload", weekStart: 9, weekEnd: 9, description: "Reduce volume and intensity to recover"),
            BlockBlueprint(name: "AMRAP", weekStart: 10, weekEnd: 10, description: "Test your limits with AMRAP finals")
        ]

        let weeks = (1...10).map { weekNumber in
            WeekBlueprint(weekNumber: weekNumber, workouts: [
                day1Lower(week: weekNumber),
                day2Chest(week: weekNumber),
                day3Back(week: weekNumber),
                day4Lower2(week: weekNumber),
                day5Delts(week: weekNumber)
            ])
        }

        return TemplateBlueprint(
            name: "Jeff Nippard Full Body 5x",
            description: "A 10-week full body program training 5 days per week with percentage-based progression on the four main compound lifts. Includes foundation, intensification, and deload/AMRAP blocks.",
            totalWeeks: 10,
            defaultTrainingDays: [.monday, .tuesday, .wednesday, .friday, .saturday],
            blocks: blocks,
            weeks: weeks
        )
    }()

    // MARK: - Block Helpers

    private static let isBlock2: Set<Int> = [5, 6, 7, 8]
    private static let deloadWeek = 9

    // MARK: - Day 1: Lower Focused Full Body (Squat Primary)

    private static func day1Lower(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Back Squat
        let squatExercises = squatForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: squatExercises)

        // Accessories
        let rpe = week == deloadWeek ? "RPE6" : "RPE8"
        let setReduction = week == deloadWeek ? 1 : 0

        exercises.append(ExerciseBlueprint(
            name: "Lying Leg Curl",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Control the eccentric, squeeze hamstrings at peak contraction",
            substitutions: ["Seated leg curl", "Sliding leg curl"]
        )); idx += 1

        if isBlock2.contains(week) || week > 8 {
            exercises.append(ExerciseBlueprint(
                name: "Single-Leg Leg Press",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Full range of motion, don't lock out knees",
                substitutions: ["Assisted pistol squat", "DB step-up"]
            )); idx += 1
        } else {
            exercises.append(ExerciseBlueprint(
                name: "Leg Extension",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Squeeze quads at the top, control the negative",
                substitutions: ["Sissy squat", "Goblet squat"]
            )); idx += 1
        }

        exercises.append(ExerciseBlueprint(
            name: "Standing Calf Raise",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "12",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Full stretch at the bottom, pause at the top",
            substitutions: ["Seated calf raise", "Leg press calf press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "DB Incline Press",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "30-degree incline, squeeze chest at the top",
            substitutions: ["Barbell incline press", "Deficit push-up"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Ab Wheel Rollout",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Brace core, extend as far as controllable, don't let hips sag",
            substitutions: ["Long-lever plank", "Plank", "Hollow body hold"]
        )); idx += 1

        return WorkoutBlueprint(name: "Lower Focused Full Body", dayIndex: 0, exercises: exercises)
    }

    // MARK: - Day 2: Chest Focused Full Body (Bench Primary)

    private static func day2Chest(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Bench Press
        let benchExercises = benchForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: benchExercises)

        let rpe = week == deloadWeek ? "RPE6" : "RPE8"
        let setReduction = week == deloadWeek ? 1 : 0

        exercises.append(ExerciseBlueprint(
            name: "Low Incline DB Press",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "15-20 degree incline, focus on upper chest squeeze",
            substitutions: ["Low incline machine press", "Low incline barbell press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Low to High Cable Flye",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Cables set low, arc upward, squeeze at peak",
            substitutions: ["Pec deck", "DB flye"]
        )); idx += 1

        if isBlock2.contains(week) || week > 8 {
            exercises.append(ExerciseBlueprint(
                name: "Weighted Pullup",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "2-4 min",
                notes: "Full hang to chin over bar, control the descent",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"]
            )); idx += 1
        } else {
            exercises.append(ExerciseBlueprint(
                name: "Pronated Pulldown",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Pull to upper chest, squeeze lats, control the eccentric",
                substitutions: ["Pull-up", "Supinated pulldown"]
            )); idx += 1
        }

        exercises.append(ExerciseBlueprint(
            name: "EZ Bar Skull Crusher",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Lower to forehead, keep elbows tucked, full extension at top",
            substitutions: ["Floor press", "Pin press", "JM press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Hanging Leg Raise",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "12",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Posterior pelvic tilt at the top, control the descent",
            substitutions: ["Captain's chair crunch", "Reverse crunch"]
        )); idx += 1

        return WorkoutBlueprint(name: "Chest Focused Full Body", dayIndex: 1, exercises: exercises)
    }

    // MARK: - Day 3: Back Focused Full Body (All RPE-Based)

    private static func day3Back(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        let rpe8 = week == deloadWeek ? "RPE6" : "RPE8"
        let rpe7 = week == deloadWeek ? "RPE5" : "RPE7"
        let setReduction = week == deloadWeek ? 1 : 0

        if isBlock2.contains(week) || week > 8 {
            exercises.append(ExerciseBlueprint(
                name: "Chin-Up",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "6-8",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "2-4 min",
                notes: "Supinated grip, full hang to chin over bar, control descent",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"]
            )); idx += 1
        } else {
            exercises.append(ExerciseBlueprint(
                name: "Weighted Pullup",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "6-8",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "2-4 min",
                notes: "Full hang to chin over bar, control the descent",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"]
            )); idx += 1
        }

        if isBlock2.contains(week) || week > 8 {
            exercises.append(ExerciseBlueprint(
                name: "Pendlay Row",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "2-4 min",
                notes: "Bar from floor each rep, explosive pull, controlled lower",
                substitutions: ["Chest-supported T-bar row (pronated grip)", "Seal row / Helms row"]
            )); idx += 1
        } else {
            exercises.append(ExerciseBlueprint(
                name: "Humble Row",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "2-4 min",
                notes: "45-degree torso angle, pull to lower chest, squeeze shoulder blades",
                substitutions: ["Chest-supported T-bar row (pronated grip)", "Seal row / Helms row"]
            )); idx += 1
        }

        if isBlock2.contains(week) || week > 8 {
            exercises.append(ExerciseBlueprint(
                name: "Banded Chest-Supported T-Bar Row",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "1-2 min",
                notes: "Chest on pad, squeeze lats at peak contraction",
                substitutions: ["DB row"]
            )); idx += 1
        } else {
            exercises.append(ExerciseBlueprint(
                name: "Cable Seated Row",
                orderIndex: idx,
                workingSets: 3 - setReduction,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe8,
                restPeriod: "1-2 min",
                notes: "Pull to lower chest, squeeze shoulder blades together",
                substitutions: ["DB row"]
            )); idx += 1
        }

        exercises.append(ExerciseBlueprint(
            name: "Rope Face Pull",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe7,
            restPeriod: "1-2 min",
            notes: "Pull to face, externally rotate at end, squeeze rear delts",
            substitutions: ["Reverse DB flye", "Reverse cable crossover"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "DB Lateral Raise",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Slight forward lean, lead with elbows, control the negative",
            substitutions: ["Machine lateral raise", "Egyptian lateral raise"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Hammer Curl",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Neutral grip, squeeze brachialis at the top",
            substitutions: ["EZ bar pronated curl", "Rope hammer curl"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Bicycle Crunch",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Opposite elbow to knee, full extension on the straight leg",
            substitutions: []
        )); idx += 1

        return WorkoutBlueprint(name: "Back Focused Full Body", dayIndex: 2, exercises: exercises)
    }

    // MARK: - Day 4: Lower Focused Full Body 2 (Deadlift Primary)

    private static func day4Lower2(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Deadlift
        let deadliftExercises = deadliftForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: deadliftExercises)

        let rpe = week == deloadWeek ? "RPE6" : "RPE8"
        let setReduction = week == deloadWeek ? 1 : 0

        exercises.append(ExerciseBlueprint(
            name: "Leg Press",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Full depth, don't lock out knees, controlled tempo",
            substitutions: ["Goblet squat", "Walking lunge"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "RDL",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "8",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "2-4 min",
            notes: "Hinge at hips, soft knees, stretch hamstrings, bar close to body",
            substitutions: ["Stiff leg deadlift", "Block pull (4\")"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Seated Hip Abduction",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Squeeze glutes at full abduction, control the return",
            substitutions: ["Lateral band walk"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Eccentric-Accentuated Standing Calf Raise",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "3-second eccentric, full stretch at bottom, pause at top",
            substitutions: ["Slow-eccentric leg press toe press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Cable Crunch",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe,
            restPeriod: "1-2 min",
            notes: "Curl ribcage toward pelvis, don't flex at the hips",
            substitutions: ["Bodyweight crunch", "V sit-up", "Bicycle crunch"]
        )); idx += 1

        return WorkoutBlueprint(name: "Lower Focused Full Body 2", dayIndex: 3, exercises: exercises)
    }

    // MARK: - Day 5: Deltoid Focused Full Body (OHP Primary)

    private static func day5Delts(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: OHP
        let ohpExercises = ohpForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: ohpExercises)

        let rpe8 = week == deloadWeek ? "RPE6" : "RPE8"
        let rpe7 = week == deloadWeek ? "RPE5" : "RPE7"
        let setReduction = week == deloadWeek ? 1 : 0

        exercises.append(ExerciseBlueprint(
            name: "Arnold Press",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Rotate palms from facing you to forward as you press, full ROM",
            substitutions: ["DB seated shoulder press", "Machine shoulder press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Cable Rope Upright Row",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "12",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Pull to chin height, elbows high and wide, squeeze delts",
            substitutions: ["Machine lateral raise", "Face pull"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Reverse Pec Deck",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "15",
            loadType: .rpe,
            rpeTarget: rpe7,
            restPeriod: "1-2 min",
            notes: "Squeeze rear delts, control the negative, slight pause at peak",
            substitutions: ["Reverse cable flye"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Dip",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "8",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "2-4 min",
            notes: "Slight forward lean for chest, upright for triceps, full depth",
            substitutions: ["Assisted dip", "Machine dip", "Close-grip bench press"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "Supinated EZ Bar Curl",
            orderIndex: idx,
            workingSets: 3 - setReduction,
            targetReps: "10",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "Supinated grip on inner camber, squeeze biceps at top",
            substitutions: ["DB curl", "Cable curl"]
        )); idx += 1

        exercises.append(ExerciseBlueprint(
            name: "EZ Bar Curl 21s",
            orderIndex: idx,
            workingSets: week == deloadWeek ? 0 : 1,
            targetReps: "7/7/7",
            loadType: .rpe,
            rpeTarget: rpe8,
            restPeriod: "1-2 min",
            notes: "7 reps bottom half, 7 reps top half, 7 reps full range",
            substitutions: ["DB curl 21s", "Cable curl 21s"]
        )); idx += 1

        return WorkoutBlueprint(name: "Deltoid Focused Full Body", dayIndex: 4, exercises: exercises)
    }

    // MARK: - Primary Lift Builders

    // MARK: Back Squat

    private static func squatForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Sit back and down, 15\u{00B0} toe flare, drive knees out laterally"
        let subs = ["Hack squat", "Smith machine squat", "Leg press + 15 reps back extensions"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.775,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "6", loadType: .percentage, percentage: 0.775,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            // Topset: 87.5% x3-5 x1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "3-5", loadType: .percentage, percentage: 0.875,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 75% x5 x2
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            // Topset: 90% x2 x1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 85% x3 x2
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            // Topset: 80% x6-8 x1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "6-8", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 70% x8 x2
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "8", loadType: .percentage, percentage: 0.70,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            // Topset: 92.5% x2 x1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.925,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 85% x2 x2
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "2", loadType: .percentage, percentage: 0.85,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            // Topset: 90% AMRAP x1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 75% x6 x2
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Bench Press

    private static func benchForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Retract scapulae, arch upper back, leg drive through floor"
        let subs = ["DB press", "Machine chest press", "Smith machine bench press"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.875,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "10", loadType: .percentage, percentage: 0.75,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, warmupSets: 2, workingSets: 3,
                targetReps: "4", loadType: .percentage, percentage: 0.70,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            // Topset: 90% AMRAP x1
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 75% x5 x2
            result.append(ExerciseBlueprint(
                name: "Barbell Bench Press", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .bench, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Deadlift

    private static func deadliftForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Brace hard, push floor away, keep bar path straight"
        let subs = ["Sumo deadlift"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.875,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            // Topset: 90% x2 x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 80% x2 x3
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "2", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            // Topset: 85% x4 x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "4", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 75% x4 x3
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "4", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            // Topset: 80% x6 x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "6", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 70% x6 x3
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "6", loadType: .percentage, percentage: 0.70,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            // Topset: 95% x2 x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.95,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 85% x3 x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 1,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 2, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            // Topset: 90% AMRAP x1
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: 75% x5 x2
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Overhead Press

    private static func ohpForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Squeeze glutes, stack wrists over elbows, press slightly back"
        let subs = ["Seated barbell overhead press"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.65,
                percentageOf: .ohp, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.775,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.675,
                percentageOf: .ohp, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "8", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.65,
                percentageOf: .ohp, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10:
            // 75-80% x10 x4
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.775,
                percentageOf: .ohp, rpeTarget: "75-80%", restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }
}
