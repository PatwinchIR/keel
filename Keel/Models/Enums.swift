import Foundation
import SwiftUI
import HealthKit

enum WeightUnit: String, Codable, CaseIterable {
    case lbs, kg

    var label: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }
}

enum TrainingDay: Int, Codable, CaseIterable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    static func < (lhs: TrainingDay, rhs: TrainingDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func fromDate(_ date: Date) -> TrainingDay {
        let weekday = Calendar.current.component(.weekday, from: date)
        return TrainingDay(rawValue: weekday) ?? .monday
    }
}

enum ExerciseTag: String, Codable, CaseIterable {
    case topset, backoff

    var prefix: String {
        switch self {
        case .topset: return "[TOPSET]"
        case .backoff: return "[BACK OFF]"
        }
    }

    var icon: String {
        switch self {
        case .topset: return "arrow.up.right.circle.fill"
        case .backoff: return "arrow.down.right.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .topset: return Color(hex: 0xD4A048)
        case .backoff: return Color(hex: 0x7A8B7A)
        }
    }
}

enum LoadType: String, Codable {
    case percentage, rpe
}

enum CompoundLift: String, Codable, CaseIterable, Identifiable {
    case squat, bench, deadlift, ohp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squat: return "Back Squat"
        case .bench: return "Bench Press"
        case .deadlift: return "Deadlift"
        case .ohp: return "Overhead Press"
        }
    }

    var shortName: String {
        switch self {
        case .squat: return "SQ"
        case .bench: return "BP"
        case .deadlift: return "DL"
        case .ohp: return "OHP"
        }
    }

    var chartColor: Color {
        switch self {
        case .squat: return K.Colors.squat
        case .bench: return K.Colors.bench
        case .deadlift: return K.Colors.deadlift
        case .ohp: return K.Colors.ohp
        }
    }
}

enum SetType: String, Codable {
    case warmup, working
}

enum CardioType: String, Codable, CaseIterable, Identifiable {
    // Cardio
    case running, walking, cycling, swimming, hiking
    // Gym
    case stairMaster, elliptical, rowing, inclineWalking, jumpRope
    // Fitness
    case hiit, crossTraining, dance, yoga, pilates, coreTraining
    // Racket sports
    case tennis, pickleball, badminton, squash, tableTennis
    // Team sports
    case basketball, soccer, volleyball, baseball, softball
    case americanFootball, hockey, lacrosse, rugby
    // Combat
    case boxing, martialArts, wrestling
    // Water
    case surfing, paddleSports, waterPolo
    // Outdoor
    case climbing, golf, skating, skiing, snowboarding
    // Other
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .stairMaster: return "Stair Climber"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .inclineWalking: return "Incline Walk"
        case .jumpRope: return "Jump Rope"
        case .hiit: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .dance: return "Dance"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .coreTraining: return "Core Training"
        case .tennis: return "Tennis"
        case .pickleball: return "Pickleball"
        case .badminton: return "Badminton"
        case .squash: return "Squash"
        case .tableTennis: return "Table Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .volleyball: return "Volleyball"
        case .baseball: return "Baseball"
        case .softball: return "Softball"
        case .americanFootball: return "Football"
        case .hockey: return "Hockey"
        case .lacrosse: return "Lacrosse"
        case .rugby: return "Rugby"
        case .boxing: return "Boxing"
        case .martialArts: return "Martial Arts"
        case .wrestling: return "Wrestling"
        case .surfing: return "Surfing"
        case .paddleSports: return "Paddle Sports"
        case .waterPolo: return "Water Polo"
        case .climbing: return "Climbing"
        case .golf: return "Golf"
        case .skating: return "Skating"
        case .skiing: return "Skiing"
        case .snowboarding: return "Snowboarding"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .stairMaster: return "figure.stair.stepper"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .inclineWalking: return "figure.walk"
        case .jumpRope: return "figure.jumprope"
        case .hiit: return "flame.fill"
        case .crossTraining: return "figure.cross.training"
        case .dance: return "figure.dance"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .coreTraining: return "figure.core.training"
        case .tennis: return "figure.tennis"
        case .pickleball: return "figure.pickleball"
        case .badminton: return "figure.badminton"
        case .squash: return "figure.squash"
        case .tableTennis: return "figure.table.tennis"
        case .basketball: return "figure.basketball"
        case .soccer: return "figure.soccer"
        case .volleyball: return "figure.volleyball"
        case .baseball: return "figure.baseball"
        case .softball: return "figure.softball"
        case .americanFootball: return "figure.american.football"
        case .hockey: return "figure.hockey"
        case .lacrosse: return "figure.lacrosse"
        case .rugby: return "figure.rugby"
        case .boxing: return "figure.boxing"
        case .martialArts: return "figure.martial.arts"
        case .wrestling: return "figure.wrestling"
        case .surfing: return "figure.surfing"
        case .paddleSports: return "figure.water.fitness"
        case .waterPolo: return "figure.water.polo"
        case .climbing: return "figure.climbing"
        case .golf: return "figure.golf"
        case .skating: return "figure.skating"
        case .skiing: return "figure.skiing.downhill"
        case .snowboarding: return "figure.snowboarding"
        case .other: return "figure.mixed.cardio"
        }
    }

    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .running: return .running
        case .walking: return .walking
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .hiking: return .hiking
        case .stairMaster: return .stairClimbing
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .inclineWalking: return .walking
        case .jumpRope: return .jumpRope
        case .hiit: return .highIntensityIntervalTraining
        case .crossTraining: return .crossTraining
        case .dance: return .socialDance
        case .yoga: return .yoga
        case .pilates: return .pilates
        case .coreTraining: return .coreTraining
        case .tennis: return .tennis
        case .pickleball: return .pickleball
        case .badminton: return .badminton
        case .squash: return .squash
        case .tableTennis: return .tableTennis
        case .basketball: return .basketball
        case .soccer: return .soccer
        case .volleyball: return .volleyball
        case .baseball: return .baseball
        case .softball: return .softball
        case .americanFootball: return .americanFootball
        case .hockey: return .hockey
        case .lacrosse: return .lacrosse
        case .rugby: return .rugby
        case .boxing: return .boxing
        case .martialArts: return .martialArts
        case .wrestling: return .wrestling
        case .surfing: return .surfingSports
        case .paddleSports: return .paddleSports
        case .waterPolo: return .waterPolo
        case .climbing: return .climbing
        case .golf: return .golf
        case .skating: return .skatingSports
        case .skiing: return .downhillSkiing
        case .snowboarding: return .snowboarding
        case .other: return .other
        }
    }

    enum Category: String, CaseIterable {
        case cardio = "Cardio"
        case gym = "Gym"
        case fitness = "Fitness"
        case racket = "Racket Sports"
        case team = "Team Sports"
        case combat = "Combat"
        case water = "Water"
        case outdoor = "Outdoor"
        case other = "Other"
    }

    var category: Category {
        switch self {
        case .running, .walking, .cycling, .swimming, .hiking: return .cardio
        case .stairMaster, .elliptical, .rowing, .inclineWalking, .jumpRope: return .gym
        case .hiit, .crossTraining, .dance, .yoga, .pilates, .coreTraining: return .fitness
        case .tennis, .pickleball, .badminton, .squash, .tableTennis: return .racket
        case .basketball, .soccer, .volleyball, .baseball, .softball,
             .americanFootball, .hockey, .lacrosse, .rugby: return .team
        case .boxing, .martialArts, .wrestling: return .combat
        case .surfing, .paddleSports, .waterPolo: return .water
        case .climbing, .golf, .skating, .skiing, .snowboarding: return .outdoor
        case .other: return .other
        }
    }

    static func grouped() -> [(category: Category, types: [CardioType])] {
        Category.allCases.compactMap { cat in
            let types = allCases.filter { $0.category == cat }
            return types.isEmpty ? nil : (category: cat, types: types)
        }
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case sixMonths = "6M"
    case oneYear = "1Y"
    case twoYears = "2Y"
    case all = "ALL"

    var id: String { rawValue }

    var dateFloor: Date? {
        let calendar = Calendar.current
        switch self {
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
        case .oneYear: return calendar.date(byAdding: .year, value: -1, to: Date())
        case .twoYears: return calendar.date(byAdding: .year, value: -2, to: Date())
        case .all: return nil
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps
    case quads, hamstrings, glutes, calves, core

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .core: return "Core"
        }
    }

    var color: Color {
        switch self {
        case .chest: return Color(hex: 0xE07B53)     // coral
        case .back: return Color(hex: 0x5B9BD5)       // steel blue
        case .shoulders: return Color(hex: 0xC46BAE)   // mauve
        case .biceps: return Color(hex: 0x7EC699)      // light green
        case .triceps: return Color(hex: 0xD4C04A)     // mustard
        case .quads: return Color(hex: 0x3D8B5E)       // forest green
        case .hamstrings: return Color(hex: 0x2E7D7D)  // teal
        case .glutes: return Color(hex: 0xB07CD8)      // violet
        case .calves: return Color(hex: 0xD98C5F)      // burnt orange
        case .core: return Color(hex: 0x6BB5B5)        // seafoam
        }
    }

    var shortName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Delts"
        case .biceps: return "Bis"
        case .triceps: return "Tris"
        case .quads: return "Quads"
        case .hamstrings: return "Hams"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .core: return "Core"
        }
    }

    /// Lookup table mapping exercise names to their primary muscle groups.
    /// Covers all exercises in the Jeff Nippard Full Body 5x template and common substitutions.
    static func forExercise(_ name: String) -> [MuscleGroup] {
        switch name {
        // Compounds — Squat
        case "Back Squat":                                  return [.quads, .glutes]
        // Compounds — Bench
        case "Bench Press":                                 return [.chest, .triceps, .shoulders]
        // Compounds — Deadlift
        case "Deadlift", "Reset Deadlift", "Sumo deadlift": return [.back, .hamstrings, .glutes]
        // Compounds — OHP
        case "Overhead Press":                              return [.shoulders, .triceps]

        // Chest accessories
        case "DB Incline Press", "Barbell incline press":   return [.chest, .shoulders]
        case "Low Incline DB Press",
             "Low incline machine press",
             "Low incline barbell press":                   return [.chest]
        case "Low to High Cable Flye", "Pec deck", "DB flye": return [.chest]
        case "Decline Bench Press":                         return [.chest, .triceps]
        case "Deficit push-up":                             return [.chest, .triceps]
        case "Push Up":                                     return [.chest, .triceps, .shoulders]
        case "Dip":                                         return [.chest, .triceps]

        // Back accessories
        case "Chin-Up", "Neutral-grip pull-up":             return [.back, .biceps]
        case "Pronated Pulldown", "Pull-up",
             "Supinated pulldown",
             "Wide Grip Lat Pulldown", "Lat pulldown":      return [.back]
        case "Weighted Pullup":                             return [.back, .biceps]
        case "Dumbbell Row", "DB row",
             "Cable row", "Chest-supported row":            return [.back]
        case "Humble Row":                                  return [.back]
        case "Chest-Supported T-Bar Row",
             "Banded Chest-Supported T-Bar Row":            return [.back]
        case "Pendlay Row":                                 return [.back]
        case "Cable Seated Row":                            return [.back]
        case "Cable Pull-Over":                             return [.back, .chest]

        // Shoulder accessories
        case "DB Lateral Raise",
             "Machine lateral raise",
             "Cable lateral raise",
             "Cable Lateral Raise",
             "Egyptian Lateral Raise":                      return [.shoulders]
        case "Arnold Press",
             "DB seated shoulder press",
             "Machine shoulder press":                      return [.shoulders, .triceps]
        case "Cable Rope Upright Row":                      return [.shoulders]
        case "Rope Face Pull", "Reverse Pec Deck":          return [.shoulders, .back]

        // Arm accessories — Biceps
        case "Supinated EZ Bar Curl",
             "DB curl", "Cable curl":                       return [.biceps]
        case "Hammer Curl":                                 return [.biceps]
        case "EZ Bar Curl 21s":                             return [.biceps]
        case "Cable Single-Arm Curl":                       return [.biceps]
        case "Incline DB Curl":                             return [.biceps]

        // Arm accessories — Triceps
        case "Overhead Tricep Extension",
             "EZ bar skull crusher":                        return [.triceps]
        case "Tricep Pressdown":                            return [.triceps]
        case "EZ Bar Skull Crusher":                        return [.triceps]

        // Leg accessories
        case "Lying Leg Curl", "Seated leg curl",
             "Sliding leg curl",
             "Swiss Ball Leg Curl":                         return [.hamstrings]
        case "Glute Ham Raise":                             return [.hamstrings, .glutes]
        case "Leg Press", "Single-Leg Leg Press":           return [.quads, .glutes]
        case "Leg Extension":                               return [.quads]
        case "Barbell Hip Thrust or RDL",
             "Stiff leg deadlift", "Glute bridge":          return [.glutes, .hamstrings]
        case "Seated Hip Abduction":                        return [.glutes]
        case "Standing Calf Raise",
             "Eccentric-Accentuated Standing Calf Raise":   return [.calves]

        // Core
        case "Hanging Leg Raise",
             "Captain's chair crunch",
             "Reverse crunch":                              return [.core]
        case "Ab Wheel Rollout",
             "Long-lever plank", "Plank",
             "Hollow body hold":                            return [.core]
        case "Cable Crunch",
             "Bodyweight crunch", "V sit-up":               return [.core]
        case "Bicycle Crunch":                              return [.core]

        // Traps (grouped under back)
        case "Hex Bar Shrug",
             "Smith machine shrug", "DB shrug":             return [.back]

        default:                                            return []
        }
    }
}

enum OneRMFormula: String, CaseIterable, Identifiable {
    case brzycki, epley

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brzycki: return "Brzycki"
        case .epley: return "Epley"
        }
    }
}
