import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBlueprint: TemplateBlueprint?

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: K.Spacing.lg) {
                        // Built-in template
                        templateCard(
                            name: "Jeff Nippard Full Body 5x",
                            description: "10-week periodized program. 3 blocks: Foundation, Intensification, Deload/AMRAP. Percentage-based progression on squat, bench, deadlift, OHP.",
                            weeks: 10,
                            days: 5
                        ) {
                            selectedBlueprint = JeffNippardTemplate.blueprint
                        }
                    }
                    .padding(K.Spacing.lg)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .toolbarBackground(K.Colors.surface, for: .navigationBar)
            .sheet(item: $selectedBlueprint) { blueprint in
                ProgramSetupView(blueprint: blueprint) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func templateCard(name: String, description: String, weeks: Int, days: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: K.Spacing.md) {
                HStack {
                    Text(name)
                        .font(.keelHeadline)
                        .foregroundStyle(K.Colors.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(K.Colors.tertiary)
                }

                Text(description)
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: K.Spacing.lg) {
                    Label("\(weeks) weeks", systemImage: "calendar")
                    Label("\(days) days/week", systemImage: "figure.strengthtraining.traditional")
                }
                .font(.caption)
                .foregroundStyle(K.Colors.tertiary)
            }
            .keelCard()
        }
    }
}

// MARK: - Program Setup (enter 1RMs before starting)

struct ProgramSetupView: View {
    let blueprint: TemplateBlueprint
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var squatMax: String = "337"
    @State private var benchMax: String = "254"
    @State private var deadliftMax: String = "424"
    @State private var ohpMax: String = "160"
    @State private var unit: WeightUnit = .lbs

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: K.Spacing.xl) {
                        Text("Enter your current 1RMs to calculate training loads.")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.secondary)

                        VStack(spacing: K.Spacing.md) {
                            ormField(label: "Back Squat", value: $squatMax)
                            ormField(label: "Bench Press", value: $benchMax)
                            ormField(label: "Deadlift", value: $deadliftMax)
                            ormField(label: "Overhead Press", value: $ohpMax)
                        }

                        Picker("Unit", selection: $unit) {
                            ForEach(WeightUnit.allCases, id: \.self) { u in
                                Text(u.label).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button {
                            createProgram()
                        } label: {
                            Text("START PROGRAM")
                                .font(.keelHeadline)
                                .foregroundStyle(K.Colors.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, K.Spacing.lg)
                                .background(K.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                        }
                        .padding(.top, K.Spacing.lg)
                    }
                    .padding(K.Spacing.lg)
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .toolbarBackground(K.Colors.surface, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func ormField(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.keelBody)
                .foregroundStyle(K.Colors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("0", text: value)
                .font(.keelWeight)
                .foregroundStyle(K.Colors.accent)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 100)

            Text(unit.label)
                .font(.keelCaption)
                .foregroundStyle(K.Colors.secondary)
                .frame(width: 30)
        }
        .padding(K.Spacing.lg)
        .background(K.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
    }

    private func createProgram() {
        let orms: [CompoundLift: Double] = [
            .squat: Double(squatMax) ?? 0,
            .bench: Double(benchMax) ?? 0,
            .deadlift: Double(deadliftMax) ?? 0,
            .ohp: Double(ohpMax) ?? 0
        ]

        // Save 1RMs
        let service = ProgramService(modelContext: modelContext)
        for (lift, weight) in orms {
            service.saveOneRepMax(lift: lift, weight: weight, cycleNumber: 1)
        }

        // Create program
        _ = service.createProgramFromBlueprint(blueprint, oneRepMaxes: orms)

        dismiss()
        onComplete()
    }
}
