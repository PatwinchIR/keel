import SwiftUI
import SwiftData

struct AddOneRMView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var weights: [CompoundLift: String] = [:]
    @State private var notes: [CompoundLift: String] = [:]
    @FocusState private var isInputFocused: Bool

    private var hasAnyInput: Bool {
        weights.values.contains { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: K.Spacing.lg) {
                        // Date picker — shared across all lifts
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .foregroundStyle(K.Colors.primary)
                            .tint(K.Colors.accent)
                            .keelCard()

                        // All lifts inline
                        ForEach(CompoundLift.allCases) { lift in
                            liftRow(lift)
                        }

                        // Save
                        let filledCount = CompoundLift.allCases.filter { !(weights[$0] ?? "").isEmpty }.count
                        Button {
                            saveAll()
                        } label: {
                            Text("SAVE\(filledCount > 1 ? " (\(filledCount) RECORDS)" : "")")
                                .font(.keelHeadline)
                                .foregroundStyle(K.Colors.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, K.Spacing.lg)
                                .background(hasAnyInput ? K.Colors.accent : K.Colors.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                        }
                        .disabled(!hasAnyInput)

                        Spacer(minLength: 40)
                    }
                    .padding(K.Spacing.lg)
                }
            }
            .navigationTitle("Add 1RM Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(K.Colors.secondary)
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

    @ViewBuilder
    private func liftRow(_ lift: CompoundLift) -> some View {
        VStack(spacing: K.Spacing.sm) {
            HStack {
                Circle()
                    .fill(lift.chartColor)
                    .frame(width: 8, height: 8)
                Text(lift.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(K.Colors.primary)
                Spacer()
                TextField("0", text: Binding(
                    get: { weights[lift, default: ""] },
                    set: { weights[lift] = $0 }
                ))
                .font(.keelWeight)
                .foregroundStyle(K.Colors.accent)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .focused($isInputFocused)
                .frame(width: 100)
                Text("lbs")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
            }

            TextField("Note (optional)", text: Binding(
                get: { notes[lift, default: ""] },
                set: { notes[lift] = $0 }
            ))
            .font(.system(size: 12))
            .foregroundStyle(K.Colors.secondary)
        }
        .keelCard()
    }

    private func saveAll() {
        let service = ProgramService(modelContext: modelContext)
        let cycleNumber = service.activeProgram()?.currentCycleNumber ?? 1

        for lift in CompoundLift.allCases {
            guard let text = weights[lift],
                  !text.isEmpty,
                  let w = Double(text) else { continue }

            let note = notes[lift, default: ""]

            service.saveOneRepMax(
                lift: lift,
                weight: w,
                date: date,
                cycleNumber: cycleNumber,
                note: note.isEmpty ? nil : note
            )
        }
        service.syncCycleNumber()
        dismiss()
    }
}
