import SwiftUI
import SwiftData

struct ProgramOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Program> { $0.isActive == true }) private var activePrograms: [Program]
    @State private var selectedWorkout: Workout?
    @State private var showProgramBuilder = false
    @State private var showTemplateList = false
    @State private var weekToComplete: Int?

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
        .alert("Mark Week Complete",
               isPresented: Binding(
                   get: { weekToComplete != nil },
                   set: { if !$0 { weekToComplete = nil } }
               )
        ) {
            Button("Cancel", role: .cancel) { weekToComplete = nil }
            Button("Complete All") {
                if let program, let week = weekToComplete {
                    let service = ProgramService(modelContext: modelContext)
                    service.completeWeek(program, week: week)
                }
                weekToComplete = nil
            }
        } message: {
            if let week = weekToComplete, let program {
                let remaining = program.workoutsForWeek(week).filter { !$0.isCompleted }.count
                Text("Mark all \(remaining) remaining workout\(remaining == 1 ? "" : "s") in Week \(week) as complete?")
            }
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

                // Week grid — current week first, then cycle
                ForEach(orderedWeeks(for: program), id: \.self) { week in
                    weekRow(week: week, program: program)
                }

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Week status

    private enum WeekStatus {
        case current, completed, upcoming
    }

    private func weekStatus(_ week: Int, program: Program) -> WeekStatus {
        if week == program.currentWeek { return .current }
        let workouts = program.workoutsForWeek(week)
        if !workouts.isEmpty && workouts.allSatisfy(\.isCompleted) { return .completed }
        return .upcoming
    }

    // MARK: - Week row

    @ViewBuilder
    private func weekRow(week: Int, program: Program) -> some View {
        let status = weekStatus(week, program: program)
        let workouts = program.workoutsForWeek(week)
        let completedCount = workouts.filter(\.isCompleted).count
        let isCurrent = status == .current

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            // Header
            HStack(spacing: K.Spacing.sm) {
                // Week number
                Text("WEEK \(week)")
                    .sectionHeader()
                    .foregroundStyle(status == .completed ? K.Colors.tertiary : K.Colors.secondary)

                if let block = program.blockForWeek(week) {
                    Text("·")
                        .foregroundStyle(K.Colors.tertiary)
                        .font(.caption)
                    Text(block.name.uppercased())
                        .sectionHeader()
                        .foregroundStyle(status == .completed ? K.Colors.tertiary : K.Colors.secondary)
                }

                Spacer()

                // Completion fraction
                if !workouts.isEmpty {
                    Text("\(completedCount)/\(workouts.count)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(status == .completed ? K.Colors.success : K.Colors.tertiary)
                }

                // Mark week complete button (only when there are incomplete workouts)
                if completedCount < workouts.count && !workouts.isEmpty {
                    Button {
                        weekToComplete = week
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(K.Colors.tertiary)
                    }
                }

                // Status badge
                if isCurrent {
                    Text("CURRENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(K.Colors.accent)
                        .padding(.horizontal, K.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(K.Colors.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                } else if status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(K.Colors.success)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            // Week progress bar (current week only)
            if isCurrent && !workouts.isEmpty {
                weekProgressBar(completed: completedCount, total: workouts.count)
                    .padding(.horizontal, K.Spacing.lg)
            }

            // Workout cells
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: K.Spacing.sm) {
                    ForEach(workouts) { workout in
                        if isCurrent {
                            currentWeekWorkoutCell(workout: workout, program: program)
                        } else {
                            compactWorkoutCell(workout: workout, status: status)
                        }
                    }
                }
                .padding(.horizontal, K.Spacing.lg)
            }
        }
        // Current week gets a card-like container with accent left border
        .padding(.vertical, isCurrent ? K.Spacing.md : 0)
        .background(
            isCurrent
                ? K.Colors.surface.opacity(0.6)
                : Color.clear
        )
        .overlay(alignment: .leading) {
            if isCurrent {
                Rectangle()
                    .fill(K.Colors.accent)
                    .frame(width: 3)
            }
        }
        .opacity(status == .completed ? 0.6 : 1.0)
    }

    // MARK: - Week progress bar

    @ViewBuilder
    private func weekProgressBar(completed: Int, total: Int) -> some View {
        let fraction = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(K.Colors.surfaceBorder)
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(K.Colors.accent)
                    .frame(width: geo.size.width * fraction, height: 3)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Current week workout cell (expanded)

    @ViewBuilder
    private func currentWeekWorkoutCell(workout: Workout, program: Program) -> some View {
        let isToday = isToday(workout, program: program)

        Button {
            selectedWorkout = workout
        } label: {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                HStack {
                    Text("D\(workout.dayIndex + 1)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(isToday ? .white : K.Colors.secondary)

                    Spacer()

                    if isToday && !workout.isCompleted {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                    } else if workout.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isToday ? .white : K.Colors.success)
                    }
                }

                Text(shortWorkoutName(workout.name))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isToday ? .white : K.Colors.primary)
                    .lineLimit(1)

                // Extra details for current week
                HStack(spacing: K.Spacing.xs) {
                    Label("\(workout.exercises.count)", systemImage: "figure.strengthtraining.traditional")
                    Text("·")
                    Label("~\(workout.estimatedMinutes)m", systemImage: "clock")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isToday ? .white.opacity(0.8) : K.Colors.tertiary)

                // Per-workout progress bar
                if !workout.isCompleted && workout.completionProgress > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(isToday ? Color.white.opacity(0.2) : K.Colors.surfaceBorder)
                                .frame(height: 2)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(isToday ? Color.white.opacity(0.8) : K.Colors.accent)
                                .frame(width: geo.size.width * workout.completionProgress, height: 2)
                        }
                    }
                    .frame(height: 2)
                }
            }
            .padding(K.Spacing.md)
            .frame(width: 120)
            .background(
                isToday ? K.Colors.accent :
                workout.isCompleted ? K.Colors.success.opacity(0.08) :
                K.Colors.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(
                        isToday ? K.Colors.accent : K.Colors.surfaceBorder,
                        lineWidth: isToday ? 0 : 0.5
                    )
            )
        }
    }

    // MARK: - Compact workout cell (completed / upcoming weeks)

    @ViewBuilder
    private func compactWorkoutCell(workout: Workout, status: WeekStatus) -> some View {
        Button {
            selectedWorkout = workout
        } label: {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                HStack {
                    Text("D\(workout.dayIndex + 1)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(K.Colors.secondary)

                    if workout.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(K.Colors.success)
                    }
                }

                Text(shortWorkoutName(workout.name))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(status == .completed ? K.Colors.secondary : K.Colors.primary)
                    .lineLimit(1)
            }
            .padding(K.Spacing.md)
            .frame(width: 90)
            .background(
                workout.isCompleted ? K.Colors.success.opacity(0.08) : K.Colors.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
            .overlay(
                RoundedRectangle(cornerRadius: K.Radius.sharp)
                    .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
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

    /// Returns weeks ordered so the current week appears first,
    /// followed by subsequent weeks, wrapping around to earlier weeks.
    private func orderedWeeks(for program: Program) -> [Int] {
        let total = program.totalWeeks
        let current = program.currentWeek
        return (0..<total).map { offset in
            ((current - 1 + offset) % total) + 1
        }
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
