import SwiftUI

struct LiveWorkoutBanner: View {
    var workoutService: WorkoutSessionService
    var healthKitService: HealthKitService
    var onEnd: (() -> Void)? = nil

    @State private var heartPulse = false
    @State private var breathe = false
    @State private var showEndConfirm = false

    private var isExternal: Bool {
        workoutService.sessionMode == .external
    }

    private var pulseDuration: Double {
        guard workoutService.heartRate > 0 else { return 1.0 }
        return 60.0 / workoutService.heartRate
    }

    var body: some View {
        HStack {
            // Heart rate
            statItem(
                icon: "heart.fill",
                value: workoutService.heartRate > 0 ? "\(Int(workoutService.heartRate))" : "--",
                label: "bpm",
                pulse: true,
                dimValue: workoutService.heartRate == 0
            )

            Spacer()

            // Calories
            statItem(
                icon: "flame.fill",
                value: "\(Int(workoutService.activeCalories))",
                label: "cal",
                pulse: false
            )

            Spacer()

            // Controls
            HStack(spacing: K.Spacing.sm) {
                if !isExternal {
                    Button {
                        if workoutService.isPaused {
                            workoutService.resumeSession()
                        } else {
                            workoutService.pauseSession()
                        }
                    } label: {
                        Image(systemName: workoutService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }

                Button {
                    showEndConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.md)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        K.Colors.liveGradientTop,
                        K.Colors.liveGradientBottom
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Breathing overlay
                Color.white
                    .opacity(breathe ? 0.10 : 0.0)
                    .animation(
                        .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                        value: breathe
                    )
            }
            .ignoresSafeArea(edges: .top)
        )
        .onAppear {
            heartPulse = true
            breathe = true
        }
        .confirmationDialog(
            isExternal ? "Stop Tracking?" : "End Workout Session?",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button(isExternal ? "Stop Tracking" : "End Session", role: .destructive) {
                workoutService.endSession()
                onEnd?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(isExternal
                 ? "This will stop observing your Apple Watch workout data."
                 : "This will stop tracking time and calories. Your completed sets will be kept.")
        }
    }

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(
        icon: String,
        value: String,
        label: String?,
        pulse: Bool,
        dimValue: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .scaleEffect(pulse && heartPulse ? 1.25 : 1.0)
                .animation(
                    pulse ? .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true) : .default,
                    value: heartPulse
                )

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(dimValue ? .white.opacity(0.4) : .white)
                .monospacedDigit()
                .contentTransition(.numericText())

            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
