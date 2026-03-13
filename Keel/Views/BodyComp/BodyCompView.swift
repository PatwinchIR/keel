import SwiftUI
import SwiftData

struct BodyCompView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyComposition.date, order: .reverse) private var entries: [BodyComposition]
    @State private var showAddEntry = false

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.lg) {
                    HStack {
                        Text("BODY COMPOSITION")
                            .sectionHeader()
                        Spacer()
                        Button {
                            showAddEntry = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.body)
                                .foregroundStyle(K.Colors.accent)
                        }
                    }
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.top, K.Spacing.lg)

                    if entries.isEmpty {
                        VStack(spacing: K.Spacing.md) {
                            Text("No entries yet")
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.secondary)
                            Text("Tap + to add body weight or body fat data")
                                .font(.keelCaption)
                                .foregroundStyle(K.Colors.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.xxl)
                    } else {
                        ForEach(entries) { entry in
                            entryRow(entry)
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddBodyCompView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: BodyComposition) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)

                if let method = entry.method {
                    Text(method)
                        .font(.caption2)
                        .foregroundStyle(K.Colors.tertiary)
                }
            }

            Spacer()

            HStack(spacing: K.Spacing.xl) {
                if let weight = entry.bodyWeight {
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.1f", weight))")
                            .font(.keelMono)
                            .foregroundStyle(K.Colors.primary)
                        Text("lbs")
                            .font(.caption2)
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }

                if let bf = entry.bodyFat {
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.1f", bf))%")
                            .font(.keelMono)
                            .foregroundStyle(K.Colors.accent)
                        Text("BF")
                            .font(.caption2)
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }
            }
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.sm)
    }
}

// MARK: - Add Entry

struct AddBodyCompView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var bodyWeight: String = ""
    @State private var bodyFat: String = ""
    @State private var method: String = ""
    @State private var note: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                VStack(spacing: K.Spacing.lg) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .foregroundStyle(K.Colors.primary)
                        .tint(K.Colors.accent)
                        .keelCard()

                    HStack {
                        Text("Body Weight")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        TextField("—", text: $bodyWeight)
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
                    .keelCard()

                    HStack {
                        Text("Body Fat")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        TextField("—", text: $bodyFat)
                            .font(.keelWeight)
                            .foregroundStyle(K.Colors.accent)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .frame(width: 100)
                        Text("%")
                            .font(.keelCaption)
                            .foregroundStyle(K.Colors.secondary)
                    }
                    .keelCard()

                    TextField("Method (e.g. DEXA, scale)", text: $method)
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.primary)
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
                    .disabled(bodyWeight.isEmpty && bodyFat.isEmpty)

                    Spacer()
                }
                .padding(K.Spacing.lg)
            }
            .navigationTitle("Add Entry")
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

    private func save() {
        let entry = BodyComposition(
            date: date,
            bodyFat: Double(bodyFat),
            bodyWeight: Double(bodyWeight),
            method: method.isEmpty ? nil : method,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
