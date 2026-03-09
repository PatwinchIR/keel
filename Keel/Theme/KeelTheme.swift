import SwiftUI

enum K {
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: 0xF3F5F1)
        static let surface = Color(hex: 0xFFFFFF)
        static let surfaceLight = Color(hex: 0xF8FAF7)
        static let surfaceBorder = Color(hex: 0xDDE3D9)

        static let primary = Color(hex: 0x1A1F1A)
        static let secondary = Color(hex: 0x6B7B6B)
        static let tertiary = Color(hex: 0xA0ADA0)

        static let accent = Color(hex: 0x3D8B5E)
        static let success = Color(hex: 0x2E8B4A)
        static let pr = Color(hex: 0xB8860B)
        static let error = Color(hex: 0xC0392B)

        static let warmup = Color(hex: 0xEFF4EC)
        static let working = Color(hex: 0xFFFFFF)

        // Lift-specific colors for charts
        static let squat = Color(hex: 0x3D8B5E)
        static let bench = Color(hex: 0xC49030)
        static let deadlift = Color(hex: 0x2E7D7D)
        static let ohp = Color(hex: 0x7B6A9B)

        // Extended palette for accessory exercise chart lines
        static let accessoryChartColors: [Color] = [
            Color(hex: 0xE07B53),  // coral
            Color(hex: 0x5B9BD5),  // steel blue
            Color(hex: 0xC46BAE),  // mauve
            Color(hex: 0x7EC699),  // light green
            Color(hex: 0xD4C04A),  // mustard
            Color(hex: 0x6BB5B5),  // seafoam
            Color(hex: 0xB07CD8),  // violet
            Color(hex: 0xD98C5F),  // burnt orange
            Color(hex: 0x5DADE2),  // sky blue
            Color(hex: 0xA3D977),  // lime
        ]

        /// Stable hash for deterministic color assignment (djb2 algorithm)
        private static func stableHash(_ string: String) -> Int {
            var hash = 5381
            for char in string.utf8 {
                hash = ((hash &<< 5) &+ hash) &+ Int(char)
            }
            return abs(hash)
        }

        /// Returns a chart color for any exercise name.
        /// Compound lifts get their fixed colors; accessories get deterministic colors from the palette.
        static func chartColor(for exerciseName: String) -> Color {
            switch exerciseName {
            case CompoundLift.squat.displayName: return squat
            case CompoundLift.bench.displayName: return bench
            case CompoundLift.deadlift.displayName: return deadlift
            case CompoundLift.ohp.displayName: return ohp
            default:
                let index = stableHash(exerciseName) % accessoryChartColors.count
                return accessoryChartColors[index]
            }
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sharp: CGFloat = 2
    }

    // MARK: - Animation
    enum Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = K.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(K.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
            )
    }
}

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(K.Colors.secondary)
    }
}

extension View {
    func keelCard(padding: CGFloat = K.Spacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func sectionHeader() -> some View {
        modifier(SectionHeaderModifier())
    }
}

// MARK: - Font Helpers

extension Font {
    static let keelTitle = Font.system(.title, design: .default, weight: .bold)
    static let keelHeadline = Font.system(.headline, design: .default, weight: .bold)
    static let keelBody = Font.system(.body, design: .default, weight: .regular)
    static let keelCaption = Font.system(.caption, design: .default, weight: .medium)
    static let keelWeight = Font.system(.title, design: .default, weight: .heavy)
    static let keelWeightLarge = Font.system(size: 48, weight: .heavy, design: .default)
    static let keelMono = Font.system(.body, design: .monospaced, weight: .medium)
    static let keelMonoLarge = Font.system(size: 32, weight: .heavy, design: .monospaced)
}

// MARK: - Weight Formatting

extension Double {
    func weightString(unit: WeightUnit = .lbs) -> String {
        if self == self.rounded() {
            return "\(Int(self)) \(unit.label)"
        }
        return String(format: "%.1f \(unit.label)", self)
    }

    func percentageString() -> String {
        String(format: "%.1f%%", self * 100)
    }
}
