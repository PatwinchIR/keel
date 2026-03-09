import SwiftUI
import SwiftData

struct AddOneRMView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLift: CompoundLift = .squat
    @State private var weight: String = ""
    @State private var date = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                VStack(spacing: K.Spacing.lg) {
                    // Lift picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: K.Spacing.sm) {
                            ForEach(CompoundLift.allCases) { lift in
                                Button {
                                    selectedLift = lift
                                } label: {
                                    Text(lift.displayName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(selectedLift == lift ? K.Colors.background : K.Colors.secondary)
                                        .padding(.horizontal, K.Spacing.md)
                                        .padding(.vertical, K.Spacing.sm)
                                        .background(selectedLift == lift ? lift.chartColor : K.Colors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                                }
                            }
                        }
                    }

                    HStack {
                        Text("Weight")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        TextField("0", text: $weight)
                            .font(.keelWeight)
                            .foregroundStyle(K.Colors.accent)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 120)
                        Text("lbs")
                            .font(.keelCaption)
                            .foregroundStyle(K.Colors.secondary)
                    }
                    .keelCard()

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(K.Colors.primary)
                        .tint(K.Colors.accent)
                        .keelCard()

                    TextField("Note (optional)", text: $note)
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.primary)
                        .keelCard()

                    Button {
                        save()
                    } label: {
                        Text("SAVE")
                            .font(.keelHeadline)
                            .foregroundStyle(K.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, K.Spacing.lg)
                            .background(K.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                    }
                    .disabled(weight.isEmpty)

                    Spacer()
                }
                .padding(K.Spacing.lg)
            }
            .navigationTitle("Add 1RM Record")
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

    private func save() {
        guard let w = Double(weight) else { return }
        let service = ProgramService(modelContext: modelContext)
        service.saveOneRepMax(
            lift: selectedLift,
            weight: w,
            cycleNumber: 0,
            note: note.isEmpty ? nil : note
        )
        dismiss()
    }
}
