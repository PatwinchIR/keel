import SwiftUI
import SwiftData

struct OneRMCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Program> { $0.isActive == true }) private var activePrograms: [Program]

    @State private var selectedLift: CompoundLift = .squat
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var saved = false
    @FocusState private var isInputFocused: Bool

    private var program: Program? { activePrograms.first }

    private var brzyckiResult: Double? {
        guard let w = Double(weight), let r = Int(reps), r > 0, w > 0 else { return nil }
        return OneRepMax.brzyckiEstimate(weight: w, reps: r)
    }

    private var epleyResult: Double? {
        guard let w = Double(weight), let r = Int(reps), r > 0, w > 0 else { return nil }
        return OneRepMax.epleyEstimate(weight: w, reps: r)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                VStack(spacing: K.Spacing.xl) {
                    // Lift picker — full names in scrollable row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: K.Spacing.sm) {
                            ForEach(CompoundLift.allCases) { lift in
                                Button {
                                    selectedLift = lift
                                    saved = false
                                } label: {
                                    Text(lift.displayName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(selectedLift == lift ? K.Colors.background : K.Colors.secondary)
                                        .padding(.horizontal, K.Spacing.md)
                                        .padding(.vertical, K.Spacing.sm)
                                        .background(selectedLift == lift ? K.Colors.accent : K.Colors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                                }
                            }
                        }
                    }
                    .padding(.top, K.Spacing.lg)

                    // Input fields
                    HStack(spacing: K.Spacing.lg) {
                        VStack(spacing: K.Spacing.xs) {
                            Text("WEIGHT")
                                .sectionHeader()
                            HStack(alignment: .firstTextBaseline, spacing: K.Spacing.xs) {
                                TextField("0", text: $weight)
                                    .font(.keelWeightLarge)
                                    .foregroundStyle(K.Colors.primary)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused)
                                    .onChange(of: weight) { saved = false }
                                Text("lbs")
                                    .font(.keelCaption)
                                    .foregroundStyle(K.Colors.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Text("×")
                            .font(.title)
                            .foregroundStyle(K.Colors.tertiary)

                        VStack(spacing: K.Spacing.xs) {
                            Text("REPS")
                                .sectionHeader()
                            TextField("0", text: $reps)
                                .font(.keelWeightLarge)
                                .foregroundStyle(K.Colors.primary)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .focused($isInputFocused)
                                .onChange(of: reps) { saved = false }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .keelCard()

                    // Results — Brzycki primary, Epley secondary
                    if let brzycki = brzyckiResult {
                        VStack(spacing: K.Spacing.md) {
                            // Brzycki (primary)
                            VStack(spacing: K.Spacing.xs) {
                                Text("ESTIMATED 1RM  •  BRZYCKI")
                                    .sectionHeader()

                                Text(String(format: "%.1f", brzycki))
                                    .font(.system(size: 56, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(K.Colors.accent)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())

                                Text("lbs")
                                    .font(.keelCaption)
                                    .foregroundStyle(K.Colors.secondary)
                            }

                            // Epley (secondary)
                            if let epley = epleyResult {
                                HStack(spacing: K.Spacing.sm) {
                                    Text("Epley:")
                                        .font(.keelCaption)
                                        .foregroundStyle(K.Colors.tertiary)
                                    Text(String(format: "%.1f lbs", epley))
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundStyle(K.Colors.secondary)
                                }
                            }
                        }
                        .padding(.vertical, K.Spacing.lg)

                        if !saved {
                            Button {
                                saveEstimate(value: brzycki)
                            } label: {
                                Text("SAVE AS NEW 1RM")
                                    .font(.keelHeadline)
                                    .foregroundStyle(K.Colors.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, K.Spacing.lg)
                                    .background(K.Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(K.Colors.success)
                                Text("Saved")
                                    .font(.keelHeadline)
                                    .foregroundStyle(K.Colors.success)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(K.Spacing.lg)
            }
            .navigationTitle("1RM Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(K.Colors.accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isInputFocused = false }
                        .foregroundStyle(K.Colors.accent)
                }
            }
            .toolbarBackground(K.Colors.surface, for: .navigationBar)
        }
    }

    private func saveEstimate(value: Double) {
        let service = ProgramService(modelContext: modelContext)
        let cycle = program?.currentCycleNumber ?? 1
        let w = Double(weight) ?? 0
        let r = reps
        // Round to nearest 5 for storage
        let rounded = (value / 5).rounded() * 5
        service.saveOneRepMax(
            lift: selectedLift,
            weight: rounded,
            cycleNumber: cycle,
            note: "Brzycki: \(r) reps at \(Int(w)) lbs"
        )
        saved = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
