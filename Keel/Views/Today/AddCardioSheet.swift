import SwiftUI
import SwiftData

struct AddCardioSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: CardioType = .running
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""
    @State private var searchText: String = ""

    let date: Date

    private var filteredGroups: [(category: CardioType.Category, types: [CardioType])] {
        let groups = CardioType.grouped()
        guard !searchText.isEmpty else { return groups }
        let query = searchText.lowercased()
        return groups.compactMap { group in
            let matched = group.types.filter { $0.displayName.lowercased().contains(query) }
            return matched.isEmpty ? nil : (category: group.category, types: matched)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Activity list
                    List {
                        ForEach(filteredGroups, id: \.category) { group in
                            Section {
                                ForEach(group.types) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        HStack(spacing: K.Spacing.md) {
                                            Image(systemName: type.icon)
                                                .font(.body)
                                                .foregroundStyle(selectedType == type ? K.Colors.accent : K.Colors.secondary)
                                                .frame(width: 28)

                                            Text(type.displayName)
                                                .font(.keelBody)
                                                .foregroundStyle(K.Colors.primary)

                                            Spacer()

                                            if selectedType == type {
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(K.Colors.accent)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    .listRowBackground(
                                        selectedType == type
                                            ? K.Colors.accent.opacity(0.1)
                                            : K.Colors.surface
                                    )
                                }
                            } header: {
                                Text(group.category.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(K.Colors.secondary)
                                    .tracking(0.6)
                            }
                        }
                    }
                    .listStyle(.grouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search activities")

                    // Bottom controls
                    VStack(spacing: K.Spacing.md) {
                        Divider().background(K.Colors.surfaceBorder)

                        // Duration
                        HStack {
                            Text("Duration")
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.primary)

                            Spacer()

                            Stepper(value: $durationMinutes, in: 5...180, step: 5) {
                                HStack(spacing: K.Spacing.xs) {
                                    Text("\(durationMinutes)")
                                        .font(.system(.body, design: .monospaced, weight: .bold))
                                        .foregroundStyle(K.Colors.accent)
                                        .monospacedDigit()
                                    Text("min")
                                        .font(.keelCaption)
                                        .foregroundStyle(K.Colors.secondary)
                                }
                            }
                            .tint(K.Colors.accent)
                        }
                        .padding(.horizontal, K.Spacing.lg)

                        // Notes
                        TextField("Notes (optional)", text: $notes)
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                            .padding(.horizontal, K.Spacing.lg)

                        // Save
                        Button {
                            save()
                        } label: {
                            Text("LOG CARDIO")
                                .font(.keelHeadline)
                                .foregroundStyle(K.Colors.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, K.Spacing.md)
                                .background(K.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                        }
                        .padding(.horizontal, K.Spacing.lg)
                        .padding(.bottom, K.Spacing.md)
                    }
                    .background(K.Colors.surface)
                }
            }
            .navigationTitle("Log Activity")
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
        let service = ProgramService(modelContext: modelContext)
        service.addCardioLog(
            type: selectedType,
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes,
            date: date
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
