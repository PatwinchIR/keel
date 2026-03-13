import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Program> { $0.isActive == true }) private var activePrograms: [Program]
    @State private var showNewCycleConfirm = false
    @State private var showResetConfirm = false
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(PlateSettings.self) private var plateSettings
    @Environment(RestDaySettings.self) private var restDaySettings
    @FocusState private var isInputFocused: Bool

    private var program: Program? { activePrograms.first }

    var body: some View {
        ZStack {
            K.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: K.Spacing.xl) {
                    // Program section
                    if let program {
                        programSection(program)
                    }

                    // Rest days section
                    restDaySection

                    // Plate calculator section
                    plateSection

                    // HealthKit section
                    healthKitSection

                    // About section
                    aboutSection

                    Spacer(minLength: 100)
                }
                .padding(K.Spacing.lg)
                .padding(.top, K.Spacing.lg)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isInputFocused = false }
                        .foregroundStyle(K.Colors.accent)
                }
            }
        }
    }

    @ViewBuilder
    private func programSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Text("PROGRAM")
                .sectionHeader()

            VStack(spacing: 1) {
                settingsRow(label: "Name", value: program.name)

                // Week picker
                HStack {
                    Text("Week")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)
                    Spacer()
                    Picker("Week", selection: Binding(
                        get: { program.currentWeek },
                        set: { newWeek in
                            ProgramService(modelContext: modelContext).setWeek(program, to: newWeek)
                        }
                    )) {
                        ForEach(1...program.totalWeeks, id: \.self) { week in
                            Text("Week \(week)").tag(week)
                        }
                    }
                    .tint(K.Colors.accent)
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.vertical, K.Spacing.sm)
                .background(K.Colors.surface)

                HStack {
                    Text("Cycle")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)
                    Spacer()
                    Picker("Cycle", selection: Binding(
                        get: { program.currentCycleNumber },
                        set: { newCycle in
                            program.currentCycleNumber = max(1, newCycle)
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(1...max(program.currentCycleNumber, 20), id: \.self) { cycle in
                            Text("Cycle \(cycle)").tag(cycle)
                        }
                    }
                    .tint(K.Colors.accent)
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.vertical, K.Spacing.sm)
                .background(K.Colors.surface)
                settingsRow(label: "Unit", value: program.unit.label)
                settingsRow(label: "Training Days", value: program.trainingDays.map(\.shortName).joined(separator: ", "))
            }

            // New cycle
            if program.currentWeek >= program.totalWeeks {
                Button {
                    showNewCycleConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Start New Cycle")
                    }
                    .font(.keelHeadline)
                    .foregroundStyle(K.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.lg)
                    .background(K.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }
            }

            // Deactivate
            Button {
                showResetConfirm = true
            } label: {
                Text("Deactivate Program")
                    .font(.keelCaption)
                    .foregroundStyle(K.Colors.error)
            }
            .padding(.top, K.Spacing.sm)
        }
        .alert("Start New Cycle?", isPresented: $showNewCycleConfirm) {
            Button("Start") {
                let service = ProgramService(modelContext: modelContext)
                let orms = service.currentOneRepMaxes()
                service.startNewCycle(program, newOneRepMaxes: orms)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all workouts and recalculate loads using your latest 1RMs. Cycle \(program.currentCycleNumber + 1) will begin.")
        }
        .alert("Deactivate Program?", isPresented: $showResetConfirm) {
            Button("Deactivate", role: .destructive) {
                program.isActive = false
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your workout data will be preserved but the program will no longer be active.")
        }
    }

    @ViewBuilder
    private var restDaySection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Text("REST DAYS")
                .sectionHeader()

            VStack(spacing: 1) {
                ForEach(TrainingDay.allCases, id: \.rawValue) { day in
                    HStack {
                        Text(day.fullName)
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { restDaySettings.isRestDay(day) },
                            set: { _ in restDaySettings.toggleRestDay(day) }
                        ))
                        .tint(K.Colors.accent)
                    }
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.vertical, K.Spacing.sm)
                    .background(K.Colors.surface)
                }
            }
        }
    }

    @ViewBuilder
    private var plateSection: some View {
        @Bindable var plateSettings = plateSettings
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Text("PLATE CALCULATOR")
                .sectionHeader()

            VStack(spacing: 1) {
                // Unit picker
                HStack {
                    Text("Unit")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)
                    Spacer()
                    Picker("", selection: $plateSettings.weightUnit) {
                        Text("LBS").tag(WeightUnit.lbs)
                        Text("KG").tag(WeightUnit.kg)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.vertical, K.Spacing.md)
                .background(K.Colors.surface)

                // Bar weight
                HStack {
                    Text("Bar Weight")
                        .font(.keelBody)
                        .foregroundStyle(K.Colors.secondary)
                    Spacer()
                    HStack(spacing: K.Spacing.xs) {
                        TextField(
                            plateSettings.weightUnit == .kg ? "20" : "45",
                            value: $plateSettings.barWeight,
                            format: .number
                        )
                            .font(.keelMono)
                            .foregroundStyle(K.Colors.primary)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .frame(width: 60)
                        Text(plateSettings.weightUnit.label)
                            .font(.keelCaption)
                            .foregroundStyle(K.Colors.secondary)
                    }
                }
                .padding(.horizontal, K.Spacing.lg)
                .padding(.vertical, K.Spacing.md)
                .background(K.Colors.surface)

                // Available plates
                ForEach(plateSettings.currentPlateOptions, id: \.self) { plate in
                    HStack {
                        Text("\(plate.plateSettingsLabel) \(plateSettings.weightUnit.label)")
                            .font(.keelBody)
                            .foregroundStyle(K.Colors.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { plateSettings.isPlateEnabled(plate) },
                            set: { _ in plateSettings.togglePlate(plate) }
                        ))
                        .tint(K.Colors.accent)
                    }
                    .padding(.horizontal, K.Spacing.lg)
                    .padding(.vertical, K.Spacing.sm)
                    .background(K.Colors.surface)
                }
            }
        }
    }

    @ViewBuilder
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Text("HEALTH")
                .sectionHeader()

            if healthKitService.isAuthorized {
                VStack(spacing: 1) {
                    settingsRow(label: "HealthKit", value: "Connected")
                    if let weight = healthKitService.latestBodyWeight {
                        settingsRow(label: "Body Weight", value: "\(Int(weight)) lbs")
                    }
                }
            } else {
                Button {
                    Task { await healthKitService.requestAuthorization() }
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Connect HealthKit")
                    }
                    .font(.keelBody)
                    .foregroundStyle(K.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, K.Spacing.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: K.Radius.sharp)
                            .stroke(K.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: K.Spacing.md) {
            Text("ABOUT")
                .sectionHeader()

            VStack(spacing: 1) {
                settingsRow(label: "App", value: "Keel")
                settingsRow(label: "Version", value: "1.0.0")
            }
        }
    }

    @ViewBuilder
    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.keelBody)
                .foregroundStyle(K.Colors.secondary)
            Spacer()
            Text(value)
                .font(.keelMono)
                .foregroundStyle(K.Colors.primary)
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.md)
        .background(K.Colors.surface)
    }
}

private extension Double {
    var plateSettingsLabel: String {
        if self == self.rounded() && self >= 1 {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }
}
