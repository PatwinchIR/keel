import SwiftUI

struct LiveWorkoutBanner: View {
    var workoutService: WorkoutSessionService
    var onCancel: (() -> Void)? = nil

    @State private var heartPulse = false
    @State private var showCancelConfirm = false

    var body: some View {
        VStack(spacing: K.Spacing.xs) {
            HStack(spacing: K.Spacing.md) {
                // Live indicator + elapsed time
                HStack(spacing: K.Spacing.xs) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                    Text(workoutService.formattedElapsedTime)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .foregroundStyle(K.Colors.primary)
                }

                Spacer()

                // Heart rate
                if workoutService.heartRate > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .scaleEffect(heartPulse ? 1.2 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                value: heartPulse
                            )
                        Text("\(Int(workoutService.heartRate))")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(K.Colors.primary)
                    }
                    .onAppear { heartPulse = true }
                }

                // Calories
                if workoutService.activeCalories > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(Int(workoutService.activeCalories)) cal")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(K.Colors.primary)
                    }
                }

                // Pause / Resume
                Button {
                    if workoutService.isPaused {
                        workoutService.resumeSession()
                    } else {
                        workoutService.pauseSession()
                    }
                } label: {
                    Image(systemName: workoutService.isPaused ? "play.fill" : "pause.fill")
                        .font(.caption)
                        .foregroundStyle(K.Colors.primary)
                        .frame(width: 28, height: 28)
                        .background(K.Colors.surfaceLight)
                        .clipShape(Circle())
                }

                // Cancel / Stop
                Button {
                    showCancelConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(K.Colors.error)
                        .frame(width: 28, height: 28)
                        .background(K.Colors.error.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Text("Tracking workout for Apple Health")
                .font(.system(size: 10))
                .foregroundStyle(K.Colors.tertiary)
        }
        .padding(.horizontal, K.Spacing.lg)
        .padding(.vertical, K.Spacing.sm)
        .background(K.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
        .overlay(
            RoundedRectangle(cornerRadius: K.Radius.sharp)
                .stroke(K.Colors.accent.opacity(0.3), lineWidth: 0.5)
        )
        .confirmationDialog("End Workout Session?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("End Session", role: .destructive) {
                workoutService.endSession()
                onCancel?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will stop tracking time and calories. Your completed sets will be kept.")
        }
    }
}
