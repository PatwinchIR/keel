import SwiftUI
import SwiftData

struct EditOneRMView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var record: OneRepMax

    @State private var weightText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var showDeleteConfirm = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                VStack(spacing: K.Spacing.lg) {
                    // Lift indicator
                    HStack(spacing: K.Spacing.xs) {
                        Circle()
                            .fill(record.lift.chartColor)
                            .frame(width: 8, height: 8)
                        Text(record.lift.displayName)
                            .font(.keelHeadline)
                            .foregroundStyle(K.Colors.primary)
                    }

                    // Weight input
                    HStack {
                        Text("Weight")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        TextField("0", text: $weightText)
                            .font(.keelWeight)
                            .foregroundStyle(K.Colors.accent)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .frame(width: 120)
                        Text("lbs")
                            .font(.keelCaption)
                            .foregroundStyle(K.Colors.secondary)
                    }
                    .keelCard()

                    // Date
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(K.Colors.primary)
                        .tint(K.Colors.accent)
                        .keelCard()

                    // Note
                    TextField("Note (optional)", text: $note)
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.primary)
                        .keelCard()

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text("SAVE")
                            .font(.keelHeadline)
                            .foregroundStyle(K.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, K.Spacing.lg)
                            .background(!weightText.isEmpty ? K.Colors.accent : K.Colors.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                    }
                    .disabled(weightText.isEmpty)

                    // Delete button
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Record")
                            .font(.keelCaption)
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }
                .padding(K.Spacing.lg)
            }
            .navigationTitle("Edit Record")
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
            .onAppear {
                weightText = String(Int(record.weight))
                date = record.date
                note = record.note ?? ""
            }
            .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    let service = ProgramService(modelContext: modelContext)
                    service.deleteOneRepMax(record)
                    service.syncCycleNumber()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func save() {
        guard let w = Double(weightText) else { return }
        record.weight = w
        record.date = date
        record.note = note.isEmpty ? nil : note
        try? modelContext.save()
        dismiss()
    }
}
