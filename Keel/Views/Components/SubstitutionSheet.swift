import SwiftUI

struct SubstitutionSheet: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: K.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                Text("SUBSTITUTIONS")
                    .sectionHeader()

                Text(exercise.name)
                    .font(.keelHeadline)
                    .foregroundStyle(K.Colors.primary)

                if exercise.loadType == .percentage {
                    HStack(spacing: K.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                        Text("Percentage-based loading may not apply to substitute movements")
                            .font(.caption2)
                    }
                    .foregroundStyle(K.Colors.pr)
                    .padding(.top, K.Spacing.xs)
                }
            }
            .padding(.horizontal, K.Spacing.lg)
            .padding(.top, K.Spacing.lg)

            Divider()
                .background(K.Colors.surfaceBorder)

            // Current selection
            if let sub = exercise.activeSubstitution {
                HStack {
                    Text("Current: \(sub)")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.accent)

                    Spacer()

                    Button("Revert") {
                        exercise.activeSubstitution = nil
                        dismiss()
                    }
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
                }
                .padding(.horizontal, K.Spacing.lg)
            }

            // Substitution list
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(exercise.substitutions, id: \.self) { sub in
                        Button {
                            exercise.activeSubstitution = sub
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                        } label: {
                            HStack {
                                Text(sub)
                                    .font(.keelBody)
                                    .foregroundStyle(K.Colors.primary)

                                Spacer()

                                if exercise.activeSubstitution == sub {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(K.Colors.accent)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(K.Colors.tertiary)
                            }
                            .padding(K.Spacing.lg)
                            .background(K.Colors.surface)
                        }
                    }
                }
            }
        }
        .background(K.Colors.background)
    }
}
