import SwiftUI
import SwiftData

struct ProgramBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var totalWeeks: Int = 10
    @State private var selectedDays: Set<TrainingDay> = [.monday, .tuesday, .wednesday, .friday, .saturday]
    @State private var unit: WeightUnit = .lbs

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: K.Spacing.xl) {
                        // Name
                        VStack(alignment: .leading, spacing: K.Spacing.xs) {
                            Text("PROGRAM NAME")
                                .sectionHeader()
                            TextField("My Program", text: $name)
                                .font(.keelHeadline)
                                .foregroundStyle(K.Colors.primary)
                                .keelCard()
                        }

                        // Weeks
                        VStack(alignment: .leading, spacing: K.Spacing.xs) {
                            Text("TOTAL WEEKS")
                                .sectionHeader()
                            Stepper("\(totalWeeks) weeks", value: $totalWeeks, in: 1...52)
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.primary)
                                .keelCard()
                        }

                        // Training days
                        VStack(alignment: .leading, spacing: K.Spacing.sm) {
                            Text("TRAINING DAYS")
                                .sectionHeader()

                            HStack(spacing: K.Spacing.sm) {
                                ForEach(TrainingDay.allCases, id: \.rawValue) { day in
                                    Button {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    } label: {
                                        Text(day.shortName)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(selectedDays.contains(day) ? K.Colors.background : K.Colors.secondary)
                                            .frame(width: 40, height: 40)
                                            .background(selectedDays.contains(day) ? K.Colors.accent : K.Colors.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                                    }
                                }
                            }
                        }

                        // Unit
                        VStack(alignment: .leading, spacing: K.Spacing.xs) {
                            Text("UNIT")
                                .sectionHeader()
                            Picker("Unit", selection: $unit) {
                                ForEach(WeightUnit.allCases, id: \.self) { u in
                                    Text(u.label).tag(u)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Create button
                        Button {
                            createProgram()
                        } label: {
                            Text("CREATE PROGRAM")
                                .font(.keelHeadline)
                                .foregroundStyle(K.Colors.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, K.Spacing.lg)
                                .background(name.isEmpty ? K.Colors.tertiary : K.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                        }
                        .disabled(name.isEmpty)
                        .padding(.top, K.Spacing.lg)

                        Spacer()
                    }
                    .padding(K.Spacing.lg)
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .toolbarBackground(K.Colors.surface, for: .navigationBar)
        }
    }

    private func createProgram() {
        let days = Array(selectedDays).sorted()
        let program = Program(
            name: name,
            unit: unit,
            totalWeeks: totalWeeks,
            trainingDays: days
        )
        modelContext.insert(program)

        // Create empty workouts for each week/day
        for week in 1...totalWeeks {
            for (index, _) in days.enumerated() {
                let workout = Workout(
                    name: "Workout \(index + 1)",
                    weekNumber: week,
                    dayIndex: index
                )
                workout.program = program
                program.workouts.append(workout)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
