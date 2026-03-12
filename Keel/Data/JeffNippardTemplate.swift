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

    private static let isBlock1: Set<Int> = [1, 2, 3, 4]
    private static let isBlock2: Set<Int> = [5, 6, 7, 8]
    private static let deloadWeek = 9
    private static let amrapWeek = 10

    // MARK: - Day 1: Lower Focused Full Body (Squat Primary)

    private static func day1Lower(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Back Squat
        let squatExercises = squatForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: squatExercises)

        if isBlock2.contains(week) {
            // Block 2: Secondary OHP + Swiss Ball Leg Curl + Chin-Up + EZ Bar Curl + Ab Wheel
            let ohpExercises = secondaryOHPForWeek(week, startIndex: &idx)
            exercises.append(contentsOf: ohpExercises)

            exercises.append(ExerciseBlueprint(
                name: "Swiss Ball Leg Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: week <= 6 ? "RPE7" : "RPE8",
                restPeriod: "1-2 min",
                notes: "Prevent your hips from touching the ground. Dig your heels into the ball",
                substitutions: ["Lying leg curl", "Seated leg curl"],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Chin-Up",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: week <= 6 ? "RPE7" : "RPE8",
                restPeriod: "2-3 min",
                notes: "Supinated (underhand) shoulder width grip, pull with lats",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Supinated EZ Bar Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10+2",
                loadType: .rpe,
                rpeTarget: "RPE10",
                restPeriod: "1-2 min",
                notes: "10 reps with good control + 2 reps with moderate cheating/momentum",
                substitutions: ["DB curl", "Cable curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Ab Wheel Rollout",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: week == 5 ? "6" : "12",
                loadType: .rpe,
                rpeTarget: week <= 6 ? "RPE7" : "RPE8",
                restPeriod: "1-2 min",
                notes: "Squeeze your glutes, don't pull from your arms",
                substitutions: ["Long-lever plank", "Plank", "Hollow body hold"],
                isBodyweight: true
            )); idx += 1

        } else if week == deloadWeek {
            // Deload Day 1: Bench (speed reps) + Lying Leg Curl + Pulldown + Curl + Cable Crunch
            let benchExercises = deloadSecondaryBenchDay1(startIndex: &idx)
            exercises.append(contentsOf: benchExercises)

            exercises.append(ExerciseBlueprint(
                name: "Lying Leg Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your hamstrings to move the weight",
                substitutions: ["Seated leg curl", "Sliding leg curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Pronated Pulldown",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "2-3 min",
                notes: "Pull your elbows down and in",
                substitutions: ["Pull-up", "Supinated pulldown"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Supinated EZ Bar Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Press your pinky into the bar harder than your pointer finger",
                substitutions: ["DB curl", "Cable curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on flexing your spine",
                substitutions: ["Bodyweight crunch", "V sit-up"]
            )); idx += 1

        } else if week == amrapWeek {
            // AMRAP Day 1: DB Incline (RPE5!) + Lying Leg Curl + Pulldown + Curl + Cable Crunch
            exercises.append(ExerciseBlueprint(
                name: "DB Incline Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: "RPE5",
                restPeriod: "2-3 min",
                notes: "Very light weight - avoid interference with bench AMRAP tomorrow",
                substitutions: ["Barbell incline press", "Deficit push-up"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Lying Leg Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your hamstrings to move the weight",
                substitutions: ["Seated leg curl", "Sliding leg curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Pronated Pulldown",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "2-3 min",
                notes: "Pull your elbows down and in",
                substitutions: ["Pull-up", "Supinated pulldown"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Supinated EZ Bar Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE9",
                restPeriod: "1-2 min",
                notes: "Press your pinky into the bar harder than your pointer finger",
                substitutions: ["DB curl", "Cable curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on flexing your spine",
                substitutions: ["Bodyweight crunch", "V sit-up"]
            )); idx += 1

        } else {
            // Block 1: DB Incline + Lying Leg Curl + Pulldown + EZ Bar Curl (dropset) + Hanging Leg Raise
            let rpeProgression: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE9"
                case 4: return "RPE9"
                default: return "RPE8"
                }
            }()
            let rpeModerate: String = {
                switch week {
                case 1, 2: return "RPE6"
                case 3: return "RPE7"
                case 4: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpePulldown: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3: return "RPE7"
                case 4: return "RPE8"
                default: return "RPE7"
                }
            }()

            exercises.append(ExerciseBlueprint(
                name: "DB Incline Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpeProgression,
                restPeriod: "2-3 min",
                notes: "~45 degree incline, mind muscle connection with upper pecs",
                substitutions: ["Barbell incline press", "Deficit push-up"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Lying Leg Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeModerate,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your hamstrings to move the weight",
                substitutions: ["Seated leg curl", "Sliding leg curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Pronated Pulldown",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpePulldown,
                restPeriod: "2-3 min",
                notes: "Pull your elbows down and in",
                substitutions: ["Pull-up", "Supinated pulldown"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Supinated EZ Bar Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15/15",
                loadType: .rpe,
                rpeTarget: week <= 2 ? "RPE9" : "RPE10",
                restPeriod: "1-2 min",
                notes: "Dropset. Drop weight by ~50% on second 15 reps. 30 reps total.",
                substitutions: ["DB curl", "Cable curl"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hanging Leg Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: week <= 2 ? "RPE7" : (week == 3 ? "RPE7" : "RPE8"),
                restPeriod: "1-2 min",
                notes: "Roll hips up as you squeeze lower abs, avoid swinging",
                substitutions: ["Captain's chair crunch", "Reverse crunch"],
                isBodyweight: true
            )); idx += 1
        }

        return WorkoutBlueprint(name: "Lower Focused Full Body", dayIndex: 0, exercises: exercises)
    }

    // MARK: - Day 2: Chest Focused Full Body (Bench Primary)

    private static func day2Chest(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Bench Press
        let benchExercises = benchForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: benchExercises)

        if isBlock2.contains(week) {
            // Block 2: Low Incline DB Press + Hip Thrust/RDL + DB Row + DB Lateral Raise + Overhead Tricep Ext + Shrug
            let rpe = week <= 6 ? "RPE7" : "RPE8"

            exercises.append(ExerciseBlueprint(
                name: "Low Incline DB Press",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: week == 5 ? "RPE8" : rpe,
                restPeriod: "1-2 min",
                notes: "15° bench angle. Tuck your elbows",
                substitutions: ["Low incline machine press", "Low incline barbell press"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Barbell Hip Thrust or RDL",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "2-3 min",
                notes: "Hip thrust if glutes are priority, RDL if hamstrings are priority. Focus on mind muscle connection.",
                substitutions: ["Stiff leg deadlift", "Glute bridge"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Dumbbell Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-3 min",
                notes: "Pull the dumbbell to your hip",
                substitutions: ["Cable row", "Chest-supported row"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "DB Lateral Raise",
                orderIndex: idx,
                workingSets: 4,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-3 min",
                notes: "Raise the dumbbell out not up, mind muscle connection with middle fibers",
                substitutions: ["Machine lateral raise", "Cable lateral raise"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Overhead Tricep Extension",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your triceps to move the weight",
                substitutions: ["EZ bar skull crusher", "Tricep pressdown"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hex Bar Shrug",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Shrug up and in, pull shoulders up to ears!",
                substitutions: ["Smith machine shrug", "DB shrug"]
            )); idx += 1

        } else if week == deloadWeek {
            // Deload Day 2: Cable Flye + Deadlift (secondary) + T-Bar Row + Lateral Raise + Pressdown + Shrug
            exercises.append(ExerciseBlueprint(
                name: "Low to High Cable Flye",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Start with your hands out to your sides and palms facing the ceiling",
                substitutions: ["Pec deck", "DB flye"]
            )); idx += 1

            // Secondary Deadlift on Day 2 deload
            exercises.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 2, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "2-3 min",
                notes: "Explosive reps off the floor - should feel light and fast",
                substitutions: ["Sumo deadlift"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Chest-Supported T-Bar Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-3 min",
                notes: "Fully protract at bottom, retract at top",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "DB Lateral Raise",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-3 min",
                notes: "Raise the dumbbell out not up, mind muscle connection with middle fibers",
                substitutions: ["Machine lateral raise", "Cable lateral raise"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Tricep Pressdown",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your triceps to move the weight",
                substitutions: ["EZ bar skull crusher", "Overhead tricep extension"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hex Bar Shrug",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Shrug up and in, pull shoulders up to ears!",
                substitutions: ["Smith machine shrug", "DB shrug"]
            )); idx += 1

        } else if week == amrapWeek {
            // AMRAP Day 2: Cable Flye + Hip Thrust/RDL (RPE5!) + T-Bar Row + Arnold Press + Pressdown + Shrug
            exercises.append(ExerciseBlueprint(
                name: "Low to High Cable Flye",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE9",
                restPeriod: "1-2 min",
                notes: "Start with your hands out to your sides and palms facing the ceiling",
                substitutions: ["Pec deck", "DB flye"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Barbell Hip Thrust or RDL",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE5",
                restPeriod: "2-3 min",
                notes: "Very light weight to avoid interference with deadlift AMRAPs on Day 4",
                substitutions: ["Stiff leg deadlift", "Glute bridge"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Chest-Supported T-Bar Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-3 min",
                notes: "Squeeze your shoulder blades together at the top, let them round forward at the bottom",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Arnold Press",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-3 min",
                notes: "Start with your elbows in front of you and palms facing in. Rotate the dumbbells so that your palms face forward as you press.",
                substitutions: ["DB seated shoulder press", "Machine shoulder press"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Tricep Pressdown",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE9",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your triceps to move the weight",
                substitutions: ["EZ bar skull crusher", "Overhead tricep extension"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hex Bar Shrug",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE10",
                restPeriod: "1-2 min",
                notes: "Shrug up and in, pull shoulders up to ears!",
                substitutions: ["Smith machine shrug", "DB shrug"]
            )); idx += 1

        } else {
            // Block 1: Cable Flye + Hip Thrust/RDL + T-Bar Row + Arnold Press + Tricep Pressdown + Shrug
            let rpeModerate: String = {
                switch week {
                case 1, 2: return "RPE6"
                case 3: return "RPE7"
                case 4: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpeHigh: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE9"
                case 4: return "RPE9"
                default: return "RPE8"
                }
            }()
            let rpeMid: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE7"
                default: return "RPE7"
                }
            }()
            let rpeMid2: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE8"
                default: return "RPE7"
                }
            }()

            exercises.append(ExerciseBlueprint(
                name: "Low to High Cable Flye",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeHigh,
                restPeriod: "1-2 min",
                notes: "Start with your hands out to your sides and palms facing the ceiling, focus on pulling your elbows up and in while rotating your palms to face the floor",
                substitutions: ["Pec deck", "DB flye"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Barbell Hip Thrust or RDL",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpeModerate,
                restPeriod: "2-3 min",
                notes: "Hip thrust if glutes are priority, RDL if hamstrings are priority. Focus on mind muscle connection.",
                substitutions: ["Stiff leg deadlift", "Glute bridge"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Chest-Supported T-Bar Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeModerate,
                restPeriod: "1-3 min",
                notes: "Squeeze your shoulder blades together at the top, let them round forward at the bottom",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Arnold Press",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-3 min",
                notes: "Start with your elbows in front of you and palms facing in. Rotate the dumbbells so that your palms face forward as you press.",
                substitutions: ["DB seated shoulder press", "Machine shoulder press"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Tricep Pressdown",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your triceps to move the weight",
                substitutions: ["EZ bar skull crusher", "Overhead tricep extension"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hex Bar Shrug",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpeModerate,
                restPeriod: "1-2 min",
                notes: "Shrug up and in, pull shoulders up to ears!",
                substitutions: ["Smith machine shrug", "DB shrug"]
            )); idx += 1
        }

        return WorkoutBlueprint(name: "Chest Focused Full Body", dayIndex: 1, exercises: exercises)
    }

    // MARK: - Day 3: Back Focused Full Body (Weighted Pull-Up Primary, RPE-Based)

    private static func day3Back(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        if isBlock1.contains(week) || week == amrapWeek {
            // Block 1 / AMRAP: Weighted Pull-Up + Humble Row + Leg Press + Standing Calf Raise + Cable Rope Upright Row + Hammer Curl
            let rpeMain: String = {
                switch week {
                case 1: return "RPE8"
                case 2, 3, 4: return "RPE9"
                case 10: return "RPE9"
                default: return "RPE8"
                }
            }()
            let rpeMod: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE9"
                case 4: return "RPE9"
                case 10: return "RPE8"
                default: return "RPE8"
                }
            }()
            let rpeLow: String = {
                switch week {
                case 1: return "RPE6"
                case 2: return "RPE6"
                case 3: return "RPE7"
                case 4: return "RPE8"
                case 10: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpeMid: String = {
                switch week {
                case 1, 2, 3: return "RPE7"
                case 4: return "RPE8"
                case 10: return "RPE8"
                default: return "RPE7"
                }
            }()
            let hammerRpe: String = {
                switch week {
                case 1, 2, 3, 4: return "RPE9"
                case 10: return "RPE10"
                default: return "RPE9"
                }
            }()
            let pullupReps: String = {
                switch week {
                case 7: return "10"
                default: return "6"
                }
            }()

            exercises.append(ExerciseBlueprint(
                name: "Weighted Pullup",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: pullupReps,
                loadType: .rpe,
                rpeTarget: rpeMain,
                restPeriod: "2-3 min",
                notes: "1.5x shoulder width grip, pull your chest to the bar",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Humble Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "2-3 min",
                notes: "Pin your lower chest against the top of an incline bench",
                substitutions: ["Chest-supported T-bar row", "Seal row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Leg Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeLow,
                restPeriod: "2-3 min",
                notes: "Low/medium/high foot placement, don't allow your lower back to round",
                substitutions: ["Goblet squat", "Walking lunge"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "1-2 second pause at the bottom of each rep",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Rope Upright Row",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing the upper traps at the top",
                substitutions: ["Machine lateral raise", "Face pull"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hammer Curl",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: hammerRpe,
                restPeriod: "1-2 min",
                notes: "3-second eccentric. Arch the dumbbell out not up, focus on squeezing your forearms",
                substitutions: ["EZ bar pronated curl", "Rope hammer curl"],
                isDumbbell: true
            )); idx += 1

        } else if isBlock2.contains(week) {
            // Block 2: Weighted Pull-Up + Banded T-Bar Row + Single-Leg Leg Press + Eccentric Calf + Upright Row + Cable Single-Arm Curl
            let rpe = week <= 6 ? "RPE7" : "RPE8"
            let pullupSets = week == 5 ? 3 : (week == 7 ? 3 : (week == 6 ? 4 : 4))
            let pullupReps: String = {
                switch week {
                case 5: return "6"
                case 6: return "3"
                case 7: return "10"
                case 8: return "6"
                default: return "6"
                }
            }()
            let pullupRpe = week <= 6 ? "RPE9" : "RPE9"

            exercises.append(ExerciseBlueprint(
                name: "Weighted Pullup",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: pullupSets,
                targetReps: pullupReps,
                loadType: .rpe,
                rpeTarget: pullupRpe,
                restPeriod: "2-3 min",
                notes: "1.5x shoulder width grip, pull your chest to the bar",
                substitutions: ["Lat pulldown", "Neutral-grip pull-up"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Banded Chest-Supported T-Bar Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: week <= 5 ? "RPE8" : rpe,
                restPeriod: "2-3 min",
                notes: "Be explosive at the bottom, drive elbows back hard!",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Single-Leg Leg Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 4,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "2-3 min",
                notes: "Low/medium/high foot placement, don't allow your lower back to round",
                substitutions: ["Assisted pistol squat", "DB step-up"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Eccentric-Accentuated Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Press onto your toes. 4-second eccentric",
                substitutions: ["Slow-eccentric leg press toe press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Rope Upright Row",
                orderIndex: idx,
                workingSets: 4,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing the upper traps at the top",
                substitutions: ["Machine lateral raise", "Face pull"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Single-Arm Curl",
                orderIndex: idx,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Keep your shoulder joint hyperextended (elbow behind torso)",
                substitutions: ["Incline DB curl", "Hammer curl"]
            )); idx += 1

        } else {
            // Deload Day 3: Wide Grip Lat Pulldown + T-Bar Row + Leg Press + Standing Calf + Upright Row + Hammer Curl
            exercises.append(ExerciseBlueprint(
                name: "Wide Grip Lat Pulldown",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "6",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "2-3 min",
                notes: "Pull with your chest to the bar",
                substitutions: ["Pull-up", "Neutral-grip pulldown"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Chest-Supported T-Bar Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "2-3 min",
                notes: "Squeeze your shoulder blades together at the top, let them round forward at the bottom",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Leg Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "2-3 min",
                notes: "Low/medium/high foot placement, don't allow your lower back to round",
                substitutions: ["Goblet squat", "Walking lunge"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "1-2 second pause at the bottom of each rep",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Rope Upright Row",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing the upper traps at the top",
                substitutions: ["Machine lateral raise", "Face pull"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Hammer Curl",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "3-second eccentric. Arch the dumbbell out not up, focus on squeezing your forearms",
                substitutions: ["EZ bar pronated curl", "Rope hammer curl"],
                isDumbbell: true
            )); idx += 1
        }

        return WorkoutBlueprint(name: "Back Focused Full Body", dayIndex: 2, exercises: exercises)
    }

    // MARK: - Day 4: Lower Focused Full Body 2 (Deadlift Primary)

    private static func day4Lower2(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: Deadlift
        let deadliftExercises = deadliftForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: deadliftExercises)

        if isBlock1.contains(week) || week == amrapWeek {
            // Block 1 / AMRAP: Dip + Glute Ham Raise + Leg Extension + Cable Pull-Over + DB Lat Raise + Face Pull + Skull Crusher
            let rpeHigh: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE9"
                case 4: return "RPE9"
                case 10: return "RPE7"
                default: return "RPE8"
                }
            }()
            let rpeMod: String = {
                switch week {
                case 1: return "RPE6"
                case 2: return "RPE7"
                case 3: return "RPE7"
                case 4: return "RPE8"
                case 10: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpeMid: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE7"
                case 10: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpeMid2: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE8"
                case 10: return "RPE8"
                default: return "RPE7"
                }
            }()

            if week == amrapWeek {
                // AMRAP Week 10 Day 4: Decline Bench Press instead of Dip
                exercises.append(ExerciseBlueprint(
                    name: "Decline Bench Press",
                    orderIndex: idx,
                    warmupSets: 2,
                    workingSets: 3,
                    targetReps: "8",
                    loadType: .rpe,
                    rpeTarget: "RPE7",
                    restPeriod: "2-3 min",
                    notes: "Constant tension reps, touch bar to chest",
                    substitutions: ["Dip", "Close-grip bench press"]
                )); idx += 1
            } else {
                exercises.append(ExerciseBlueprint(
                    name: "Dip",
                    orderIndex: idx,
                    warmupSets: 2,
                    workingSets: 3,
                    targetReps: "10",
                    loadType: .rpe,
                    rpeTarget: rpeHigh,
                    restPeriod: "2-3 min",
                    notes: "Tuck your elbows at 45°, lean your torso forward 15°, shoulder width or slightly wider grip",
                    substitutions: ["Assisted dip", "Machine dip", "Close-grip bench press"],
                    isBodyweight: true
                )); idx += 1
            }

            exercises.append(ExerciseBlueprint(
                name: "Glute Ham Raise",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "1-2 min",
                notes: "Keep lower back straight, use hamstrings to curl your body up",
                substitutions: ["Nordic curl", "Swiss ball leg curl"],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Leg Extension",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your quads to move the weight",
                substitutions: ["Sissy squat", "Goblet squat"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Pull-Over",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-3 min",
                notes: "Lean your torso at a 45° angle, focus on pulling the weight straight down, not in",
                substitutions: ["Straight-arm pulldown", "DB pull-over"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "DB Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Raise the dumbbell out not up, mind muscle connection with middle fibers",
                substitutions: ["Machine lateral raise", "Cable lateral raise"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Rope Face Pull",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Pull your elbows up and out, squeeze your shoulder blades together",
                substitutions: ["Reverse DB flye", "Reverse cable crossover"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "EZ Bar Skull Crusher",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeMid,
                restPeriod: "1-2 min",
                notes: "Arc the bar back behind your head, keep constant tension on triceps",
                substitutions: ["Floor press", "Pin press", "JM press"]
            )); idx += 1

        } else if isBlock2.contains(week) {
            // Block 2: Decline Bench + Glute Ham Raise + Leg Extension + Cable Pull-Over + DB Lat Raise + Reverse Pec Deck + Skull Crusher
            let rpe = week <= 6 ? "RPE7" : "RPE8"

            exercises.append(ExerciseBlueprint(
                name: "Decline Bench Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 4,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "2-3 min",
                notes: "Constant tension reps, touch bar to chest",
                substitutions: ["Dip", "Close-grip bench press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Glute Ham Raise",
                orderIndex: idx,
                workingSets: 4,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Keep lower back straight, use hamstrings to curl your body up",
                substitutions: ["Nordic curl", "Swiss ball leg curl"],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Leg Extension",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your quads to move the weight",
                substitutions: ["Sissy squat", "Goblet squat"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Pull-Over",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-3 min",
                notes: "Lean your torso at a 45° angle, focus on pulling the weight straight down, not in",
                substitutions: ["Straight-arm pulldown", "DB pull-over"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "DB Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Raise the dumbbell out not up, mind muscle connection with middle fibers",
                substitutions: ["Machine lateral raise", "Cable lateral raise"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Reverse Pec Deck",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Swing the weight out, not back",
                substitutions: ["Reverse cable flye", "Rope face pull"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "EZ Bar Skull Crusher",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Arc the bar back behind your head, keep constant tension on triceps",
                substitutions: ["Floor press", "Pin press", "JM press"]
            )); idx += 1

        } else {
            // Deload Day 4: Decline Bench + Glute Ham Raise + Leg Extension + Cable Pull-Over + DB Lat Raise + Face Pull + Skull Crusher
            exercises.append(ExerciseBlueprint(
                name: "Decline Bench Press",
                orderIndex: idx,
                warmupSets: 2,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: "RPE7",
                restPeriod: "2-3 min",
                notes: "Constant tension reps, touch bar to chest",
                substitutions: ["Dip", "Close-grip bench press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Glute Ham Raise",
                orderIndex: idx,
                workingSets: 3,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Keep lower back straight, use hamstrings to curl your body up",
                substitutions: ["Nordic curl", "Swiss ball leg curl"],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Leg Extension",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on squeezing your quads to move the weight",
                substitutions: ["Sissy squat", "Goblet squat"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Pull-Over",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-3 min",
                notes: "Lean your torso at a 45° angle, focus on pulling the weight straight down, not in",
                substitutions: ["Straight-arm pulldown", "DB pull-over"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "DB Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Raise the dumbbell out not up, mind muscle connection with middle fibers",
                substitutions: ["Machine lateral raise", "Cable lateral raise"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Rope Face Pull",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Pull your elbows up and out, squeeze your shoulder blades together",
                substitutions: ["Reverse DB flye", "Reverse cable crossover"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "EZ Bar Skull Crusher",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Arc the bar back behind your head, keep constant tension on triceps",
                substitutions: ["Floor press", "Pin press", "JM press"]
            )); idx += 1
        }

        return WorkoutBlueprint(name: "Lower Focused Full Body 2", dayIndex: 3, exercises: exercises)
    }

    // MARK: - Day 5: Deltoid Focused Full Body (OHP Primary)

    private static func day5Delts(week: Int) -> WorkoutBlueprint {
        var exercises: [ExerciseBlueprint] = []
        var idx = 0

        // Primary: OHP
        let ohpExercises = ohpForWeek(week, startIndex: &idx)
        exercises.append(contentsOf: ohpExercises)

        if isBlock2.contains(week) {
            // Block 2: Cable Lateral Raise + Pendlay Row + Seated Hip Abduction + EZ Bar Curl 21s + Cable Crunch + Standing Calf + Push Up
            let rpe = week <= 6 ? "RPE7" : "RPE8"

            exercises.append(ExerciseBlueprint(
                name: "Cable Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: week <= 5 ? "RPE8" : rpe,
                restPeriod: "1-2 min",
                notes: "Swing the weight out, not up",
                substitutions: ["DB lateral raise", "Machine lateral raise"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Pendlay Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: week <= 6 ? "10" : "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-3 min",
                notes: "Keep a flat back, pull your elbows back at 45 degree angle",
                substitutions: ["Barbell row", "Chest-supported row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Seated Hip Abduction",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Focus on driving your knees out",
                substitutions: ["Lateral band walk"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "EZ Bar Curl 21s",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 2,
                targetReps: week == 5 ? "7/7/7" : "10",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "First 7 reps bottom half of ROM, next 7 reps top half of ROM, last 7 reps full ROM",
                substitutions: ["DB curl 21s", "Cable curl 21s"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Focus on flexing your spine. Avoid yanking with your arms",
                substitutions: ["Bodyweight crunch", "V sit-up"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "1-2 second pause at the bottom of each rep",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Push Up",
                orderIndex: idx,
                workingSets: 2,
                targetReps: "AMRAP",
                loadType: .rpe,
                rpeTarget: rpe,
                restPeriod: "1-2 min",
                notes: "Squeeze your pecs",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

        } else if week == deloadWeek {
            // Deload Day 5: Bench (practice for AMRAPs) + Cable Seated Row + Hip Abduction + Incline Curl + Bicycle Crunch + Calf + Push Up
            exercises.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 1, workingSets: 3,
                targetReps: "2", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "1-2 min",
                notes: "Practice set up and explosive technique for AMRAPs next week",
                substitutions: ["DB press", "Machine chest press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Seated Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-3 min",
                notes: "Focus on squeezing your shoulder blades together, pull with your elbows down and in",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Seated Hip Abduction",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on driving your knees out",
                substitutions: ["Lateral band walk"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Incline DB Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 2,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Brace upper back against bench, 45 degree incline, keep shoulders back as you curl",
                substitutions: ["DB curl", "Cable curl"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Bicycle Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Focus on flexing and rotating your spine, bring your left elbow to right knee, right elbow to left knee",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "1-2 second pause at the bottom of each rep",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Push Up",
                orderIndex: idx,
                workingSets: 2,
                targetReps: "AMRAP",
                loadType: .rpe,
                rpeTarget: "RPE6",
                restPeriod: "1-2 min",
                notes: "Perform as many reps as you can to hit target RPE",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

        } else if week == amrapWeek {
            // AMRAP Day 5: Egyptian Lateral Raise + Cable Seated Row + Hip Abduction + Incline Curl + Bicycle Crunch + Calf + Push Up
            exercises.append(ExerciseBlueprint(
                name: "Egyptian Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: "RPE9",
                restPeriod: "1-2 min",
                notes: "2-second eccentric. Lean away from the cable, focus on squeezing your delts",
                substitutions: ["DB lateral raise", "Cable lateral raise"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Seated Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-3 min",
                notes: "Focus on squeezing your shoulder blades together, pull with your elbows down and in",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Seated Hip Abduction",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-2 min",
                notes: "Focus on driving your knees out",
                substitutions: ["Lateral band walk"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Incline DB Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 2,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: "RPE10",
                restPeriod: "1-2 min",
                notes: "Brace upper back against bench, 45 degree incline, keep shoulders back as you curl",
                substitutions: ["DB curl", "Cable curl"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Bicycle Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-2 min",
                notes: "Focus on flexing and rotating your spine, bring your left elbow to right knee, right elbow to left knee",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: "RPE8",
                restPeriod: "1-2 min",
                notes: "Press onto your toes",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Push Up",
                orderIndex: idx,
                workingSets: 2,
                targetReps: "AMRAP",
                loadType: .rpe,
                rpeTarget: "RPE10",
                restPeriod: "1-2 min",
                notes: "Squeeze your pecs",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

        } else {
            // Block 1: Egyptian Lateral Raise + Cable Seated Row + Seated Hip Abduction + Incline DB Curl + Bicycle Crunch + Standing Calf + Push Up
            let rpeLateral: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE9"
                case 4: return "RPE9"
                default: return "RPE8"
                }
            }()
            let rpeMod: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE7"
                default: return "RPE7"
                }
            }()
            let rpeMod2: String = {
                switch week {
                case 1, 2: return "RPE7"
                case 3, 4: return "RPE8"
                default: return "RPE7"
                }
            }()
            let rpeCurl: String = {
                switch week {
                case 1: return "RPE8"
                case 2: return "RPE8"
                case 3: return "RPE7"
                case 4: return "RPE8"
                default: return "RPE8"
                }
            }()
            let rpePushup: String = {
                switch week {
                case 1: return "RPE6"
                case 2: return "RPE6"
                case 3: return "RPE7"
                case 4: return "RPE8"
                default: return "RPE7"
                }
            }()

            exercises.append(ExerciseBlueprint(
                name: "Egyptian Lateral Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "8",
                loadType: .rpe,
                rpeTarget: rpeLateral,
                restPeriod: "1-2 min",
                notes: "2-second eccentric. Lean away from the cable, focus on squeezing your delts",
                substitutions: ["DB lateral raise", "Cable lateral raise"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Cable Seated Row",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "1-3 min",
                notes: "Focus on squeezing your shoulder blades together, pull with your elbows down and in",
                substitutions: ["DB row", "Cable row"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Seated Hip Abduction",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "20",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "1-2 min",
                notes: "Focus on driving your knees out",
                substitutions: ["Lateral band walk"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Incline DB Curl",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 2,
                targetReps: "10",
                loadType: .rpe,
                rpeTarget: rpeCurl,
                restPeriod: "1-2 min",
                notes: "Brace upper back against bench, 45 degree incline, keep shoulders back as you curl",
                substitutions: ["DB curl", "Cable curl"],
                isDumbbell: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Bicycle Crunch",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 3,
                targetReps: "15",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "1-2 min",
                notes: "Focus on flexing and rotating your spine, bring your left elbow to right knee, right elbow to left knee",
                substitutions: [],
                isBodyweight: true
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Standing Calf Raise",
                orderIndex: idx,
                warmupSets: 1,
                workingSets: 4,
                targetReps: "12",
                loadType: .rpe,
                rpeTarget: rpeMod,
                restPeriod: "1-2 min",
                notes: "Press onto your toes",
                substitutions: ["Seated calf raise", "Leg press calf press"]
            )); idx += 1

            exercises.append(ExerciseBlueprint(
                name: "Push Up",
                orderIndex: idx,
                workingSets: 2,
                targetReps: "AMRAP",
                loadType: .rpe,
                rpeTarget: rpePushup,
                restPeriod: "1-2 min",
                notes: "Perform as many reps as you can to hit target RPE",
                substitutions: [],
                isBodyweight: true
            )); idx += 1
        }

        return WorkoutBlueprint(name: "Deltoid Focused Full Body", dayIndex: 4, exercises: exercises)
    }

    // MARK: - Primary Lift Builders

    // MARK: Back Squat

    private static func squatForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Sit back and down, 15° toe flare, drive your knees out laterally"
        let subs = ["Hack squat", "Smith machine squat", "Leg press + 15 reps back extensions"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.775,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "6", loadType: .percentage, percentage: 0.775,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "3-5", loadType: .percentage, percentage: 0.875,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "6-8", loadType: .percentage, percentage: 0.80,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "8", loadType: .percentage, percentage: 0.70,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.925,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "2", loadType: .percentage, percentage: 0.85,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .squat, restPeriod: "2-4 min", notes: "As many reps as possible (AMRAP) - Always use a spotter and good technique", substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Back Squat", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .squat, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Bench Press

    private static func benchForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Retract scapulae, arch upper back, leg drive through floor"
        let cueBlock2 = "Elbows at a 45° angle. Squeeze your shoulder blades and stay firm on the bench"
        let subs = ["DB press", "Machine chest press", "Smith machine bench press"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.875,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        case 6:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.85,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        case 7:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "10", loadType: .percentage, percentage: 0.75,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        case 8:
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        case 9: // Deload — Day 2 primary
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "3", loadType: .percentage, percentage: 0.80,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .bench, restPeriod: "2-4 min", notes: "As many reps as possible (AMRAP) - Always use a spotter and good technique", substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Bench Press", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .bench, restPeriod: "2-4 min", notes: cueBlock2, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Deadlift

    private static func deadliftForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Brace your lats, chest tall, hips high, pull the slack out of the bar prior to moving it off the ground"
        let subs = ["Sumo deadlift"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1: // Touch-and-go
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2: // Reset deadlift
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3: // Touch-and-go
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "2", loadType: .percentage, percentage: 0.875,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4: // Reset deadlift
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5:
            // Topset: touch-and-go
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.90,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            // Backoff: reset deadlift
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "2", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "4", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "4", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "6", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 3,
                targetReps: "6", loadType: .percentage, percentage: 0.70,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8:
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "2", loadType: .percentage, percentage: 0.95,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 1,
                targetReps: "3", loadType: .percentage, percentage: 0.85,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload — Day 4 primary
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "2", loadType: .percentage, percentage: 0.80,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10: // AMRAP
            result.append(ExerciseBlueprint(
                name: "Deadlift", orderIndex: idx, tag: .topset, warmupSets: 3, workingSets: 1,
                targetReps: "AMRAP", loadType: .percentage, percentage: 0.90,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: "As many reps as possible (AMRAP) - Always use a spotter and good technique", substitutions: subs
            )); idx += 1
            result.append(ExerciseBlueprint(
                name: "Reset Deadlift", orderIndex: idx, tag: .backoff, warmupSets: 0, workingSets: 2,
                targetReps: "5", loadType: .percentage, percentage: 0.75,
                percentageOf: .deadlift, restPeriod: "3-5 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Overhead Press (Day 5 Primary)

    private static func ohpForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Squeeze your glutes to keep your torso upright, clear your head out of the way, press up and slightly back"
        let subs = ["Seated barbell overhead press"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 1:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 2:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.65,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 3:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.775,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 4:
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.675,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 5: // Day 5 primary: 3ws x8 @ 80%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 3,
                targetReps: "8", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6: // Day 5 primary: 4ws x4 @ 82.5%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "4", loadType: .percentage, percentage: 0.825,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7: // Day 5 primary: 4ws x6 @ 80%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8: // Day 5 primary: 5ws x3 @ 87.5%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 5,
                targetReps: "3", loadType: .percentage, percentage: 0.875,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 9: // Deload
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 10:
            // 75-80% x10 x4
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 3, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.775,
                percentageOf: .ohp, rpeTarget: "75-80%", restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Secondary OHP (Day 1, Block 2 only)

    private static func secondaryOHPForWeek(_ week: Int, startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Squeeze your glutes to keep your torso upright, clear your head out of the way, press up and slightly back"
        let subs = ["Seated barbell overhead press"]
        var result: [ExerciseBlueprint] = []

        switch week {
        case 5: // 4ws x6 @ 80%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "6", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 6: // 4ws x8 @ 75%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "8", loadType: .percentage, percentage: 0.75,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 7: // 4ws x10 @ 65%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "10", loadType: .percentage, percentage: 0.65,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        case 8: // 4ws x5 @ 80%
            result.append(ExerciseBlueprint(
                name: "Overhead Press", orderIndex: idx, warmupSets: 2, workingSets: 4,
                targetReps: "5", loadType: .percentage, percentage: 0.80,
                percentageOf: .ohp, restPeriod: "2-3 min", notes: cue, substitutions: subs
            )); idx += 1
        default:
            break
        }

        return result
    }

    // MARK: Deload Secondary Bench on Day 1 (Week 9 only)

    private static func deloadSecondaryBenchDay1(startIndex idx: inout Int) -> [ExerciseBlueprint] {
        let cue = "Speed reps - press bar explosively off chest"
        let subs = ["DB press", "Machine chest press"]
        var result: [ExerciseBlueprint] = []

        result.append(ExerciseBlueprint(
            name: "Bench Press", orderIndex: idx, warmupSets: 2, workingSets: 3,
            targetReps: "4", loadType: .percentage, percentage: 0.70,
            percentageOf: .bench, restPeriod: "2-3 min", notes: cue, substitutions: subs
        )); idx += 1

        return result
    }
}
