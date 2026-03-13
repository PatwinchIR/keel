import SwiftUI
import SwiftData
import Charts

struct WorkoutAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutHistory.completedAt, order: .reverse) private var allHistory: [WorkoutHistory]

    @State private var selectedWorkoutFilter: String = "All"
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedDetail: WorkoutHistory?
    @State private var chartMode: ChartMode = .volume
    @State private var selectedExercise: String?
    @State private var selectedMuscleGroup: MuscleGroup?

    enum ChartMode: String, CaseIterable {
        case volume = "Volume"
        case duration = "Duration"
        case rest = "Rest"
        case muscleGroups = "Muscles"
        case exercise = "Exercise"
    }

    private var service: ProgramService {
        ProgramService(modelContext: modelContext)
    }

    private var filteredHistory: [WorkoutHistory] {
        var result = allHistory
        if selectedWorkoutFilter != "All" {
            result = result.filter { $0.workoutName == selectedWorkoutFilter }
        }
        if let floor = selectedTimeRange.dateFloor {
            result = result.filter { $0.completedAt >= floor }
        }
        return result
    }

    private var workoutNames: [String] {
        let names = Set(allHistory.map(\.workoutName))
        return ["All"] + names.sorted()
    }

    private var currentCycleNumber: Int? {
        allHistory.first?.cycleNumber
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.xl) {
                if allHistory.isEmpty {
                    emptyState
                } else {
                    summaryStatsCard
                    chartSection
                    historyListSection
                }

                Spacer(minLength: 100)
            }
        }
        .sheet(item: $selectedDetail) { record in
            WorkoutHistoryDetailView(workout: record)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: K.Spacing.md) {
            Text("No workout history yet")
                .font(.keelBody)
                .foregroundStyle(K.Colors.secondary)

            Text("Complete workouts to see analytics here")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, K.Spacing.xxl)
    }

    // MARK: - Summary Stats Card

    @ViewBuilder
    private var summaryStatsCard: some View {
        VStack(alignment: .leading, spacing: K.Spacing.lg) {
            if let cycle = currentCycleNumber {
                let cycleHistory = allHistory.filter { $0.cycleNumber == cycle }
                statBlock(label: "THIS CYCLE", history: cycleHistory)
            }

            statBlock(label: "ALL TIME", history: allHistory)
        }
        .keelCard()
        .padding(.horizontal, K.Spacing.lg)
        .padding(.top, K.Spacing.sm)
    }

    @ViewBuilder
    private func statBlock(label: String, history: [WorkoutHistory]) -> some View {
        let totalVol = history.reduce(0.0) { $0 + $1.totalVolume }
        let avgDuration = history.isEmpty ? 0 : history.reduce(0) { $0 + $1.durationSeconds } / history.count
        let avgDurationMin = avgDuration / 60
        let avgRest = {
            let rests = history.compactMap(\.averageRestSeconds)
            guard !rests.isEmpty else { return 0.0 }
            return rests.reduce(0, +) / Double(rests.count)
        }()
        let totalHours = Double(history.reduce(0) { $0 + $1.durationSeconds }) / 3600.0

        VStack(alignment: .leading, spacing: K.Spacing.xs) {
            Text(label)
                .sectionHeader()

            HStack(spacing: K.Spacing.lg) {
                statItem(value: "\(history.count)", label: "workouts")
                statItem(value: formatVolume(totalVol), label: "volume")
                statItem(value: "\(avgDurationMin)m", label: "avg time")
                if avgRest > 0 {
                    statItem(value: formatRestTime(avgRest), label: "avg rest")
                }
            }

            if totalHours >= 1 {
                Text("\(String(format: "%.1f", totalHours)) total hours")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(K.Colors.tertiary)
            }
        }
    }

    @ViewBuilder
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(K.Colors.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(K.Colors.tertiary)
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Text("TRENDS")
                    .sectionHeader()
                Spacer()
                TimeRangePicker(selection: $selectedTimeRange)
            }
            .padding(.horizontal, K.Spacing.lg)

            // Filter row
            HStack(spacing: K.Spacing.sm) {
                chartModePicker
                Spacer()
                workoutFilterMenu
            }
            .padding(.horizontal, K.Spacing.lg)

            let trendData = filteredHistory.reversed()
            if chartMode == .muscleGroups {
                muscleGroupBreakdown
            } else if chartMode == .exercise {
                exerciseVolumeSection
            } else if trendData.count >= 2 {
                switch chartMode {
                case .volume:
                    volumeChart(data: Array(trendData))
                case .duration:
                    durationChart(data: Array(trendData))
                case .rest:
                    restChart(data: Array(trendData))
                case .muscleGroups, .exercise:
                    EmptyView() // handled above
                }
            } else {
                Text("Need at least 2 workouts to show trends")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.xl)
            }
        }
    }

    @ViewBuilder
    private var chartModePicker: some View {
        HStack(spacing: 0) {
            ForEach(ChartMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(K.Animation.fast) {
                        chartMode = mode
                    }
                } label: {
                    // Reserve space for the bold variant so width never changes
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .hidden()
                        .overlay {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: chartMode == mode ? .bold : .medium))
                                .foregroundStyle(chartMode == mode ? K.Colors.accent : K.Colors.tertiary)
                        }
                        .padding(.horizontal, K.Spacing.sm)
                        .padding(.vertical, K.Spacing.xs)
                        .background(
                            chartMode == mode
                                ? K.Colors.accent.opacity(0.12)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
            }
        }
    }

    @ViewBuilder
    private var workoutFilterMenu: some View {
        Menu {
            ForEach(workoutNames, id: \.self) { name in
                Button {
                    selectedWorkoutFilter = name
                } label: {
                    HStack {
                        Text(name)
                        if name == selectedWorkoutFilter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedWorkoutFilter == "All" ? "All Workouts" : selectedWorkoutFilter)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(K.Colors.accent)
        }
    }

    // MARK: - Volume Chart

    @ViewBuilder
    private func volumeChart(data: [WorkoutHistory]) -> some View {
        let volumes = data.map(\.totalVolume)
        let minV = volumes.min() ?? 0
        let maxV = volumes.max() ?? 0
        let padding = max((maxV - minV) * 0.15, 100)

        Chart {
            ForEach(data, id: \.id) { wh in
                LineMark(
                    x: .value("Date", wh.completedAt),
                    y: .value("Volume", wh.totalVolume)
                )
                .foregroundStyle(K.Colors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", wh.completedAt),
                    y: .value("Volume", wh.totalVolume)
                )
                .foregroundStyle(K.Colors.accent)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: max(0, minV - padding)...(maxV + padding))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(formatVolume(v))
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(K.Colors.secondary)
            }
        }
        .chartLegend(.hidden)
        .frame(height: 200)
        .padding(.horizontal, K.Spacing.lg)
    }

    // MARK: - Duration Chart

    @ViewBuilder
    private func durationChart(data: [WorkoutHistory]) -> some View {
        let durations = data.map { Double($0.durationSeconds) / 60.0 }
        let minD = durations.min() ?? 0
        let maxD = durations.max() ?? 0
        let padding = max((maxD - minD) * 0.15, 5)

        Chart {
            ForEach(data, id: \.id) { wh in
                let mins = Double(wh.durationSeconds) / 60.0
                LineMark(
                    x: .value("Date", wh.completedAt),
                    y: .value("Duration", mins)
                )
                .foregroundStyle(K.Colors.bench)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", wh.completedAt),
                    y: .value("Duration", mins)
                )
                .foregroundStyle(K.Colors.bench)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: max(0, minD - padding)...(maxD + padding))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))m")
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(K.Colors.secondary)
            }
        }
        .chartLegend(.hidden)
        .frame(height: 200)
        .padding(.horizontal, K.Spacing.lg)
    }

    // MARK: - Rest Time Chart

    @ViewBuilder
    private func restChart(data: [WorkoutHistory]) -> some View {
        let withRest = data.filter { $0.averageRestSeconds != nil }

        if withRest.count >= 2 {
            let rests = withRest.compactMap(\.averageRestSeconds)
            let minR = rests.min() ?? 0
            let maxR = rests.max() ?? 0
            let padding = max((maxR - minR) * 0.15, 15)

            Chart {
                ForEach(withRest, id: \.id) { wh in
                    if let rest = wh.averageRestSeconds {
                        LineMark(
                            x: .value("Date", wh.completedAt),
                            y: .value("Rest", rest)
                        )
                        .foregroundStyle(K.Colors.deadlift)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", wh.completedAt),
                            y: .value("Rest", rest)
                        )
                        .foregroundStyle(K.Colors.deadlift)
                        .symbolSize(30)
                    }
                }
            }
            .chartYScale(domain: max(0, minR - padding)...(maxR + padding))
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatRestTime(v))
                                .foregroundStyle(K.Colors.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .chartLegend(.hidden)
            .frame(height: 200)
            .padding(.horizontal, K.Spacing.lg)
        } else {
            Text("Not enough rest time data yet")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.xl)
        }
    }

    // MARK: - History List

    @ViewBuilder
    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            Text("HISTORY")
                .sectionHeader()
                .padding(.horizontal, K.Spacing.lg)

            ForEach(filteredHistory) { record in
                Button {
                    selectedDetail = record
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    WorkoutHistoryRow(workout: record)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, K.Spacing.lg)
            }
        }
    }

    // MARK: - Exercise Volume Trend

    private var distinctExerciseNames: [String] {
        var names = Set<String>()
        for wh in allHistory {
            for set in wh.sets where !set.isSkipped && set.setType == .working {
                names.insert(set.exerciseName)
            }
        }
        return names.sorted()
    }

    private var exerciseVolumeTrendData: [(date: Date, volume: Double)] {
        guard let exerciseName = selectedExercise else { return [] }
        var result: [(date: Date, volume: Double)] = []
        for wh in filteredHistory {
            let exerciseSets = wh.sets.filter {
                $0.exerciseName == exerciseName && !$0.isSkipped && $0.setType == .working
            }
            if !exerciseSets.isEmpty {
                let vol = exerciseSets.reduce(0.0) { $0 + $1.volume }
                result.append((date: wh.completedAt, volume: vol))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private var exerciseVolumeSection: some View {
        let exercises = distinctExerciseNames

        if exercises.isEmpty {
            Text("No exercise data yet")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: K.Spacing.sm) {
                // Exercise picker
                Menu {
                    ForEach(exercises, id: \.self) { name in
                        Button {
                            selectedExercise = name
                        } label: {
                            HStack {
                                Text(name)
                                if name == selectedExercise {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedExercise ?? "Select Exercise")
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(K.Colors.accent)
                    .padding(.horizontal, K.Spacing.sm)
                    .padding(.vertical, K.Spacing.xs)
                    .background(K.Colors.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
                .padding(.horizontal, K.Spacing.lg)
                .onAppear {
                    if selectedExercise == nil {
                        selectedExercise = exercises.first
                    }
                }

                let data = exerciseVolumeTrendData
                if data.count >= 2 {
                    exerciseVolumeChart(data: data)
                } else if selectedExercise != nil {
                    Text(data.isEmpty ? "No data for this exercise" : "Need at least 2 sessions to show trends")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.xl)
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseVolumeChart(data: [(date: Date, volume: Double)]) -> some View {
        let volumes = data.map(\.volume)
        let minV = volumes.min() ?? 0
        let maxV = volumes.max() ?? 0
        let padding = max((maxV - minV) * 0.15, 100)
        let exerciseColor = K.Colors.chartColor(for: selectedExercise ?? "")

        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(exerciseColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(exerciseColor)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: max(0, minV - padding)...(maxV + padding))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(formatVolume(v))
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(K.Colors.secondary)
            }
        }
        .chartLegend(.hidden)
        .frame(height: 200)
        .padding(.horizontal, K.Spacing.lg)
    }

    // MARK: - Muscle Group Breakdown

    private var muscleGroupVolumeData: [(group: MuscleGroup, volume: Double, sets: Int)] {
        var volumeByGroup: [MuscleGroup: Double] = [:]
        var setsByGroup: [MuscleGroup: Int] = [:]

        for wh in filteredHistory {
            for set in wh.sets where !set.isSkipped && set.setType == .working {
                let groups = set.muscleGroups
                guard !groups.isEmpty else { continue }
                let vol = set.volume
                // Split volume equally across muscle groups for the set
                let share = vol / Double(groups.count)
                for group in groups {
                    volumeByGroup[group, default: 0] += share
                    setsByGroup[group, default: 0] += 1
                }
            }
        }

        return MuscleGroup.allCases.compactMap { group in
            guard let vol = volumeByGroup[group], vol > 0 else { return nil }
            return (group: group, volume: vol, sets: setsByGroup[group] ?? 0)
        }.sorted { $0.volume > $1.volume }
    }

    @ViewBuilder
    private var muscleGroupBreakdown: some View {
        let data = muscleGroupVolumeData
        if data.isEmpty {
            Text("No muscle group data yet")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: K.Spacing.sm) {
                // Bar chart
                Chart {
                    ForEach(data, id: \.group) { item in
                        BarMark(
                            x: .value("Volume", item.volume),
                            y: .value("Muscle", item.group.shortName)
                        )
                        .foregroundStyle(item.group.color)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .foregroundStyle(K.Colors.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(data.count) * 32 + 20)
                .padding(.horizontal, K.Spacing.lg)

                // Detail rows
                VStack(spacing: K.Spacing.xs) {
                    ForEach(data, id: \.group) { item in
                        Button {
                            withAnimation(K.Animation.fast) {
                                selectedMuscleGroup = item.group
                            }
                        } label: {
                            HStack(spacing: K.Spacing.sm) {
                                Circle()
                                    .fill(item.group.color)
                                    .frame(width: 10, height: 10)
                                Text(item.group.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(K.Colors.primary)
                                Spacer()
                                Text("\(item.sets) sets")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(K.Colors.tertiary)
                                Text(formatVolume(item.volume))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(K.Colors.primary)
                                    .frame(width: 60, alignment: .trailing)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(selectedMuscleGroup == item.group ? item.group.color : K.Colors.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)

                // Muscle group volume trend
                if let group = selectedMuscleGroup {
                    muscleGroupTrendSection(group: group)
                }
            }
        }
    }

    private func muscleGroupTrendData(for group: MuscleGroup) -> [(date: Date, volume: Double)] {
        var result: [(date: Date, volume: Double)] = []
        for wh in filteredHistory {
            var vol = 0.0
            for set in wh.sets where !set.isSkipped && set.setType == .working {
                let groups = set.muscleGroups
                if groups.contains(group) {
                    vol += set.volume / Double(groups.count)
                }
            }
            if vol > 0 {
                result.append((date: wh.completedAt, volume: vol))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private func muscleGroupTrendSection(group: MuscleGroup) -> some View {
        let data = muscleGroupTrendData(for: group)

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Circle()
                    .fill(group.color)
                    .frame(width: 8, height: 8)
                Text("\(group.displayName) Volume Trend")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(K.Colors.primary)
                Spacer()
                Button {
                    withAnimation(K.Animation.fast) {
                        selectedMuscleGroup = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(K.Colors.tertiary)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            if data.count >= 2 {
                let volumes = data.map(\.volume)
                let minV = volumes.min() ?? 0
                let maxV = volumes.max() ?? 0
                let padding = max((maxV - minV) * 0.15, 100)

                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(group.color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(group.color)
                        .symbolSize(30)
                    }
                }
                .chartYScale(domain: max(0, minV - padding)...(maxV + padding))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .foregroundStyle(K.Colors.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 180)
                .padding(.horizontal, K.Spacing.lg)
            } else {
                Text(data.isEmpty ? "No data for \(group.displayName)" : "Need at least 2 workouts to show trend")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.md)
            }
        }
        .padding(.top, K.Spacing.sm)
    }

    // MARK: - Formatting Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: volume)) ?? "\(Int(volume))"
        }
        return "\(Int(volume))"
    }

    private func formatRestTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
