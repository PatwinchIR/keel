import SwiftUI
import SwiftData
import Charts

struct StrengthChartView: View {
    var displayUnit: WeightUnit = .lbs

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneRepMax.date) private var allMaxes: [OneRepMax]

    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedExercises: Set<String> = []
    @State private var showAccessoryPicker = false
    @State private var rawSelectedDate: Date?
    @State private var availableExercises: [ExerciseInfo] = []
    @State private var allDataPoints: [ChartDataPoint] = []

    private var service: ProgramService {
        ProgramService(modelContext: modelContext)
    }

    private var conversionFactor: Double {
        displayUnit == .kg ? 1.0 / 2.205 : 1.0
    }

    // MARK: - Filtered Data

    private var filteredPoints: [ChartDataPoint] {
        let dateFloor = selectedTimeRange.dateFloor ?? Date.distantPast
        return allDataPoints.filter { point in
            point.date >= dateFloor && selectedExercises.contains(point.exerciseName)
        }
        .sorted { $0.date < $1.date }
    }

    private var colorDomain: [String] {
        selectedExercises.sorted()
    }

    private var colorRange: [Color] {
        colorDomain.map { K.Colors.chartColor(for: $0) }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            Text("STRENGTH")
                .sectionHeader()
                .padding(.horizontal, K.Spacing.lg)

            if allDataPoints.isEmpty {
                emptyState
            } else {
                // Time range + exercises button on one row
                HStack {
                    TimeRangePicker(selection: $selectedTimeRange)
                    Spacer()
                    Button {
                        showAccessoryPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Exercises")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(K.Colors.accent)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)

                if filteredPoints.isEmpty {
                    noSelectionState
                } else {
                    strengthLineChart
                }
            }
        }
        .sheet(isPresented: $showAccessoryPicker) {
            ExercisePickerSheet(
                exercises: availableExercises,
                selected: $selectedExercises
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            loadChartData()
        }
        .onChange(of: allMaxes.count) {
            loadChartData()
        }
    }

    // MARK: - Data Loading

    private func loadChartData() {
        var compoundNames = Set(CompoundLift.allCases.map(\.displayName))
        compoundNames.insert("Reset Deadlift") // Variant of Deadlift, not a separate accessory

        var exerciseDataByDay: [String: [Date: Double]] = [:]

        // Compounds: only official OneRepMax records
        for record in allMaxes {
            let name = record.lift.displayName
            let day = Calendar.current.startOfDay(for: record.date)
            var dayMap = exerciseDataByDay[name, default: [:]]
            dayMap[day] = max(dayMap[day] ?? 0, record.weight)
            exerciseDataByDay[name] = dayMap
        }

        // Accessories: estimated 1RMs from completed sets
        let allHistories = service.allEstimatedOneRMHistories()
        for (name, entries) in allHistories where !compoundNames.contains(name) {
            var dayMap: [Date: Double] = [:]
            for entry in entries {
                dayMap[entry.date] = max(dayMap[entry.date] ?? 0, entry.estimated1RM)
            }
            exerciseDataByDay[name] = dayMap
        }

        // Convert to flat ChartDataPoint array
        var points: [ChartDataPoint] = []
        for (name, dayMap) in exerciseDataByDay {
            let isCompound = compoundNames.contains(name)
            for (date, weight) in dayMap {
                points.append(ChartDataPoint(
                    exerciseName: name,
                    date: date,
                    estimatedOneRM: weight,
                    isCompound: isCompound
                ))
            }
        }

        allDataPoints = points

        // Build available exercises list
        let compoundLiftsByName = Dictionary(
            uniqueKeysWithValues: CompoundLift.allCases.map { ($0.displayName, $0) }
        )
        let grouped = Dictionary(grouping: allDataPoints, by: \.exerciseName)
        var exercises = grouped.keys.map { name in
            ExerciseInfo(
                name: name,
                isCompound: compoundNames.contains(name),
                color: K.Colors.chartColor(for: name),
                shortName: compoundLiftsByName[name]?.shortName
            )
        }
        // Sort: compounds first (in enum order), then alphabetical accessories
        exercises.sort { a, b in
            if a.isCompound != b.isCompound { return a.isCompound }
            return a.name < b.name
        }
        availableExercises = exercises

        // Auto-select compounds that have data (always add new compounds)
        let compoundsWithData = Set(exercises.filter(\.isCompound).map(\.name))
        if selectedExercises.isEmpty {
            selectedExercises = compoundsWithData
        } else {
            selectedExercises.formUnion(compoundsWithData)
        }
    }

    // MARK: - Line Chart

    @ViewBuilder
    private var strengthLineChart: some View {
        let points = filteredPoints
        let cf = conversionFactor
        let weights = points.map { $0.estimatedOneRM * cf }
        let minW = weights.min() ?? 0
        let maxW = weights.max() ?? 0
        let padding = max((maxW - minW) * 0.15, 10)
        let snappedSelection: Date? = rawSelectedDate.map { snappedDate(for: $0, in: points) }

        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("1RM", point.estimatedOneRM * cf),
                    series: .value("Exercise", point.exerciseName)
                )
                .foregroundStyle(by: .value("Exercise", point.exerciseName))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("1RM", point.estimatedOneRM * cf)
                )
                .foregroundStyle(by: .value("Exercise", point.exerciseName))
                .symbolSize(40)
            }

            // Vertical rule aligned by the chart engine — no manual offset
            if let snapped = snappedSelection {
                RuleMark(x: .value("Selected", snapped))
                    .foregroundStyle(K.Colors.tertiary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
        .chartYScale(domain: (minW - padding)...(maxW + padding))
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    .foregroundStyle(K.Colors.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v)) \(displayUnit.label)")
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }
        }
        .chartOverlay { chartProxy in
            GeometryReader { geoProxy in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let date: Date = chartProxy.value(atX: value.location.x) {
                                    rawSelectedDate = date
                                }
                            }
                            .onEnded { _ in
                                rawSelectedDate = nil
                            }
                    )

                // Tooltip card only — vertical line is handled by RuleMark
                if let selectedDate = rawSelectedDate {
                    let snapped = snappedDate(for: selectedDate, in: points)
                    if let xPos = chartProxy.position(forX: snapped) {
                        ChartTooltipView(
                            points: points,
                            selectedDate: selectedDate,
                            displayUnit: displayUnit,
                            xPosition: xPos,
                            containerWidth: geoProxy.size.width
                        )
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .frame(height: 250)
        .padding(.horizontal, K.Spacing.lg)
    }

    // MARK: - Helpers

    private func snappedDate(for date: Date, in points: [ChartDataPoint]) -> Date {
        let uniqueDates = Set(points.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDates.min(by: {
            abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date))
        }) ?? date
    }

    // MARK: - Empty States

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: K.Spacing.md) {
            Text("No strength data yet")
                .font(.keelBody)
                .foregroundStyle(K.Colors.secondary)

            Text("Complete an AMRAP test or add historical 1RM records")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, K.Spacing.xxl)
    }

    @ViewBuilder
    private var noSelectionState: some View {
        VStack(spacing: K.Spacing.md) {
            Text("Select exercises above to see trends")
                .font(.keelCaption)
                .foregroundStyle(K.Colors.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, K.Spacing.xl)
    }
}
