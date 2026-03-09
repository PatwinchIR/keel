import SwiftUI
import SwiftData

struct ProgramOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Program> { $0.isActive == true }) private var activePrograms: [Program]
    @State private var selectedWorkout: Workout?
    @State private var showProgramBuilder = false
    @State private var showTemplateList = false

    private var program: Program? { activePrograms.first }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            if let program {
                programContent(program)
            } else {
                noProgramView
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            InteractiveWorkoutDetailSheet(workout: workout)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTemplateList) {
            TemplateListView()
        }
    }

    @ViewBuilder
    private func programContent(_ program: Program) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.xl) {
                // Program header
                VStack(alignment: .leading, spacing: K.Spacing.xs) {
                    Text(program.name)
                        .font(.keelTitle)
                        .foregroundStyle(K.Colors.primary)

                    HStack(spacing: K.Spacing.lg) {
                        Label("Cycle \(program.currentCycleNumber)", systemImage: "arrow.clockwise")
                        Label("\(program.totalWeeks) weeks", systemImage: "calendar")
                        Label(program.unit.label, systemImage: "scalemass")
                    }
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.secondary)
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.top, K.Spacing.lg)

                // Week grid
                ForEach(1...program.totalWeeks, id: \.self) { week in
                    weekRow(week: week, program: program)
                }

                Spacer(minLength: 100)
            }
        }
    }

    @ViewBuilder
    private func weekRow(week: Int, program: Program) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Text("WEEK \(week)")
                    .sectionHeader()

                if let block = program.blockForWeek(week) {
                    Text("·")
                        .foregroundStyle(K.Colors.tertiary)
                        .font(.caption)
                    Text(block.name.uppercased())
                        .sectionHeader()
                }

                Spacer()

                if week == program.currentWeek {
                    Text("CURRENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(K.Colors.accent)
                        .padding(.horizontal, K.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(K.Colors.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: K.Spacing.sm) {
                    let workouts = program.workoutsForWeek(week)
                    ForEach(workouts) { workout in
                        workoutCell(workout: workout, week: week, program: program)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)
            }
        }
    }

    @ViewBuilder
    private func workoutCell(workout: Workout, week: Int, program: Program) -> some View {
        let isCurrent = week == program.currentWeek && isToday(workout, program: program)

        Button {
            selectedWorkout = workout
        } label: {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                HStack {
                    Text("D\(workout.dayIndex + 1)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(isCurrent ? K.Colors.accent : K.Colors.secondary)

                    if workout.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(K.Colors.success)
                    }
                }

                Text(shortWorkoutName(workout.name))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(K.Colors.primary)
                    .lineLimit(1)
            }
            .padding(K.Spacing.md)
            .frame(width: 90)
            .background(
                isCurrent ? K.Colors.accent.opacity(0.1) :
                workout.isCompleted ? K.Colors.success.opacity(0.08) :
                K.Colors.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(
                        isCurrent ? K.Colors.accent.opacity(0.3) : K.Colors.surfaceBorder,
                        lineWidth: isCurrent ? 1 : 0.5
                    )
            )
        }
    }

    @ViewBuilder
    private var noProgramView: some View {
        VStack(spacing: K.Spacing.xl) {
            Text("No Active Program")
                .font(.keelTitle)
                .foregroundStyle(K.Colors.primary)

            Text("Start a program from a template or build one from scratch.")
                .font(.keelBody)
                .foregroundStyle(K.Colors.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: K.Spacing.md) {
                Button {
                    showTemplateList = true
                } label: {
                    Text("START FROM TEMPLATE")
                        .font(.keelHeadline)
                        .foregroundStyle(K.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.lg)
                        .background(K.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }

                Button {
                    showProgramBuilder = true
                } label: {
                    Text("BUILD FROM SCRATCH")
                        .font(.keelHeadline)
                        .foregroundStyle(K.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: K.Radius.sharp)
                                .stroke(K.Colors.surfaceBorder, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, K.Spacing.xxl)
        }
    }

    private func isToday(_ workout: Workout, program: Program) -> Bool {
        let today = TrainingDay.fromDate(Date())
        guard let dayIndex = program.trainingDays.firstIndex(of: today) else { return false }
        return workout.dayIndex == dayIndex
    }

    private func shortWorkoutName(_ name: String) -> String {
        name.replacingOccurrences(of: "Focused Full Body", with: "")
            .replacingOccurrences(of: "Full Body", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Interactive Workout Detail Sheet

struct InteractiveWorkoutDetailSheet: View {
    let workout: Workout
    @Environment(PlateSettings.self) private var plateSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var expandedExerciseId: UUID?
    @State private var showRestTimer = false
    @State private var restSeconds: Int = 0

    private var oneRepMaxes: [CompoundLift: Double] {
        ProgramService(modelContext: modelContext).currentOneRepMaxes()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                K.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: K.Spacing.lg) {
                        ForEach(workout.sortedExercises) { exercise in
                            ExerciseCardView(
                                exercise: exercise,
                                oneRepMaxes: oneRepMaxes,
                                isExpanded: expandedExerciseId == exercise.id,
                                onTap: {
                                    withAnimation(K.Animation.fast) {
                                        expandedExerciseId = expandedExerciseId == exercise.id ? nil : exercise.id
                                    }
                                },
                                onSetComplete: { setLog in
                                    completeSet(setLog, exercise: exercise)
                                },
                                onLongPress: { }
                            )
                        }
                    }
                    .padding(K.Spacing.lg)
                }

                if showRestTimer {
                    RestTimerOverlay(
                        totalSeconds: restSeconds,
                        isPresented: $showRestTimer
                    )
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(K.Colors.accent)
                }
            }
            .toolbarBackground(K.Colors.surface, for: .navigationBar)
        }
    }

    private func completeSet(_ setLog: SetLog, exercise: Exercise) {
        let service = ProgramService(modelContext: modelContext)
        service.markSetComplete(setLog)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let seconds = parseRestPeriod(exercise.restPeriod)
        if seconds > 0 {
            let allDone = exercise.sortedSetLogs.allSatisfy(\.isCompleted)
            if !allDone {
                restSeconds = seconds
                showRestTimer = true
            }
        }
    }

    private func parseRestPeriod(_ rest: String) -> Int {
        let cleaned = rest.replacingOccurrences(of: " min", with: "")
        if let dash = cleaned.firstIndex(of: "-"),
           let lower = Int(cleaned[cleaned.startIndex..<dash]) {
            return lower * 60
        }
        if let val = Int(cleaned) { return val * 60 }
        return 120
    }
}
