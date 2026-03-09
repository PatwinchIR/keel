import SwiftUI

struct ExerciseInfo: Identifiable, Hashable {
    let name: String
    let isCompound: Bool
    let color: Color
    let shortName: String?

    var id: String { name }

    init(name: String, isCompound: Bool, color: Color, shortName: String? = nil) {
        self.name = name
        self.isCompound = isCompound
        self.color = color
        self.shortName = shortName
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerSheet: View {
    let exercises: [ExerciseInfo]
    @Binding var selected: Set<String>

    private var compounds: [ExerciseInfo] {
        exercises.filter(\.isCompound)
    }

    private var accessories: [ExerciseInfo] {
        exercises.filter { !$0.isCompound }
    }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.lg) {
                    Text("EXERCISES")
                        .sectionHeader()
                        .padding(.horizontal, K.Spacing.lg)
                        .padding(.top, K.Spacing.lg)

                    if !compounds.isEmpty {
                        sectionView("COMPOUNDS", exercises: compounds)
                    }

                    if !accessories.isEmpty {
                        sectionView("ACCESSORIES", exercises: accessories)
                    }

                    if exercises.isEmpty {
                        VStack(spacing: K.Spacing.md) {
                            Text("No exercises with data yet")
                                .font(.keelBody)
                                .foregroundStyle(K.Colors.secondary)
                            Text("Complete workouts to track exercise trends")
                                .font(.keelCaption)
                                .foregroundStyle(K.Colors.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.xxl)
                    }
                }
                .padding(.vertical, K.Spacing.lg)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ title: String, exercises: [ExerciseInfo]) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            Text(title)
                .sectionHeader()
                .padding(.horizontal, K.Spacing.lg)

            VStack(spacing: 0) {
                ForEach(exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .background(K.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .padding(.horizontal, K.Spacing.lg)
        }
    }

    @ViewBuilder
    private func exerciseRow(_ exercise: ExerciseInfo) -> some View {
        let isSelected = selected.contains(exercise.name)

        Button {
            withAnimation(K.Animation.fast) {
                if isSelected {
                    _ = selected.remove(exercise.name)
                } else {
                    selected.insert(exercise.name)
                }
            }
        } label: {
            HStack(spacing: K.Spacing.md) {
                Circle()
                    .fill(exercise.color)
                    .frame(width: 10, height: 10)

                Text(exercise.name)
                    .font(.keelBody)
                    .foregroundStyle(K.Colors.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? exercise.color : K.Colors.tertiary)
            }
            .padding(.horizontal, K.Spacing.lg)
            .padding(.vertical, K.Spacing.md)
        }
    }
}
