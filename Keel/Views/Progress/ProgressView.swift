import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKitService
    @Query(sort: \OneRepMax.date) private var allMaxes: [OneRepMax]
    @Query(sort: \BodyComposition.date) private var bodyComp: [BodyComposition]

    @State private var showCalculator = false
    @State private var showAddHistory = false
    @State private var displayUnit: WeightUnit = .lbs
    @State private var editingRecord: OneRepMax?
    @State private var progressTab: ProgressTab = .strength

    enum ProgressTab: String, CaseIterable {
        case strength = "Strength"
        case workouts = "Workouts"
        case body = "Body"
    }

    private var service: ProgramService {
        ProgramService(modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Segmented control
                progressTabPicker
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.top, K.Spacing.sm)
                    .padding(.bottom, K.Spacing.sm)

                switch progressTab {
                case .strength:
                    strengthContent
                case .workouts:
                    WorkoutAnalyticsView()
                case .body:
                    bodyContent
                }
            }
        }
        .sheet(isPresented: $showCalculator) {
            OneRMCalculatorView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddHistory) {
            AddOneRMView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingRecord) { record in
            EditOneRMView(record: record)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Tab Picker

    @ViewBuilder
    private var progressTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProgressTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(K.Animation.fast) {
                        progressTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: progressTab == tab ? .bold : .medium))
                        .foregroundStyle(progressTab == tab ? K.Colors.accent : K.Colors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.sm)
                        .background(
                            progressTab == tab
                                ? K.Colors.accent.opacity(0.12)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
            }
        }
        .background(K.Colors.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
        .overlay(
            RoundedRectangle(cornerRadius: K.Radius.sharp)
                .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Strength Content

    @ViewBuilder
    private var strengthContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.xl) {
                oneRMStatsSection
                StrengthChartView(displayUnit: displayUnit)
                historySection

                Spacer(minLength: 100)
            }
        }
    }

    @State private var showAddBodyComp = false

    // MARK: - Body Content

    @ViewBuilder
    private var bodyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: K.Spacing.xl) {
                bodyCompSection
                    .padding(.top, K.Spacing.sm)

                Spacer(minLength: 100)
            }
        }
        .sheet(isPresented: $showAddBodyComp) {
            AddBodyCompView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 1RM Stats Grid

    @ViewBuilder
    private var oneRMStatsSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            HStack {
                Text("1RM RECORDS")
                    .sectionHeader()
                Spacer()
                Picker("", selection: $displayUnit) {
                    Text("LBS").tag(WeightUnit.lbs)
                    Text("KG").tag(WeightUnit.kg)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding(.horizontal, K.Spacing.lg)
            .padding(.top, K.Spacing.lg)

            totalCard
                .padding(.horizontal, K.Spacing.lg)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: K.Spacing.sm) {
                ForEach(CompoundLift.allCases) { lift in
                    compactMaxCard(lift)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            // Action buttons
            HStack(spacing: K.Spacing.sm) {
                Button { showCalculator = true } label: {
                    HStack(spacing: K.Spacing.xs) {
                        Image(systemName: "function")
                        Text("Calculator")
                    }
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: K.Radius.sharp)
                            .stroke(K.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                }

                Button { showAddHistory = true } label: {
                    HStack(spacing: K.Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Record")
                    }
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: K.Radius.sharp)
                            .stroke(K.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, K.Spacing.lg)
        }
    }

    @ViewBuilder
    private var totalCard: some View {
        let totals: [(lift: CompoundLift, weight: Double)] = CompoundLift.allCases.compactMap { lift in
            guard let latest = service.oneRepMaxHistory(for: lift).last else { return nil }
            return (lift, latest.weight)
        }
        let totalLbs = totals.reduce(0.0) { $0 + $1.weight }
        let totalDisplay = displayUnit == .kg ? totalLbs / 2.205 : totalLbs

        HStack {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                Text("TOTAL")
                    .sectionHeader()

                if totals.isEmpty {
                    Text("—")
                        .font(.keelWeight)
                        .foregroundStyle(K.Colors.tertiary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: K.Spacing.xs) {
                        Text("\(Int(totalDisplay))")
                            .font(.keelWeight)
                            .foregroundStyle(K.Colors.accent)
                            .monospacedDigit()
                        Text(displayUnit.label)
                            .font(.caption2)
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
            }

            Spacer()

            if !totals.isEmpty {
                HStack(spacing: K.Spacing.md) {
                    ForEach(totals, id: \.lift) { item in
                        let w = displayUnit == .kg ? item.weight / 2.205 : item.weight
                        VStack(spacing: 2) {
                            Text(item.lift.shortName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(item.lift.chartColor)
                            Text("\(Int(w))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.secondary)
                        }
                    }
                }
            }
        }
        .keelCard(padding: K.Spacing.md)
    }

    @ViewBuilder
    private func compactMaxCard(_ lift: CompoundLift) -> some View {
        let history = service.oneRepMaxHistory(for: lift)
        let current = history.last

        HStack {
            VStack(alignment: .leading, spacing: K.Spacing.xs) {
                HStack(spacing: K.Spacing.xs) {
                    Circle()
                        .fill(lift.chartColor)
                        .frame(width: 8, height: 8)
                    Text(lift.displayName)
                        .sectionHeader()
                }

                if let current {
                    let displayWeight = displayUnit == .kg
                        ? current.weight / 2.205
                        : current.weight
                    HStack(alignment: .firstTextBaseline, spacing: K.Spacing.xs) {
                        Text("\(Int(displayWeight))")
                            .font(.keelWeight)
                            .foregroundStyle(lift.chartColor)
                            .monospacedDigit()
                        Text(displayUnit.label)
                            .font(.caption2)
                            .foregroundStyle(K.Colors.secondary)
                    }
                } else {
                    Text("—")
                        .font(.keelWeight)
                        .foregroundStyle(K.Colors.tertiary)
                }
            }

            Spacer(minLength: 4)

            if let current = current, history.count >= 2 {
                let prev = history[history.count - 2].weight
                let pct = ((current.weight - prev) / prev) * 100
                VStack(spacing: 2) {
                    Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(pct >= 0 ? "+" : "")\(String(format: "%.1f", pct))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(pct >= 0 ? K.Colors.pr : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .keelCard(padding: K.Spacing.md)
    }

    // MARK: - Body Composition

    /// Merges manual BodyComposition entries with HealthKit body weight samples.
    /// Deduplicates by date (manual entries take priority).
    private var mergedWeightData: [(date: Date, weight: Double)] {
        let calendar = Calendar.current
        var byDay: [Date: Double] = [:]

        // HealthKit data first (lower priority)
        for entry in healthKitService.bodyWeightHistory {
            let day = calendar.startOfDay(for: entry.date)
            byDay[day] = entry.weight
        }

        // Manual entries override
        for entry in bodyComp {
            if let weight = entry.bodyWeight {
                let day = calendar.startOfDay(for: entry.date)
                byDay[day] = weight
            }
        }

        return byDay.map { (date: $0.key, weight: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// Merges manual BodyComposition entries with HealthKit body fat samples.
    private var mergedBodyFatData: [(date: Date, bodyFat: Double)] {
        let calendar = Calendar.current
        var byDay: [Date: Double] = [:]

        for entry in healthKitService.bodyFatHistory {
            let day = calendar.startOfDay(for: entry.date)
            byDay[day] = entry.bodyFat
        }

        for entry in bodyComp {
            if let bf = entry.bodyFat {
                let day = calendar.startOfDay(for: entry.date)
                byDay[day] = bf
            }
        }

        return byDay.map { (date: $0.key, bodyFat: $0.value) }
            .sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private var bodyCompSection: some View {
        let weightData = mergedWeightData
        let fatData = mergedBodyFatData
        let hasData = !weightData.isEmpty || !fatData.isEmpty

        VStack(alignment: .leading, spacing: K.Spacing.xl) {
            HStack {
                Text("BODY COMPOSITION")
                    .sectionHeader()
                Spacer()
                Button { showAddBodyComp = true } label: {
                    HStack(spacing: K.Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Entry")
                    }
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.accent)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            if !hasData {
                VStack(spacing: K.Spacing.md) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 32))
                        .foregroundStyle(K.Colors.tertiary)

                    Text("No body composition data yet")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)

                    Text("Data from Apple Health will appear automatically, or add entries manually")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.tertiary)
                        .multilineTextAlignment(.center)

                    Button { showAddBodyComp = true } label: {
                        Text("Add First Entry")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(K.Colors.accent)
                            .padding(.horizontal, K.Spacing.lg)
                            .padding(.vertical, K.Spacing.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: K.Radius.sharp)
                                    .stroke(K.Colors.accent.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.top, K.Spacing.xs)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, K.Spacing.xxl)
            } else {
                bodyTimeRangePicker

                if !weightData.isEmpty {
                    bodyWeightChart(weightData)
                }

                if !fatData.isEmpty {
                    bodyFatChart(fatData)
                }

                let massData = mergedMassData
                if !massData.isEmpty {
                    massBreakdownChart(massData)
                }

                bodyCompHistoryList
            }
        }
    }

    @State private var selectedChartDate: Date?
    @State private var bodyTimeRange: BodyTimeRange = .threeMonths

    enum BodyTimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"

        var startDate: Date? {
            let cal = Calendar.current
            switch self {
            case .oneMonth: return cal.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths: return cal.date(byAdding: .month, value: -6, to: Date())
            case .oneYear: return cal.date(byAdding: .year, value: -1, to: Date())
            case .all: return nil
            }
        }

        func xAxisStride(dataMonths: Int) -> Calendar.Component {
            switch self {
            case .oneMonth: return .weekOfYear
            case .threeMonths: return .month
            case .sixMonths: return .month
            case .oneYear: return .month
            case .all: return dataMonths > 24 ? .year : .month
            }
        }

        func xAxisStrideCount(dataMonths: Int) -> Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 1
            case .sixMonths: return 2
            case .oneYear: return 3
            case .all:
                if dataMonths > 24 { return 1 }         // yearly
                if dataMonths > 12 { return 6 }         // every 6 months
                return 3                                  // every 3 months
            }
        }

        func xAxisFormat(dataMonths: Int) -> Date.FormatStyle {
            switch self {
            case .oneMonth: return .dateTime.month(.abbreviated).day()
            case .threeMonths: return .dateTime.month(.abbreviated)
            case .sixMonths: return .dateTime.month(.abbreviated)
            case .oneYear: return .dateTime.month(.abbreviated)
            case .all:
                if dataMonths > 12 { return .dateTime.month(.narrow).year(.twoDigits) }
                return .dateTime.month(.abbreviated)
            }
        }
    }

    private func dataSpanMonths(_ dates: [Date]) -> Int {
        guard let first = dates.first, let last = dates.last else { return 0 }
        return max(1, Calendar.current.dateComponents([.month], from: first, to: last).month ?? 0)
    }

    private var selectionDateFormat: Date.FormatStyle {
        .dateTime.month(.abbreviated).day().year()
    }

    private func filteredData<T>(_ data: [(date: Date, value: T)]) -> [(date: Date, value: T)] {
        guard let start = bodyTimeRange.startDate else { return data }
        return data.filter { $0.date >= start }
    }

    /// Computed lean body mass and fat mass from merged weight + body fat data
    private var mergedMassData: [(date: Date, lean: Double, fat: Double)] {
        let calendar = Calendar.current
        let weightByDay = Dictionary(
            mergedWeightData.map { (calendar.startOfDay(for: $0.date), $0.weight) },
            uniquingKeysWith: { _, new in new }
        )
        let fatByDay = Dictionary(
            mergedBodyFatData.map { (calendar.startOfDay(for: $0.date), $0.bodyFat) },
            uniquingKeysWith: { _, new in new }
        )

        // Also pull HealthKit lean body mass for days we don't have computed data
        let lbmByDay = Dictionary(
            healthKitService.leanBodyMassHistory.map { (calendar.startOfDay(for: $0.date), $0.mass) },
            uniquingKeysWith: { _, new in new }
        )

        var result: [(date: Date, lean: Double, fat: Double)] = []

        // Days where we have both weight and BF% → compute
        let allDays = Set(weightByDay.keys).union(lbmByDay.keys).sorted()
        for day in allDays {
            if let weight = weightByDay[day], let bf = fatByDay[day] {
                let fatMass = weight * bf / 100
                let leanMass = weight - fatMass
                result.append((date: day, lean: leanMass, fat: fatMass))
            } else if let lbm = lbmByDay[day], let weight = weightByDay[day] {
                let fatMass = weight - lbm
                result.append((date: day, lean: lbm, fat: max(0, fatMass)))
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    private func nearestEntry<T>(in data: [(date: Date, value: T)], to target: Date) -> (date: Date, value: T)? {
        guard !data.isEmpty else { return nil }
        return data.min(by: { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) })
    }

    @ViewBuilder
    private var bodyTimeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(BodyTimeRange.allCases, id: \.rawValue) { range in
                Button {
                    withAnimation(K.Animation.fast) {
                        bodyTimeRange = range
                        selectedChartDate = nil
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 12, weight: bodyTimeRange == range ? .bold : .medium))
                        .foregroundStyle(bodyTimeRange == range ? K.Colors.accent : K.Colors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, K.Spacing.xs)
                        .background(
                            bodyTimeRange == range
                                ? K.Colors.accent.opacity(0.12)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
            }
        }
        .background(K.Colors.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
        .overlay(
            RoundedRectangle(cornerRadius: K.Radius.sharp)
                .stroke(K.Colors.surfaceBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, K.Spacing.lg)
    }

    @ViewBuilder
    private func bodyWeightChart(_ data: [(date: Date, weight: Double)]) -> some View {
        let mapped = data.map { (date: $0.date, value: $0.weight) }
        let filtered = filteredData(mapped)
        let showDots = filtered.count <= 30
        let months = dataSpanMonths(filtered.map(\.date))

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Text("BODY WEIGHT")
                    .sectionHeader()

                Spacer()

                if let sel = selectedChartDate,
                   let entry = nearestEntry(in: filtered, to: sel) {
                    HStack(spacing: K.Spacing.xs) {
                        Text(entry.date.formatted(selectionDateFormat))
                            .font(.system(size: 10))
                            .foregroundStyle(K.Colors.secondary)
                        Text("\(String(format: "%.1f", entry.value)) lbs")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(K.Colors.accent)
                    }
                } else if let latest = filtered.last {
                    Text("\(String(format: "%.1f", latest.value)) lbs")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(K.Colors.accent)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            Chart {
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.value)
                    )
                    .foregroundStyle(K.Colors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    if showDots {
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.value)
                        )
                        .foregroundStyle(K.Colors.accent)
                        .symbolSize(12)
                    }
                }

                if let sel = selectedChartDate {
                    RuleMark(x: .value("Selected", sel))
                        .foregroundStyle(K.Colors.accent.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel().foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: bodyTimeRange.xAxisStride(dataMonths: months), count: bodyTimeRange.xAxisStrideCount(dataMonths: months))) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel(format: bodyTimeRange.xAxisFormat(dataMonths: months))
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXSelection(value: $selectedChartDate)
            .chartLegend(.hidden)
            .frame(height: 200)
            .padding(.horizontal, K.Spacing.lg)
        }
    }

    @ViewBuilder
    private func bodyFatChart(_ data: [(date: Date, bodyFat: Double)]) -> some View {
        let mapped = data.map { (date: $0.date, value: $0.bodyFat) }
        let filtered = filteredData(mapped)
        let showDots = filtered.count <= 30
        let months = dataSpanMonths(filtered.map(\.date))

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Text("BODY FAT %")
                    .sectionHeader()

                Spacer()

                if let sel = selectedChartDate,
                   let entry = nearestEntry(in: filtered, to: sel) {
                    HStack(spacing: K.Spacing.xs) {
                        Text(entry.date.formatted(selectionDateFormat))
                            .font(.system(size: 10))
                            .foregroundStyle(K.Colors.secondary)
                        Text("\(String(format: "%.1f", entry.value))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(K.Colors.pr)
                    }
                } else if let latest = filtered.last {
                    Text("\(String(format: "%.1f", latest.value))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(K.Colors.pr)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            Chart {
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("BF%", entry.value)
                    )
                    .foregroundStyle(K.Colors.pr)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    if showDots {
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("BF%", entry.value)
                        )
                        .foregroundStyle(K.Colors.pr)
                        .symbolSize(12)
                    }
                }

                if let sel = selectedChartDate {
                    RuleMark(x: .value("Selected", sel))
                        .foregroundStyle(K.Colors.pr.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel().foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: bodyTimeRange.xAxisStride(dataMonths: months), count: bodyTimeRange.xAxisStrideCount(dataMonths: months))) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel(format: bodyTimeRange.xAxisFormat(dataMonths: months))
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXSelection(value: $selectedChartDate)
            .chartLegend(.hidden)
            .frame(height: 200)
            .padding(.horizontal, K.Spacing.lg)
        }
    }

    @ViewBuilder
    private func massBreakdownChart(_ data: [(date: Date, lean: Double, fat: Double)]) -> some View {
        let start = bodyTimeRange.startDate
        let filtered = start != nil ? data.filter { $0.date >= start! } : data
        let showDots = filtered.count <= 30
        let months = dataSpanMonths(filtered.map(\.date))

        if !filtered.isEmpty {
        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            HStack {
                Text("MASS BREAKDOWN")
                    .sectionHeader()

                Spacer()

                if let sel = selectedChartDate,
                   let entry = filtered.min(by: { abs($0.date.timeIntervalSince(sel)) < abs($1.date.timeIntervalSince(sel)) }) {
                    HStack(spacing: K.Spacing.sm) {
                        Text(entry.date.formatted(selectionDateFormat))
                            .font(.system(size: 10))
                            .foregroundStyle(K.Colors.secondary)
                        HStack(spacing: K.Spacing.xs) {
                            Circle().fill(K.Colors.accent).frame(width: 6, height: 6)
                            Text("\(String(format: "%.0f", entry.lean))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(K.Colors.accent)
                        }
                        HStack(spacing: K.Spacing.xs) {
                            Circle().fill(K.Colors.pr).frame(width: 6, height: 6)
                            Text("\(String(format: "%.0f", entry.fat))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(K.Colors.pr)
                        }
                    }
                } else if let latest = filtered.last {
                    HStack(spacing: K.Spacing.sm) {
                        HStack(spacing: K.Spacing.xs) {
                            Circle().fill(K.Colors.accent).frame(width: 6, height: 6)
                            Text("Lean \(String(format: "%.0f", latest.lean))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.accent)
                        }
                        HStack(spacing: K.Spacing.xs) {
                            Circle().fill(K.Colors.pr).frame(width: 6, height: 6)
                            Text("Fat \(String(format: "%.0f", latest.fat))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.pr)
                        }
                    }
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            Chart {
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Mass", entry.lean),
                        series: .value("Type", "Lean")
                    )
                    .foregroundStyle(K.Colors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Mass", entry.fat),
                        series: .value("Type", "Fat")
                    )
                    .foregroundStyle(K.Colors.pr)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    if showDots {
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Mass", entry.lean)
                        )
                        .foregroundStyle(K.Colors.accent)
                        .symbolSize(10)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Mass", entry.fat)
                        )
                        .foregroundStyle(K.Colors.pr)
                        .symbolSize(10)
                    }
                }

                if let sel = selectedChartDate {
                    RuleMark(x: .value("Selected", sel))
                        .foregroundStyle(K.Colors.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel().foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: bodyTimeRange.xAxisStride(dataMonths: months), count: bodyTimeRange.xAxisStrideCount(dataMonths: months))) { _ in
                    AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                    AxisValueLabel(format: bodyTimeRange.xAxisFormat(dataMonths: months))
                        .foregroundStyle(K.Colors.secondary)
                }
            }
            .chartXSelection(value: $selectedChartDate)
            .chartLegend(.hidden)
            .frame(height: 200)
            .padding(.horizontal, K.Spacing.lg)
        }
        }
    }

    @ViewBuilder
    private var bodyCompHistoryList: some View {
        let calendar = Calendar.current
        // Merge weight and body fat data by day for history list
        var historyByDay: [Date: (weight: Double?, bodyFat: Double?)] = [:]

        let _ = {
            for entry in mergedWeightData {
                let day = calendar.startOfDay(for: entry.date)
                historyByDay[day, default: (nil, nil)].weight = entry.weight
            }
            for entry in mergedBodyFatData {
                let day = calendar.startOfDay(for: entry.date)
                historyByDay[day, default: (nil, nil)].bodyFat = entry.bodyFat
            }
        }()

        let sortedDays = historyByDay.sorted { $0.key > $1.key }.prefix(20)

        VStack(alignment: .leading, spacing: K.Spacing.sm) {
            Text("HISTORY")
                .sectionHeader()
                .padding(.horizontal, K.Spacing.lg)

            ForEach(Array(sortedDays.enumerated()), id: \.offset) { _, entry in
                HStack {
                    Text(entry.key.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.secondary)

                    Spacer()

                    if let weight = entry.value.weight {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(String(format: "%.1f", weight))")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.primary)
                            Text("lbs")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(K.Colors.tertiary)
                        }
                    }

                    if let bf = entry.value.bodyFat {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(String(format: "%.1f", bf))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.accent)
                            Text("BF")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(K.Colors.tertiary)
                        }
                        .padding(.leading, K.Spacing.md)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.vertical, K.Spacing.xs)
            }
        }
    }

    // MARK: - History Table

    @ViewBuilder
    private var historySection: some View {
        let lifts = CompoundLift.allCases
        let histories = Dictionary(
            grouping: allMaxes,
            by: \.lift
        ).mapValues { $0.sorted { $0.date < $1.date } }
        let maxRows = lifts.map { histories[$0]?.count ?? 0 }.max() ?? 0

        VStack(alignment: .leading, spacing: 0) {
            Text("HISTORY")
                .sectionHeader()
                .padding(.horizontal, K.Spacing.lg)
                .padding(.bottom, K.Spacing.sm)

            if maxRows > 0 {
                // Table header row
                HStack(spacing: 0) {
                    // Cycle/date column
                    Text("")
                        .frame(width: 70, alignment: .leading)

                    ForEach(lifts) { lift in
                        HStack(spacing: K.Spacing.xs) {
                            Circle()
                                .fill(lift.chartColor)
                                .frame(width: 6, height: 6)
                            Text(lift.shortName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(K.Colors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.bottom, K.Spacing.xs)

                // Divider
                Rectangle()
                    .fill(K.Colors.surfaceBorder)
                    .frame(height: 0.5)
                    .padding(.horizontal, K.Spacing.lg)

                // Data rows — most recent first
                ForEach(0..<maxRows, id: \.self) { rowIndex in
                    let reverseIndex = maxRows - 1 - rowIndex
                    // Use the first available record's date for this cycle row
                    let rowDate: Date? = lifts.compactMap { lift in
                        let h = histories[lift] ?? []
                        return reverseIndex < h.count ? h[reverseIndex].date : nil
                    }.first

                    HStack(spacing: 0) {
                        // Cycle label + date
                        VStack(alignment: .leading, spacing: 1) {
                            Text("C\(reverseIndex + 1)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(K.Colors.secondary)
                            if let date = rowDate {
                                Text(date.formatted(.dateTime.month(.abbreviated).year(.twoDigits)))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(K.Colors.tertiary)
                            }
                        }
                        .frame(width: 70, alignment: .leading)

                        // One value per lift
                        ForEach(lifts) { lift in
                            let history = histories[lift] ?? []

                            if reverseIndex < history.count {
                                let record = history[reverseIndex]
                                let w = displayUnit == .kg ? record.weight / 2.205 : record.weight
                                let prevWeight: Double? = reverseIndex > 0 ? history[reverseIndex - 1].weight : nil

                                VStack(spacing: 1) {
                                    Text("\(Int(w))")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(K.Colors.primary)

                                    if let prev = prevWeight, prev > 0 {
                                        let pct = ((record.weight - prev) / prev) * 100
                                        Text("\(pct >= 0 ? "+" : "")\(String(format: "%.0f", pct))%")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundStyle(pct >= 0 ? K.Colors.pr : .red)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture { editingRecord = record }
                                .contextMenu {
                                    Button { editingRecord = record } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        withAnimation {
                                            service.deleteOneRepMax(record)
                                            service.syncCycleNumber()
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            } else {
                                Text("—")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(K.Colors.tertiary.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.vertical, K.Spacing.sm)

                    // Row separator
                    if rowIndex < maxRows - 1 {
                        Rectangle()
                            .fill(K.Colors.surfaceBorder.opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.horizontal, K.Spacing.lg)
                    }
                }
            } else {
                Text("No records yet")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.tertiary)
                    .padding(.horizontal, K.Spacing.lg)
            }
        }
    }
}
