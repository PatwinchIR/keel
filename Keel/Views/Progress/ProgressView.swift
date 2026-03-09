import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneRepMax.date) private var allMaxes: [OneRepMax]
    @Query(sort: \BodyComposition.date) private var bodyComp: [BodyComposition]

    @State private var showCalculator = false
    @State private var showAddHistory = false
    @State private var historyExpanded = false
    @State private var selectedHistoryLift: CompoundLift = .squat
    @State private var displayUnit: WeightUnit = .lbs

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
    private func compactMaxCard(_ lift: CompoundLift) -> some View {
        let current = service.currentOneRepMax(for: lift)

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

    // MARK: - Collapsible History

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Button {
                withAnimation(K.Animation.fast) {
                    historyExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("HISTORY")
                        .sectionHeader()
                    Spacer()
                    Image(systemName: historyExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(K.Colors.tertiary)
                }
            }
            .padding(.horizontal, K.Spacing.lg)

            if historyExpanded {
                // Lift filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: K.Spacing.sm) {
                        ForEach(CompoundLift.allCases) { lift in
                            Button {
                                selectedHistoryLift = lift
                            } label: {
                                Text(lift.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(selectedHistoryLift == lift ? K.Colors.background : K.Colors.secondary)
                                    .padding(.horizontal, K.Spacing.md)
                                    .padding(.vertical, K.Spacing.xs)
                                    .background(selectedHistoryLift == lift ? lift.chartColor : K.Colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                            }
                        }
                    }
                    .padding(.horizontal, K.Spacing.lg)
                }

                let history = allMaxes
                    .filter { $0.lift == selectedHistoryLift }
                    .sorted { $0.date > $1.date }

                if history.isEmpty {
                    Text("No records yet")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.tertiary)
                        .padding(.horizontal, K.Spacing.lg)
                } else {
                    ForEach(history) { record in
                        historyRow(record)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func historyRow(_ record: OneRepMax) -> some View {
        let displayWeight = displayUnit == .kg
            ? record.weight / 2.205
            : record.weight
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: K.Spacing.xs) {
                    Text("\(Int(displayWeight))")
                        .font(.keelMono)
                        .foregroundStyle(K.Colors.primary)
                    Text(displayUnit.label)
                        .font(.caption2)
                        .foregroundStyle(K.Colors.secondary)
                }

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(K.Colors.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption)
                    .foregroundStyle(K.Colors.secondary)

                Text("Cycle \(record.cycleNumber)")
                    .font(.caption2)
                    .foregroundStyle(K.Colors.tertiary)
            }
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.sm)
    }
}
