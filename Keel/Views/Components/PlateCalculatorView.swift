import SwiftUI

// MARK: - Compact Inline Plate Summary

struct PlateCompactView: View {
    let breakdown: PlateBreakdown
    var unit: WeightUnit = .lbs

    var body: some View {
        if breakdown.platesPerSide.isEmpty {
            Text("Bar only")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
        } else {
            HStack(spacing: K.Spacing.xs) {
                ForEach(breakdown.platesPerSide, id: \.weight) { plate in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(OlympicPlate.color(for: plate.weight, unit: unit))
                            .frame(width: 6, height: 14)
                        Text("\(plate.weight.clean)×\(plate.count)")
                            .font(.system(.caption2, design: .monospaced, weight: .medium))
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
                Text("/side")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(K.Colors.tertiary)
            }
        }
    }
}

// MARK: - Olympic Plate Specs (IWF Competition Colors)

enum OlympicPlate {
    /// IWF competition color coding.
    /// LBS plates mapped by their kg equivalent: 55≈25kg=Red, 45≈20kg=Blue, 35≈15kg=Yellow, 25≈10kg=Green
    /// KG plates follow IWF directly: 25=Red, 20=Blue, 15=Yellow, 10=Green, 5=White
    static func color(for weight: Double, unit: WeightUnit = .lbs) -> Color {
        if unit == .kg {
            return kgColor(weight)
        } else {
            return lbsColor(weight)
        }
    }

    private static func lbsColor(_ weight: Double) -> Color {
        switch weight {
        case 55:  return Color(hex: 0xC62828)   // Red (25kg equiv)
        case 45:  return Color(hex: 0x1565C0)   // Blue (20kg equiv)
        case 35:  return Color(hex: 0xF9A825)   // Yellow (15kg equiv)
        case 25:  return Color(hex: 0x2E7D32)   // Green (10kg equiv)
        case 10:  return Color(hex: 0xE0E0E0)   // White (5kg equiv)
        case 5:   return Color(hex: 0xD32F2F)   // Red small (2.5kg equiv)
        case 2.5: return Color(hex: 0x616161)   // Steel/black
        default:  return Color(hex: 0x757575)
        }
    }

    private static func kgColor(_ weight: Double) -> Color {
        switch weight {
        case 25:   return Color(hex: 0xC62828)   // Red
        case 20:   return Color(hex: 0x1565C0)   // Blue
        case 15:   return Color(hex: 0xF9A825)   // Yellow
        case 10:   return Color(hex: 0x2E7D32)   // Green
        case 5:    return Color(hex: 0xE0E0E0)   // White
        case 2.5:  return Color(hex: 0xD32F2F)   // Red (small)
        case 2:    return Color(hex: 0x1976D2)   // Blue (small)
        case 1.25: return Color(hex: 0xFBC02D)   // Yellow (small)
        case 0.5:  return Color(hex: 0xBDBDBD)   // White (small)
        default:   return Color(hex: 0x757575)
        }
    }

    /// Diameter scaled relative to full-size bumper (450mm real).
    /// All competition bumper plates (≥10kg / ≥25lbs) are full diameter.
    /// Change plates are progressively smaller.
    static func diameter(for weight: Double, unit: WeightUnit = .lbs) -> CGFloat {
        if unit == .kg {
            switch weight {
            case 25, 20, 15, 10: return 64   // Full size bumper
            case 5:    return 50             // Training plate
            case 2.5:  return 40             // Change plate
            case 2:    return 36
            case 1.25: return 32
            case 0.5:  return 28
            default:   return 44
            }
        } else {
            switch weight {
            case 55, 45, 35, 25: return 64   // Full size bumper
            case 10:  return 50              // Training plate
            case 5:   return 40              // Change plate
            case 2.5: return 32              // Small change plate
            default:  return 44
            }
        }
    }

    /// Thickness proportional to actual plate widths.
    static func thickness(for weight: Double, unit: WeightUnit = .lbs) -> CGFloat {
        if unit == .kg {
            switch weight {
            case 25:   return 18
            case 20:   return 15
            case 15:   return 12
            case 10:   return 9
            case 5:    return 7
            case 2.5:  return 5
            case 2:    return 4
            case 1.25: return 3
            case 0.5:  return 3
            default:   return 8
            }
        } else {
            switch weight {
            case 55:  return 18
            case 45:  return 15
            case 35:  return 12
            case 25:  return 10
            case 10:  return 7
            case 5:   return 5
            case 2.5: return 4
            default:  return 8
            }
        }
    }

    /// Label color — dark text on light plates, white text on dark plates
    static func labelColor(for weight: Double, unit: WeightUnit = .lbs) -> Color {
        // Yellow, white, and light steel plates need dark text
        if unit == .kg {
            switch weight {
            case 15, 5, 1.25, 0.5: return .black.opacity(0.7)
            default: return .white.opacity(0.85)
            }
        } else {
            switch weight {
            case 35, 10: return .black.opacity(0.7)  // Yellow and white plates
            case 2.5:    return .white.opacity(0.7)   // Steel plate
            default:     return .white.opacity(0.85)
            }
        }
    }
}

// MARK: - Visual Barbell Plate View

struct PlateVisualView: View {
    let breakdown: PlateBreakdown
    var unit: WeightUnit = .lbs

    private var conversionText: String {
        let weight = breakdown.achievedWeight
        if unit == .lbs {
            let kg = weight / 2.205
            return "≈ \(kg.clean) kg"
        } else {
            let lbs = weight * 2.205
            return "≈ \(lbs.clean) lbs"
        }
    }

    var body: some View {
        VStack(spacing: K.Spacing.sm) {
            // Weight label with conversion
            HStack(spacing: K.Spacing.xs) {
                Text(breakdown.achievedWeight.clean)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(K.Colors.primary)
                Text(unit.label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(K.Colors.secondary)
                Text(conversionText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(K.Colors.tertiary)
                if !breakdown.isExact {
                    Text("(\(breakdown.remainder.clean) off)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(K.Colors.error)
                }
            }

            // Barbell graphic
            barbellView

            // Plate legend
            if !breakdown.platesPerSide.isEmpty {
                plateLegend
            }
        }
        .padding(K.Spacing.md)
        .background(K.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
        .overlay(
            RoundedRectangle(cornerRadius: K.Radius.sharp)
                .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Barbell

    /// Dimensions modeled on an Olympic barbell:
    /// shaft (28mm) → collar flange → sleeve (50mm) with plates → end cap
    private let shaftHeight: CGFloat = 5
    private let sleeveHeight: CGFloat = 10
    private let collarWidth: CGFloat = 5
    private let collarHeight: CGFloat = 14
    private let endCapWidth: CGFloat = 4
    private let endCapHeight: CGFloat = 14
    private let shaftHalfLength: CGFloat = 40   // center-to-collar grip distance
    private let knurlWidth: CGFloat = 28
    private let plateGap: CGFloat = 1.5

    private var totalPlateStackWidth: CGFloat {
        let allPlates = breakdown.platesPerSide.flatMap { plate in
            Array(repeating: plate.weight, count: plate.count)
        }
        let widths = allPlates.map { OlympicPlate.thickness(for: $0, unit: unit) }
        let gaps = max(0, CGFloat(allPlates.count - 1)) * plateGap
        return widths.reduce(0, +) + gaps
    }

    /// Distance from center to the outermost edge of one side
    private var halfBarWidth: CGFloat {
        shaftHalfLength + collarWidth + totalPlateStackWidth + 6 + endCapWidth + 12
    }

    private var barbellView: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2

            Canvas { ctx, size in
                let metalLight = Color(hex: 0xBBBBBB)
                let metalMid = Color(hex: 0x999999)
                let metalDark = Color(hex: 0x777777)
                let metalVDark = Color(hex: 0x606060)

                // --- Full-width shaft (thin bar connecting everything) ---
                let shaftLeft = cx - halfBarWidth
                let shaftRight = cx + halfBarWidth
                let shaftRect = CGRect(
                    x: shaftLeft, y: cy - shaftHeight / 2,
                    width: shaftRight - shaftLeft, height: shaftHeight
                )
                ctx.fill(
                    Path(roundedRect: shaftRect, cornerRadius: 2),
                    with: .linearGradient(
                        Gradient(colors: [metalLight, metalDark, metalLight]),
                        startPoint: CGPoint(x: cx, y: shaftRect.minY),
                        endPoint: CGPoint(x: cx, y: shaftRect.maxY)
                    )
                )

                // --- Knurl marks (center knurl + grip knurls) ---
                // Center knurl
                let centerKnurlLeft = cx - knurlWidth / 2
                for i in stride(from: 0, to: knurlWidth, by: 2.5) {
                    var line = Path()
                    line.move(to: CGPoint(x: centerKnurlLeft + i, y: cy - shaftHeight / 2 + 1))
                    line.addLine(to: CGPoint(x: centerKnurlLeft + i, y: cy + shaftHeight / 2 - 1))
                    ctx.stroke(line, with: .color(metalVDark.opacity(0.35)), lineWidth: 0.5)
                }
                // Grip knurls (between center and collars)
                let gripKnurlWidth: CGFloat = shaftHalfLength - knurlWidth / 2 - 8
                for dir in [-1.0, 1.0] {
                    let gripStart = cx + dir * (knurlWidth / 2 + 6.0)
                    for i in stride(from: 0, through: gripKnurlWidth, by: 3) {
                        var line = Path()
                        let x = gripStart + dir * i
                        line.move(to: CGPoint(x: x, y: cy - shaftHeight / 2 + 1))
                        line.addLine(to: CGPoint(x: x, y: cy + shaftHeight / 2 - 1))
                        ctx.stroke(line, with: .color(metalVDark.opacity(0.25)), lineWidth: 0.5)
                    }
                }

                // --- Sleeves + collars + end caps (both sides) ---
                for dir in [-1.0, 1.0] {
                    // Collar sits at the end of the shaft grip area
                    let collarEdge = cx + dir * shaftHalfLength

                    // Collar flange (shaft-to-sleeve transition)
                    let collarRect = CGRect(
                        x: dir > 0 ? collarEdge : collarEdge - collarWidth,
                        y: cy - collarHeight / 2,
                        width: collarWidth,
                        height: collarHeight
                    )
                    ctx.fill(
                        Path(roundedRect: collarRect, cornerRadius: 1),
                        with: .linearGradient(
                            Gradient(colors: [metalLight, metalVDark, metalLight]),
                            startPoint: CGPoint(x: collarRect.midX, y: collarRect.minY),
                            endPoint: CGPoint(x: collarRect.midX, y: collarRect.maxY)
                        )
                    )
                    ctx.stroke(
                        Path(roundedRect: collarRect, cornerRadius: 1),
                        with: .color(Color.black.opacity(0.15)),
                        lineWidth: 0.5
                    )

                    // Sleeve (thicker bar behind plates)
                    let sleeveStart = dir > 0 ? collarRect.maxX : collarRect.minX
                    let sleeveLen = totalPlateStackWidth + 18
                    let sleeveRect = CGRect(
                        x: dir > 0 ? sleeveStart : sleeveStart - sleeveLen,
                        y: cy - sleeveHeight / 2,
                        width: sleeveLen,
                        height: sleeveHeight
                    )
                    ctx.fill(
                        Path(roundedRect: sleeveRect, cornerRadius: 1.5),
                        with: .linearGradient(
                            Gradient(colors: [metalLight, metalMid, metalLight]),
                            startPoint: CGPoint(x: sleeveRect.midX, y: sleeveRect.minY),
                            endPoint: CGPoint(x: sleeveRect.midX, y: sleeveRect.maxY)
                        )
                    )

                    // End cap
                    let capX = dir > 0 ? sleeveRect.maxX : sleeveRect.minX - endCapWidth
                    let capRect = CGRect(
                        x: capX, y: cy - endCapHeight / 2,
                        width: endCapWidth, height: endCapHeight
                    )
                    ctx.fill(
                        Path(roundedRect: capRect, cornerRadius: 2),
                        with: .linearGradient(
                            Gradient(colors: [metalMid, metalVDark]),
                            startPoint: CGPoint(x: capRect.midX, y: capRect.minY),
                            endPoint: CGPoint(x: capRect.midX, y: capRect.maxY)
                        )
                    )
                    ctx.stroke(
                        Path(roundedRect: capRect, cornerRadius: 2),
                        with: .color(Color.black.opacity(0.2)),
                        lineWidth: 0.5
                    )
                }

                // --- Plates (both sides) ---
                let allPlates = breakdown.platesPerSide.flatMap { plate in
                    Array(repeating: plate.weight, count: plate.count)
                }

                for dir in [-1.0, 1.0] {
                    let platesStart = cx + dir * (shaftHalfLength + collarWidth)
                    var offset: CGFloat = 0

                    for (_, weight) in allPlates.enumerated() {
                        let pw = OlympicPlate.thickness(for: weight, unit: unit)
                        let ph = OlympicPlate.diameter(for: weight, unit: unit)
                        let plateColor = OlympicPlate.color(for: weight, unit: unit)

                        let px: CGFloat
                        if dir > 0 {
                            px = platesStart + offset
                        } else {
                            px = platesStart - offset - pw
                        }

                        let plateRect = CGRect(
                            x: px, y: cy - ph / 2,
                            width: pw, height: ph
                        )

                        // Plate body
                        ctx.fill(
                            Path(roundedRect: plateRect, cornerRadius: 2.5),
                            with: .linearGradient(
                                Gradient(colors: [
                                    plateColor,
                                    plateColor.opacity(0.65),
                                    plateColor.opacity(0.8)
                                ]),
                                startPoint: CGPoint(x: plateRect.midX, y: plateRect.minY),
                                endPoint: CGPoint(x: plateRect.midX, y: plateRect.maxY)
                            )
                        )

                        // Plate border
                        ctx.stroke(
                            Path(roundedRect: plateRect, cornerRadius: 2.5),
                            with: .color(Color.black.opacity(0.25)),
                            lineWidth: 0.5
                        )

                        // Hub hole (center ring visible on larger plates)
                        if ph >= 50 {
                            let holeSize: CGFloat = sleeveHeight + 2
                            let holeRect = CGRect(
                                x: plateRect.midX - holeSize / 2,
                                y: cy - holeSize / 2,
                                width: holeSize, height: holeSize
                            )
                            ctx.stroke(
                                Path(ellipseIn: holeRect),
                                with: .color(Color.black.opacity(0.12)),
                                lineWidth: 0.5
                            )
                        }

                        // Weight label
                        if pw >= 9 {
                            let label = weight.plateLabel
                            ctx.draw(
                                Text(label)
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundStyle(OlympicPlate.labelColor(for: weight, unit: unit)),
                                at: CGPoint(x: plateRect.midX, y: cy),
                                anchor: .center
                            )
                        }

                        offset += pw + plateGap
                    }
                }
            }
        }
        .frame(height: 80)
    }

    // MARK: - Legend

    private var plateLegend: some View {
        HStack(spacing: K.Spacing.md) {
            ForEach(breakdown.platesPerSide, id: \.weight) { plate in
                HStack(spacing: K.Spacing.xs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(OlympicPlate.color(for: plate.weight, unit: unit))
                        .frame(width: 10, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                        )
                    Text("\(plate.weight.clean)×\(plate.count)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(K.Colors.secondary)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension Double {
    var clean: String {
        if self == self.rounded() && self >= 1 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }

    var plateLabel: String {
        if self == self.rounded() && self >= 1 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }
}

#Preview {
    VStack(spacing: 20) {
        let heavy = PlateCalculator.calculate(
            targetWeight: 405,
            barWeight: 45,
            availablePlates: [55, 45, 35, 25, 10, 5, 2.5]
        )
        PlateVisualView(breakdown: heavy, unit: .lbs)

        let kgLoad = PlateCalculator.calculate(
            targetWeight: 140,
            barWeight: 20,
            availablePlates: [25, 20, 15, 10, 5, 2.5, 1.25]
        )
        PlateVisualView(breakdown: kgLoad, unit: .kg)
    }
    .padding()
    .background(K.Colors.background)
    .preferredColorScheme(.light)
}
