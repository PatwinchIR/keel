import SwiftUI

struct RestTimerOverlay: View {
    let totalSeconds: Int
    @Binding var isPresented: Bool
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    @State private var isRunning = true

    init(totalSeconds: Int, isPresented: Binding<Bool>) {
        self.totalSeconds = totalSeconds
        self._isPresented = isPresented
        self._remainingSeconds = State(initialValue: totalSeconds)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    private var timeString: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: K.Spacing.xl) {
            Spacer()

            // Timer ring
            ZStack {
                Circle()
                    .stroke(K.Colors.surfaceBorder, lineWidth: 4)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(K.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(K.Animation.fast, value: progress)

                VStack(spacing: K.Spacing.xs) {
                    Text("REST")
                        .sectionHeader()

                    Text(timeString)
                        .font(.keelMonoLarge)
                        .foregroundStyle(K.Colors.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            // Controls
            HStack(spacing: K.Spacing.xxl) {
                // Add 30s
                Button {
                    remainingSeconds += 30
                } label: {
                    Text("+30s")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.secondary)
                        .padding(.horizontal, K.Spacing.lg)
                        .padding(.vertical, K.Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: K.Radius.sharp)
                                .stroke(K.Colors.surfaceBorder, lineWidth: 1)
                        )
                }

                // Play/Pause
                Button {
                    isRunning.toggle()
                    if isRunning {
                        startTimer()
                    } else {
                        timer?.invalidate()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(K.Colors.primary)
                        .frame(width: 56, height: 56)
                        .background(K.Colors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: K.Radius.sharp))
                }

                // Skip
                Button {
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(.keelCaption)
                        .foregroundStyle(K.Colors.secondary)
                        .padding(.horizontal, K.Spacing.lg)
                        .padding(.vertical, K.Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: K.Radius.sharp)
                                .stroke(K.Colors.surfaceBorder, lineWidth: 1)
                        )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial.opacity(0.97))
        .background(K.Colors.background.opacity(0.85))
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                withAnimation {
                    remainingSeconds -= 1
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }
    }

    private func dismiss() {
        timer?.invalidate()
        isPresented = false
    }
}
