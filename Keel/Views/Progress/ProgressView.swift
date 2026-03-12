import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneRepMax.date) private var allMaxes: [OneRepMax]
    @Query(sort: \BodyComposition.date) private var bodyComp: [BodyComposition]

    @State private var showCalculator = false
    @State private var showAddHistory = false
    @State private var displayUnit: WeightUnit = .lbs
    @State private var editingRecord: OneRepMax?

    private var service: ProgramService {
        ProgramService(modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.xl) {
                    oneRMStatsSection
                    StrengthChartView(displayUnit: displayUnit)
                    bodyCompSection
                    historySection

                    Spacer(minLength: 100)
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

    @ViewBuilder
    private var bodyCompSection: some View {
        if !bodyComp.isEmpty {
            let weightData = bodyComp.filter { $0.bodyWeight != nil }
            if !weightData.isEmpty {
                VStack(alignment: .leading, spacing: K.Spacing.sm) {
                    Text("BODY WEIGHT")
                        .sectionHeader()
                        .padding(.horizontal, K.Spacing.lg)

                    Chart {
                        ForEach(weightData) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.bodyWeight ?? 0)
                            )
                            .foregroundStyle(K.Colors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                            AxisValueLabel().foregroundStyle(K.Colors.secondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                            AxisValueLabel().foregroundStyle(K.Colors.secondary)
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal, K.Spacing.lg)
                }
            }

            let fatData = bodyComp.filter { $0.bodyFat != nil }
            if !fatData.isEmpty {
                VStack(alignment: .leading, spacing: K.Spacing.sm) {
                    Text("BODY FAT %")
                        .sectionHeader()
                        .padding(.horizontal, K.Spacing.lg)

                    Chart {
                        ForEach(fatData) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("BF%", entry.bodyFat ?? 0)
                            )
                            .foregroundStyle(K.Colors.pr)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                            AxisValueLabel().foregroundStyle(K.Colors.secondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(K.Colors.surfaceBorder)
                            AxisValueLabel().foregroundStyle(K.Colors.secondary)
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal, K.Spacing.lg)
                }
                .padding(.top, K.Spacing.lg)
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
